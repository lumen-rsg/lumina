# Jetson bring-up notes

These notes capture the reference system used to add NVIDIA Jetson support to
Lumina.  They are an engineering snapshot, not a replacement for NVIDIA's
version-matched Jetson Linux documentation.

Reference target:

```text
Board:       NVIDIA Jetson Orin Nano Developer Kit
Module:      P3767-0005
Carrier:     P3768-0000
Compatible:  nvidia,p3768-0000+p3767-0005
SoC:         nvidia,tegra234
Jetson Linux: R39.2.0
Kernel:      6.8.12-1021-tegra
Userspace:   Ubuntu 24.04 aarch64
```

Documents:

- [NVMe partition layout](partitions.md)
- [Kernel and boot findings](kernel.md)
- [NVIDIA driver and userspace findings](driver.md)
- [NVIDIA L4T README volume](L4T-README/README.md)

The observations were collected over SSH on 2026-07-30 before replacing the
stock root filesystem.
