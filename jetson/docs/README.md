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
- [NVIDIA ISO analysis and Lumina installer design](installer.md)
- [Kernel and boot findings](kernel.md)
- [NVIDIA driver and userspace findings](driver.md)
- [NVIDIA L4T README volume](L4T-README/README.md)

The observations were collected over SSH on 2026-07-30 before replacing the
stock root filesystem.

An updated reference capture on 2026-09-01 used Jetson Linux R39.2.1
(`39.2.1-20260806224157`) and the `p3767-0005-super` configuration. It retained
the `6.8.12-1021-tegra` ABI but replaced the kernel image, modules, firmware,
NVIDIA userspace, and L4TLauncher. The RPM sources now follow that coherent
R39.2.1 set; the original notes remain below as historical bring-up evidence.
