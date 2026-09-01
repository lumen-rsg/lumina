# Kernel and boot findings

## Kernel identity

The R39.2 reference system reported:

```text
Linux 6.8.12-1021-tegra
#1 SMP PREEMPT Mon Jun 1 13:25:46 PDT 2026
KERNEL_VARIANT: oot
```

The kernel payload was supplied by these NVIDIA Debian packages:

- `nvidia-l4t-kernel`
- `nvidia-l4t-kernel-dtbs`
- `nvidia-l4t-kernel-module-configs`
- `nvidia-l4t-kernel-nvgpu`
- `nvidia-l4t-kernel-openrm`
- `nvidia-l4t-kernel-oot-modules`
- `nvidia-l4t-display-kernel`

`nvidia-l4t-kernel-partitions` also existed on the stock system, but it manages
partition copies and firmware-update integration rather than files required in
the Lumina root filesystem.  The Lumina RPM does not flash those partitions.

## Files

The stock root filesystem contained:

```text
/boot/Image                         approximately 51 MiB
/boot/initrd                        approximately 11 MiB
/lib/modules/6.8.12-1021-tegra      approximately 141 MiB
```

NVIDIA split modules between `/lib/modules` and `/usr/lib/modules`.  Lumina's
source grabber normalizes the Debian `/lib` payload into `/usr/lib` for the
merged-usr Fedora filesystem while preserving file contents.

The resulting RPM installs:

```text
/boot/Image-6.8.12-1021-tegra
/usr/lib/modules/6.8.12-1021-tegra/
```

Its post-install script runs `depmod`, asks dracut to create
`/boot/initramfs-6.8.12-1021-tegra.img`, and invokes the Jetson boot setup tool
when available.

## Device trees

The running board identified itself as:

```text
nvidia,p3768-0000+p3767-0005
nvidia,p3767-0005
nvidia,tegra234
```

The matching rootfs DTBs included:

```text
tegra234-p3768-0000+p3767-0005.dtb
tegra234-p3768-0000+p3767-0005-nv.dtb
tegra234-p3768-0000+p3767-0005-nv-super.dtb
```

The generic R39.2 DTB package also contained other Orin and Thor board files.
They are retained so the RPM source stays aligned with NVIDIA's generic BSP,
although the initial supported Lumina target is P3768-0000 + P3767-0005.

The stock extlinux entry did not contain an explicit `FDT` line.  In that
configuration, NVIDIA firmware supplies the board-selected device tree.  The
Lumina boot configuration follows this behavior instead of hard-coding one
DTB.

## Active NVIDIA modules

Important loaded modules observed on the stock system included:

```text
nvidia
nvidia_modeset
nvidia_drm
nvgpu
nvmap
nvsciipc
tegra_dce
tegra_drm
nvhwpm
tegra_camera
tegra_capture_isp
tegra_camera_rtcpu
```

The display, CUDA, camera, and multimedia stacks depend on this exact kernel
ABI.  The proprietary and out-of-tree modules must therefore be shipped with
the matching `6.8.12-1021-tegra` kernel rather than attached to Fedora's
generic kernel.

## Boot configuration

The stock system used NVIDIA UEFI and `/boot/extlinux/extlinux.conf`.  Its
kernel command line included:

```text
root=PARTUUID=...
rw rootwait rootfstype=ext4
console=ttyTCU0,115200
firmware_class.path=/etc/firmware
efi=runtime
pci=pcie_bus_perf
nvme.use_threaded_interrupts=1
```

`lumina-jetson-boot-setup` preserves an existing configuration as
`extlinux.conf.pre-lumina`, detects the new root filesystem UUID, and writes an
entry for the versioned kernel and initramfs.  It does not update QSPI or raw
NVMe firmware partitions.

The QSPI/UEFI firmware and rootfs BSP should remain on the same L4T branch.
The current package set is specifically tied to R39.2.1. Although its ABI name
remains `6.8.12-1021-tegra`, the kernel image hash changed from
`d912f16edc206c79bff63af970784d19bfbe96d2b1e8232138b37c55501cdca8`
to `8e3738af56e08768157ef7fd225638d35a4f06e18201102338c6f537f866761e`.
The update changed 1,493 packaged kernel files and added three Tegra264 DTBs,
so the common ABI string must not be used to infer binary compatibility.
