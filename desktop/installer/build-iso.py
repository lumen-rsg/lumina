#!/usr/bin/env python3
"""Compose a verified Lumina UEFI network or offline installer."""
import argparse
import hashlib
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET


def run(*args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def render_kickstart(arch, graphics='mesa', installer_graphics='standard', installer_network='auto', offline=False):
    if graphics == 'nvidia-open' and arch != 'x86_64':
        raise ValueError('The NVIDIA desktop profile is x86_64 only')
    template = Path(__file__).with_name('lumina-desktop.ks.in').read_text()
    efi = 'grub2-efi-aa64\nshim-aa64' if arch == 'aarch64' else 'grub2-efi-x64\nshim-x64'
    result = template.replace('@ARCH@', arch).replace('@EFI_PACKAGES@', efi)
    if offline:
        result = '\n'.join(line for line in result.splitlines()
                           if not line.startswith(('url ', 'repo ', 'network ')) and line != '@core') + '\n'
        result = result.replace('graphical\n', 'graphical\ncdrom\n')
    if graphics == 'nvidia-open':
        result = result.replace('lumina-desktop\n', 'lumina-desktop\nkernel-devel-matched\nkernel-headers\nselinux-policy-targeted\nnvidia-driver\nnvidia-driver-selinux\nkmod-nvidia-open-dkms\n')
        result += '\n' + Path(__file__).with_name('nvidia').joinpath('post.ks').read_text()
    if installer_graphics == 'basic':
        result += '\n' + Path(__file__).with_name('basic-graphics-post.ks').read_text()
    if installer_network == 'ipv4-dns':
        result += '\n' + Path(__file__).with_name('ipv4-dns.ks').read_text()
    return result


def render_comps(arch, graphics='mesa', package_names=None):
    """Keep the desktop intact when Anaconda regenerates software selection.

    Offline media freezes the complete resolved package closure as one mandatory
    group; no remote comps groups or repositories are needed to install it.
    """
    offline = package_names is not None
    if package_names is None:
        block = render_kickstart(arch, graphics).split('%packages', 1)[1].split('%end', 1)[0]
        package_names = [s.strip() for s in block.splitlines()[1:]
                         if s.strip() and not s.startswith(('@', '-', '#'))]
    root = ET.Element('comps')
    group = ET.SubElement(root, 'group')
    for tag, text in [('id', 'lumina-desktop'), ('name', 'Lumina Desktop'),
                      ('description', 'Lumina 26.9 Cassiopeia with Chroma, Lumina Shell and Ly.'),
                      ('default', 'true'), ('uservisible', 'false')]:
        ET.SubElement(group, tag).text = text
    packages = ET.SubElement(group, 'packagelist')
    for name in sorted(set(package_names)):
        ET.SubElement(packages, 'packagereq', type='mandatory').text = name
    if offline:
        # Anaconda requests @core independently of the selected environment.
        # Define it locally too; these packages are already in the frozen set.
        core = ET.SubElement(root, 'group')
        for tag, text in [('id', 'core'), ('name', 'Lumina Base'),
                          ('description', 'Essential Lumina system packages.'),
                          ('default', 'true'), ('uservisible', 'false')]:
            ET.SubElement(core, tag).text = text
        core_packages = ET.SubElement(core, 'packagelist')
        for name in sorted(set(package_names) & {'bash', 'filesystem', 'glibc', 'setup', 'systemd'}):
            ET.SubElement(core_packages, 'packagereq', type='mandatory').text = name
    env = ET.SubElement(root, 'environment')
    for tag, text in [('id', 'lumina-desktop-environment'), ('name', 'Lumina Desktop'),
                      ('description', 'The complete Cassiopeia desktop, including Wi-Fi and hardware firmware.'),
                      ('display_order', '1')]:
        ET.SubElement(env, tag).text = text
    groups = ET.SubElement(env, 'grouplist')
    ET.SubElement(groups, 'groupid').text = 'core'
    ET.SubElement(groups, 'groupid').text = 'lumina-desktop'
    ET.indent(root)
    return '<?xml version="1.0" encoding="UTF-8"?>\n' + ET.tostring(root, encoding='unicode') + '\n'


def render_treeinfo(arch):
    return f'''[general]
arch = {arch}
family = Lumina
name = Lumina 26.9 Cassiopeia
version = 26.9
timestamp = 1789776000
packagedir = Packages
repository = .
variant = Desktop

[tree]
arch = {arch}
build_timestamp = 1789776000
platforms = {arch}
variants = Desktop

[release]
name = Lumina
short = Lumina
version = 26.9
is_layered = false

[variant-Desktop]
id = Desktop
name = Lumina Desktop
type = variant
uid = Desktop
packages = Packages
repository = .

[stage2]
mainimage = images/install.img

[images-{arch}]
kernel = images/pxeboot/vmlinuz
initrd = images/pxeboot/initrd.img
'''


def installer_kernel_args(graphics='standard', network='auto'):
    args = []
    if graphics == 'basic':
        args.append('nomodeset')
    if network == 'ipv4-dns':
        args.append('ipv6.disable=1')
    return args


def is_vendor_nvidia_package(name):
    # Fedora's firmware is needed by Nouveau; it is not a vendor driver.
    return name != 'nvidia-gpu-firmware' and (
        name.startswith(('nvidia-', 'libnvidia-', 'cuda-', 'kmod-nvidia',
                         'akmod-nvidia', 'xorg-x11-drv-nvidia')))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--arch', choices=['aarch64', 'x86_64'], required=True)
    parser.add_argument('--base-iso', type=Path, required=True)
    parser.add_argument('--checksum', type=Path, required=True,
                        help='Fedora signed CHECKSUM for the base ISO')
    parser.add_argument('--fedora-key', type=Path, required=True,
                        help='Trusted Fedora 44 release signing public key')
    parser.add_argument('--rpms', type=Path, required=True)
    parser.add_argument('--offline-rpms', type=Path,
                        help='Complete signed RPM closure from prepare-offline.py; install without a network')
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--allow-unsigned-development-rpms', action='store_true')
    parser.add_argument('--graphics', choices=['mesa', 'nvidia-open'], default='mesa')
    parser.add_argument('--installer-graphics', choices=['standard', 'basic'], default='standard',
                        help='Basic uses nomodeset only during installation; target KMS is restored')
    parser.add_argument('--installer-network', choices=['auto', 'ipv4-dns'], default='auto',
                        help='ipv4-dns uses IPv4 and public DNS during installation')
    parser.add_argument('--driver-rpms', type=Path,
                        help='Verified NVIDIA repository RPM closure to bundle for nvidia-open')
    args = parser.parse_args()
    if args.graphics == 'nvidia-open' and (args.arch != 'x86_64' or not args.driver_rpms):
        parser.error('nvidia-open requires x86_64 and --driver-rpms')
    if args.driver_rpms and args.graphics != 'nvidia-open':
        parser.error('--driver-rpms requires --graphics nvidia-open')
    if args.offline_rpms and args.graphics != 'mesa':
        parser.error('the offline profile currently supports Mesa/Nouveau only')
    for name in ['gpg', 'rpm', 'rpmkeys', 'createrepo_c', 'ksvalidator', 'mkksiso', 'mkfs.fat', 'mmd', 'mcopy', 'mksquashfs']:
        if not shutil.which(name):
            parser.error(f'missing tool: {name}')
    if args.output.exists():
        parser.error('output already exists; choose a new path')
    args.output = args.output.resolve()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='lumina-compose-', dir=args.output.parent) as temporary:
        work = Path(temporary)
        keyhome = work/'gnupg'
        keyhome.mkdir(mode=0o700)
        run('gpg', '--homedir', str(keyhome), '--batch', '--import', str(args.fedora_key))
        verified = run('gpg', '--homedir', str(keyhome), '--batch', '--decrypt', str(args.checksum),
                       capture_output=True, text=True)
        expected = re.search(r'^SHA256 \(' + re.escape(args.base_iso.name) + r'\) = ([0-9a-f]{64})$',
                             verified.stdout, re.M)
        if not expected or expected[1] != digest(args.base_iso):
            parser.error('base ISO checksum does not match its signed Fedora manifest')
        packages = work/('Packages' if args.offline_rpms else 'LuminaPackages')
        packages.mkdir()
        records = []
        names = set()
        inputs = list(args.rpms.glob('*.rpm'))
        if args.offline_rpms:
            # The offline directory includes these same Lumina RPMs. Require
            # identical copies rather than allowing stale or substituted inputs.
            for rpm in inputs:
                bundled = args.offline_rpms/rpm.name
                if not bundled.is_file() or digest(bundled) != digest(rpm):
                    parser.error(f'offline closure does not contain the supplied {rpm.name}')
            inputs = list(args.offline_rpms.glob('*.rpm'))
        if args.driver_rpms:
            inputs += list(args.driver_rpms.glob('*.rpm'))
        for rpm in sorted(inputs):
            name, arch = subprocess.check_output(['rpm', '-qp', '--qf', '%{NAME} %{ARCH}', str(rpm)], text=True).split()
            if name.endswith(('-debuginfo', '-debugsource')):
                continue
            if arch not in [args.arch, 'noarch']:
                parser.error(f'wrong architecture in {rpm.name}: {arch}')
            if name in names:
                parser.error(f'duplicate package name in installer inputs: {name}')
            if args.graphics == 'mesa' and is_vendor_nvidia_package(name):
                parser.error(f'vendor NVIDIA package is not allowed in the Mesa profile: {name}')
            if not args.allow_unsigned_development_rpms:
                checked = subprocess.run(['rpmkeys', '--checksig', str(rpm)], text=True, capture_output=True)
                if checked.returncode or 'signatures OK' not in checked.stdout:
                    parser.error(f'{rpm.name} is not signed by an imported trusted key')
            shutil.copyfile(rpm, packages/rpm.name)
            records.append(f'{digest(rpm)}  {rpm.name}')
            names.add(name)
        required = {'lumina-release', 'lumina-artwork', 'lumina-desktop', 'lumina-shell',
                    'chroma-compositor', 'quickshell', 'wl-clip-persist', 'bibata-cursor-theme',
                    'google-sans-flex-vf-fonts', 'google-material-symbols-vf-rounded-fonts',
                    'rpmfusion-free-release', 'rpmfusion-nonfree-release'}
        if args.offline_rpms:
            # Require every explicit target package, including split firmware.
            # A satisfiable RPM closure alone cannot detect missing weak deps.
            block = render_kickstart(args.arch, args.graphics).split('%packages', 1)[1].split('%end', 1)[0]
            required |= {line.strip() for line in block.splitlines()[1:]
                         if line.strip() and not line.startswith(('#', '@', '-'))}
            required |= {'ly', 'kernel-core', 'NetworkManager', 'NetworkManager-wifi', 'linux-firmware',
                         'nvidia-gpu-firmware', 'mesa-dri-drivers', 'mesa-vulkan-drivers',
                         'nvme-cli', 'btrfs-progs', 'dosfstools', 'e2fsprogs', 'xfsprogs',
                         'cryptsetup', 'lvm2', 'mdadm', 'grub2-tools-extra',
                         'langpacks-en', 'glibc-all-langpacks'}
        if args.graphics == 'nvidia-open':
            required |= {'nvidia-driver', 'nvidia-driver-selinux', 'kmod-nvidia-open-dkms'}
        if missing := required - names:
            parser.error('missing Lumina packages: ' + ', '.join(sorted(missing)))
        (packages/'SHA256SUMS').write_text('\n'.join(records)+'\n')
        comps = work/'comps.xml'
        comps.write_text(render_comps(args.arch, args.graphics, names if args.offline_rpms else None))
        repository = work if args.offline_rpms else packages
        run('createrepo_c', '-g', str(comps), str(repository))
        kickstart = work/'lumina-desktop.ks'
        kickstart.write_text(render_kickstart(args.arch, args.graphics, args.installer_graphics,
                                            args.installer_network, offline=bool(args.offline_rpms)))
        run('ksvalidator', '-v', 'F44', str(kickstart))
        suffix = '-dev' if args.allow_unsigned_development_rpms else ''
        additions = []
        if args.offline_rpms:
            treeinfo = work/'.treeinfo'
            treeinfo.write_text(render_treeinfo(args.arch))
            discinfo = work/'.discinfo'
            discinfo.write_text(f'1789776000\nLumina 26.9 Cassiopeia\n{args.arch}\nALL\n')
            for path in [work/'repodata', treeinfo, discinfo]:
                additions += ['--add', str(path)]
        if kernel_args := installer_kernel_args(args.installer_graphics, args.installer_network):
            additions += ['--cmdline', ' '.join(kernel_args)]
        if args.graphics == 'nvidia-open':
            support = work/'NvidiaSupport'
            shutil.copytree(Path(__file__).with_name('nvidia'), support)
            additions += ['--add', str(support)]
            suffix = '-nvidia' + suffix
        product = work/'product'
        shutil.copytree(Path(__file__).with_name('branding'), product)
        # Brand both os-release locations: applications vary in which they read.
        (product/'usr/lib').mkdir(parents=True, exist_ok=True)
        shutil.copyfile(product/'etc/os-release', product/'usr/lib/os-release')
        if args.offline_rpms:
            (product/'etc/anaconda/conf.d/91-lumina-offline.conf').write_text(
                '[Payload]\nenable_closest_mirror = False\n'
                'disabled_repositories =\n    fedora*\n    updates*\n'
                '    rpmfusion*\n    *source*\n    *debuginfo*\n')
        (product/'.buildstamp').write_text(
            '[Main]\nProduct=Lumina\nVersion=26.9 Cassiopeia\n'
            'BugURL=https://github.com/lumen-rsg/lumina/issues\n'
            f'IsFinal={not args.allow_unsigned_development_rpms}\nVariant=Desktop\n')
        images = work/'images'
        images.mkdir()
        run('mksquashfs', str(product), str(images/'product.img'), '-noappend', '-all-root', '-quiet')
        # Lorax normally mounts a loop device to construct its FAT image.
        # Build the same EFI/BOOT tree using mtools in an isolated helper PATH.
        helpers = work/'helpers'
        helpers.mkdir()
        helper = helpers/'mkefiboot'
        shutil.copyfile(Path(__file__).with_name('mkefiboot-mtools.py'), helper)
        helper.chmod(0o755)
        run('mkksiso', '--ks', str(kickstart), '--add', str(packages), '--add', str(images), *additions,
            '--volid', f'Lumina-26.9-{args.arch}{suffix}',
            '--replace', 'Fedora 44', 'Lumina 26.9 Cassiopeia',
            str(args.base_iso.resolve()), str(args.output),
            env=os.environ | {'PATH': str(helpers) + os.pathsep + os.environ['PATH']})
        args.output.with_suffix('.iso.sha256').write_text(f'{digest(args.output)}  {args.output.name}\n')
        args.output.with_suffix('.packages.sha256').write_text('\n'.join(records)+'\n')


if __name__ == '__main__':
    main()
