#!/usr/bin/env python3
"""Compose a UEFI network installer from verified Fedora media and Lumina RPMs."""
import argparse
import hashlib
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


def run(*args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--arch', choices=['aarch64', 'x86_64'], required=True)
    parser.add_argument('--base-iso', type=Path, required=True)
    parser.add_argument('--checksum', type=Path, required=True,
                        help='Fedora signed CHECKSUM for the base ISO')
    parser.add_argument('--fedora-key', type=Path, required=True,
                        help='Trusted Fedora 44 release signing public key')
    parser.add_argument('--rpms', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--allow-unsigned-development-rpms', action='store_true')
    args = parser.parse_args()
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
        packages = work/'LuminaPackages'
        packages.mkdir()
        records = []
        names = set()
        for rpm in sorted(args.rpms.glob('*.rpm')):
            name, arch = subprocess.check_output(['rpm', '-qp', '--qf', '%{NAME} %{ARCH}', str(rpm)], text=True).split()
            if name.endswith(('-debuginfo', '-debugsource')):
                continue
            if arch not in [args.arch, 'noarch']:
                parser.error(f'wrong architecture in {rpm.name}: {arch}')
            if not args.allow_unsigned_development_rpms:
                checked = subprocess.run(['rpmkeys', '--checksig', str(rpm)], text=True, capture_output=True)
                if checked.returncode or 'signatures OK' not in checked.stdout:
                    parser.error(f'{rpm.name} is not signed by an imported trusted key')
            shutil.copyfile(rpm, packages/rpm.name)
            records.append(f'{digest(rpm)}  {rpm.name}')
            names.add(name)
        required = {'lumina-release', 'lumina-artwork', 'lumina-desktop', 'lumina-shell',
                    'chroma', 'quickshell', 'wl-clip-persist', 'bibata-cursor-theme',
                    'google-sans-flex-vf-fonts', 'google-material-symbols-vf-rounded-fonts'}
        if missing := required - names:
            parser.error('missing Lumina packages: ' + ', '.join(sorted(missing)))
        (packages/'SHA256SUMS').write_text('\n'.join(records)+'\n')
        run('createrepo_c', str(packages))
        template = Path(__file__).with_name('lumina-desktop.ks.in').read_text()
        efi = 'grub2-efi-aa64\nshim-aa64' if args.arch == 'aarch64' else 'grub2-efi-x64\nshim-x64'
        kickstart = work/'lumina-desktop.ks'
        kickstart.write_text(template.replace('@ARCH@', args.arch).replace('@EFI_PACKAGES@', efi))
        run('ksvalidator', '-v', 'F44', str(kickstart))
        suffix = '-dev' if args.allow_unsigned_development_rpms else ''
        product = work/'product'
        shutil.copytree(Path(__file__).with_name('branding'), product)
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
        run('mkksiso', '--ks', str(kickstart), '--add', str(packages), '--add', str(images),
            '--volid', f'Lumina-26.9-{args.arch}{suffix}',
            '--replace', 'Fedora 44', 'Lumina 26.9 Cassiopeia',
            str(args.base_iso.resolve()), str(args.output),
            env=os.environ | {'PATH': str(helpers) + os.pathsep + os.environ['PATH']})
        args.output.with_suffix('.iso.sha256').write_text(f'{digest(args.output)}  {args.output.name}\n')
        args.output.with_suffix('.packages.sha256').write_text('\n'.join(records)+'\n')


if __name__ == '__main__':
    main()
