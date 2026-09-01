# Jetson Orin Nano NVMe partition layout

## Summary

The reference system booted from `/dev/nvme0n1`, a 238.5 GiB NVMe drive with
15 GPT partitions.  Only partition 1 is the ordinary Linux root filesystem.
The other partitions are boot-chain, redundancy, recovery, update, and
firmware-support payloads.

For an in-place Lumina or Fedora-derived installation:

1. Preserve the GPT.
2. Reformat partition 1 in place as ext4 and mount it at `/`.
3. Do not delete and recreate partition 1; preserving its GPT identity makes
   recovery and firmware assumptions less surprising.
4. Preserve partitions 2 through 15.
5. Do not let a generic installer format the existing EFI System Partition or
   replace `EFI/BOOT/BOOTAA64.efi`.
6. Do not install GRUB.  NVIDIA UEFI loads the L4T extlinux configuration from
   `/boot/extlinux/extlinux.conf` in the root filesystem.
7. Install the Tegra kernel RPMs and run `lumina-jetson-boot-setup` before the
   first reboot.

The boot filesystem must be readable by NVIDIA UEFI.  The initial port
therefore uses ext4 for the root filesystem and keeps `/boot` inside it rather
than using Fedora's default Btrfs layout.

The firmware must report chain A as `Normal`. The R39.2.1 reference board
successfully selected the rootfs-side extlinux entry with `L4T Boot Mode` set
to `Automatic` (`L4TDefaultBootMode=0xffffffff`). Explicit `ExtLinux` remains
the documented recovery setting for filesystem boot. Because a fresh GPT gives
the ESP a new partition identity, the installer also registers a new
`L4TLauncher` UEFI boot entry for that ESP while retaining the standard
`EFI/BOOT/BOOTAA64.efi` fallback path used by automatic device boot.

## Observed partitions

| Number | Size | Label | Observed role | Installation action |
|---:|---:|---|---|---|
| 1 | 237 GiB | `APP` | Root filesystem and `/boot` | Reformat ext4 and mount at `/` |
| 2 | 128 MiB | `A_kernel` | Boot-chain A fallback kernel image | Preserve |
| 3 | 768 KiB | `A_kernel-dtb` | Boot-chain A fallback device tree | Preserve |
| 4 | 31.6 MiB | `reserved_for_chain_A_user` | Space reserved for chain A updates | Preserve |
| 5 | 128 MiB | `B_kernel` | Boot-chain B fallback kernel image | Preserve |
| 6 | 768 KiB | `B_kernel-dtb` | Boot-chain B fallback device tree | Preserve |
| 7 | 31.6 MiB | `reserved_for_chain_B_user` | Space reserved for chain B updates | Preserve |
| 8 | 100 MiB | `recovery` | Primary recovery image | Preserve |
| 9 | 512 KiB | `recovery-dtb` | Primary recovery device tree | Preserve |
| 10 | 64 MiB | `esp` | FAT32 EFI System Partition | Preserve; never format |
| 11 | 100 MiB | `recovery_alt` | Alternate recovery image | Preserve |
| 12 | 512 KiB | `recovery-dtb_alt` | Alternate recovery device tree | Preserve |
| 13 | 64 MiB | `esp_alt` | Redundant EFI payload | Preserve |
| 14 | 400 MiB | `UDA` | NVIDIA user-data/update area | Preserve |
| 15 | 479.5 MiB | `reserved` | Reserved firmware/update space | Preserve |

At capture time, partition 10 was mounted at `/boot/efi` and contained one
110,592-byte file:

```text
/boot/efi/EFI/BOOT/BOOTAA64.efi
```

After the R39.2.1 firmware update, the same path contained the matching
114,688-byte L4TLauncher with SHA-256
`a848c03d3990b9d79c17e0d125e2f5eb149e85c1045388b37161baf05a603c7e`.
UEFI booted it through the auto-created NVMe device entry rather than a named
L4TLauncher entry.

## Why NVIDIA uses this layout

Jetson is an embedded platform rather than a conventional UEFI PC.  Its boot
flow spans BootROM and firmware in the module's QSPI flash, payloads on the
NVMe drive, and the root filesystem.  NVIDIA keeps A/B kernel and DTB copies,
two recovery paths, redundant EFI payloads, and reserved update space so that
an interrupted update has a recoverable boot chain.

The rootfs RPMs intentionally do not flash QSPI, the A/B partitions, recovery,
or either ESP.  They install a versioned kernel and initramfs under `/boot` and
write only the rootfs-side extlinux configuration.

## Backup

Before reformatting `APP`, raw images of partitions 2 through 15 were copied to
the development computer together with:

- a binary GPT backup;
- `sfdisk`, `sgdisk`, and `lsblk` partition reports;
- `BOOTAA64.efi`;
- `nv_tegra_release`, `nv_boot_control.conf`, and `extlinux.conf`;
- SHA-256 hashes of both the raw source partitions and local decompressed
  images.

Every decompressed local image matched the corresponding raw partition.  The
backup is deliberately outside this Git repository because it contains
device-specific firmware data.
