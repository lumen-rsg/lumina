# 1T Lumina

RPM sources for 1T Lumina, a Fedora-derived Linux distribution for
single-board computers.

- Website: https://linux.1t.ru/
- Source: https://github.com/lumen-rsg/lumina
- Packages: https://packages.lumina.1t.ru/

## Common packages

- `lumina-release` supplies the distribution identity, Fedora-compatible
  release capabilities and presets, RPM macros, GRUB/BLS branding, and the
  system fastfetch artwork.
- `neofetch` adds automatic 1T Lumina detection and the distribution artwork
  to the archived neofetch utility.
- `aurora` is Lumina's package manager.

Board-specific packages live under `orangepi/` and `jetson/`.

## Supported devices

- NVIDIA Jetson Orin family
- Orange Pi 5 Ultra (mainline image candidate; hardware acceptance pending)
- Orange Pi Zero 3 (Allwinner H618; directly bootable SD-card image)
