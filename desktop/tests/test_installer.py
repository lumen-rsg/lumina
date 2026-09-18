"""Validate architecture and target-safety boundaries of installer profiles."""
import importlib.util
from pathlib import Path
import unittest

path = Path(__file__).resolve().parents[1] / 'installer' / 'build-iso.py'
spec = importlib.util.spec_from_file_location('build_iso', path)
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class InstallerProfiles(unittest.TestCase):
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
        for package in ['kernel-devel-matched', 'kernel-headers', 'nvidia-driver', 'kmod-nvidia-open-dkms']:
            self.assertIn('\n' + package + '\n', packages)
        self.assertIn('%post --nochroot --erroronfail', text)
        self.assertIn('chroot /mnt/sysroot /bin/bash', text)

    def test_nvidia_rejects_arm(self):
        with self.assertRaises(ValueError):
            builder.render_kickstart('aarch64', 'nvidia-open')


if __name__ == '__main__':
    unittest.main()
