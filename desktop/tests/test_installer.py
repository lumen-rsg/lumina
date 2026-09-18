"""Validate architecture and target-safety boundaries of installer profiles."""
import importlib.util
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

path = Path(__file__).resolve().parents[1] / 'installer' / 'build-iso.py'
spec = importlib.util.spec_from_file_location('build_iso', path)
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class InstallerProfiles(unittest.TestCase):
    def test_desktop_survives_environment_reselection(self):
        for arch in ['x86_64', 'aarch64']:
            comps = ET.fromstring(builder.render_comps(arch))
            groups = {g.findtext('id'): g for g in comps.findall('group')}
            environment = comps.find('environment')
            self.assertEqual(environment.findtext('id'), 'lumina-desktop-environment')
            self.assertIn('lumina-desktop', [g.text for g in environment.findall('grouplist/groupid')])
            mandatory = {p.text for p in groups['lumina-desktop'].findall('packagelist/packagereq')
                         if p.get('type') == 'mandatory'}
            self.assertTrue({'lumina-desktop', 'kernel', 'linux-firmware', 'grubby',
                             'nvme-cli', 'btrfs-progs', 'dosfstools', 'grub2-tools-extra',
                             'cryptsetup', 'lvm2', 'mdadm', 'xfsprogs',
                             'NetworkManager', 'NetworkManager-wifi'} <= mandatory)
            self.assertNotIn('gdm', mandatory)

    def test_offline_has_only_media_source_and_self_contained_environment(self):
        packages = {'lumina-desktop', 'ly', 'kernel', 'bash', 'NetworkManager-wifi'}
        for arch in ['x86_64', 'aarch64']:
            text = builder.render_kickstart(arch, offline=True)
            self.assertIn('\ncdrom\n', text)
            self.assertIn('@^lumina-desktop-environment', text)
            self.assertNotIn('\n@core\n', text)
            self.assertFalse(any(line.startswith(('url ', 'repo ', 'network ')) for line in text.splitlines()))
            comps = ET.fromstring(builder.render_comps(arch, package_names=packages))
            self.assertEqual(packages, {p.text for p in comps.findall('group/packagelist/packagereq')})
            defined = {g.findtext('id') for g in comps.findall('group')}
            self.assertIn('core', defined)  # Anaconda also requests this implicitly.
            self.assertTrue({g.text for g in comps.findall('environment/grouplist/groupid')} <= defined)

    def test_generic_architectures_and_interactive_storage(self):
        for arch, efi in [('x86_64', 'grub2-efi-x64'), ('aarch64', 'grub2-efi-aa64')]:
            with self.subTest(arch=arch):
                text = builder.render_kickstart(arch)
                self.assertIn(efi, text)
                self.assertNotIn('@ARCH@', text)
                self.assertNotIn('nvidia-driver', text)
                commands = [line.split()[0] for line in text.splitlines()
                            if line.strip() and not line.startswith('#')]
                for unsafe in ['clearpart', 'autopart', 'zerombr', 'rootpw', 'user']:
                    self.assertNotIn(unsafe, commands)

    def test_nvidia_target_has_matching_headers_and_fatal_post(self):
        text = builder.render_kickstart('x86_64', 'nvidia-open')
        packages = text.split('%packages', 1)[1].split('%end', 1)[0]
        for package in ['kernel-devel-matched', 'kernel-headers', 'selinux-policy-targeted',
                        'nvidia-driver', 'nvidia-driver-selinux', 'kmod-nvidia-open-dkms']:
            self.assertIn('\n' + package + '\n', packages)
        self.assertIn('%post --nochroot --erroronfail', text)
        self.assertIn('chroot /mnt/sysroot /bin/bash', text)

    def test_nvidia_rejects_arm(self):
        with self.assertRaises(ValueError):
            builder.render_kickstart('aarch64', 'nvidia-open')

    def test_basic_installer_restores_target_modesetting(self):
        text = builder.render_kickstart('x86_64', installer_graphics='basic')
        self.assertIn('grubby --update-kernel=ALL --remove-args="nomodeset"', text)
        self.assertIn('%post --erroronfail --log=/var/log/lumina-basic-graphics-install.log', text)
        self.assertNotIn('NvidiaSupport', text)
        self.assertNotIn('blacklist nouveau', text)

    def test_mesa_rejects_vendor_driver_but_keeps_firmware(self):
        for package in ['nvidia-driver', 'kmod-nvidia-open-dkms', 'akmod-nvidia',
                        'xorg-x11-drv-nvidia', 'libnvidia-ml', 'cuda-driver-devel-13-4']:
            self.assertTrue(builder.is_vendor_nvidia_package(package), package)
        self.assertFalse(builder.is_vendor_nvidia_package('nvidia-gpu-firmware'))
        text = builder.render_kickstart('x86_64')
        for package in ['nvidia-gpu-firmware', 'mesa-dri-drivers', 'mesa-vulkan-drivers']:
            self.assertIn('\n' + package + '\n', text)

    def test_installer_network_override_is_explicit_and_runtime_only(self):
        self.assertNotIn('global-dns-domain', builder.render_kickstart('x86_64'))
        self.assertEqual(builder.installer_kernel_args(), [])
        self.assertEqual(builder.installer_kernel_args('basic', 'ipv4-dns'),
                         ['nomodeset', 'ipv6.disable=1'])
        text = builder.render_kickstart('x86_64', installer_network='ipv4-dns')
        self.assertIn('%pre --erroronfail', text)
        self.assertIn('/run/NetworkManager/conf.d/99-lumina-installer-dns.conf', text)
        self.assertIn('servers=1.1.1.1,8.8.8.8', text)
        self.assertIn('dns=default\nrc-manager=symlink\nsystemd-resolved=false', text)
        self.assertIn('ln -sfn /run/NetworkManager/resolv.conf /etc/resolv.conf', text)
        self.assertNotIn('--noipv6', text)
        self.assertIn('grubby --update-kernel=ALL --remove-args="ipv6.disable"', text)


if __name__ == '__main__':
    unittest.main()
