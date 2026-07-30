# NVIDIA ISO analysis and Lumina installer design

## Reference image

The inspected image is:

```text
jetsoninstaller-r39.2.0-2026-06-01-23-53-13-arm64.iso
SHA-256 6b51d397543c45a9aa46e7a1bebe06f5513f5e0c969c2bf71da2361b60eb593f
```

It is an ARM64 Ubuntu 24.04/Subiquity hybrid ISO. Its outer GPT contains the
ISO payload, a 512 MiB EFI System Partition, and a small trailing partition.
That outer layout is only for booting the installer and is not the layout
written to Jetson storage.

The Jetson must first be flashed with the matching NVIDIA release. Flashing
provisions the module's QSPI firmware and UEFI. It does not provision an empty
NVMe drive. The on-device installer creates the NVMe/eMMC/SD/USB GPT.

## How NVIDIA selects an installation target

The GRUB menu boots one kernel and initrd for every installation mode:

| Menu choice | Kernel argument |
|---|---|
| NVMe | `force-bootdisk=nvme0n1` |
| USB | no forced disk; the early script finds the USB target |
| AGX Orin eMMC | `force-bootdisk=mmcblk0` |
| microSD | `force-bootdisk=mmcblkn` |

`mmcblkn` is resolved at runtime because `mmcblk0` is the AGX Orin eMMC but
the microSD device on Orin Nano/NX. For AGX Orin, microSD becomes `mmcblk1`;
otherwise it becomes `mmcblk0`.

The live root contains `/autoinstall.yaml`, which invokes
`/ai/preseed.sh jetsoniso` as a Subiquity early command. That script validates
the target, detects the board, chooses the Orin or Thor profile, and invokes
the platform setup script. The default is destructive; `preserve-part` is an
optional kernel argument rather than the normal install path.

## Target GPT created for Orin

NVIDIA runs `sgdisk -Z`, then feeds a device-specific template to `sfdisk`.
NVMe, eMMC, and SD/USB use the same starts and sizes; only Linux device naming
and a few reserved labels differ.

Partition 1 is numbered first but is physically last. It begins at sector
3,131,968 (about 1.49 GiB) and consumes the rest of the disk. Partitions 2
through 15 occupy the space before it.

| No. | Start | Sectors | Size | Label |
|---:|---:|---:|---:|---|
| 1 | 3,131,968 | remainder | disk remainder | `APP` |
| 2 | 40 | 262,144 | 128 MiB | `A_kernel` |
| 3 | 262,184 | 1,536 | 768 KiB | `A_kernel-dtb` |
| 4 | 263,720 | 64,768 | 31.625 MiB | chain A reserved |
| 5 | 328,488 | 262,144 | 128 MiB | `B_kernel` |
| 6 | 590,632 | 1,536 | 768 KiB | `B_kernel-dtb` |
| 7 | 592,168 | 64,768 | 31.625 MiB | chain B reserved |
| 8 | 656,936 | 204,800 | 100 MiB | `recovery` |
| 9 | 861,736 | 1,024 | 512 KiB | `recovery-dtb` |
| 10 | 862,760 | 131,072 | 64 MiB | `esp` |
| 11 | 993,832 | 204,800 | 100 MiB | `recovery_alt` |
| 12 | 1,198,632 | 1,024 | 512 KiB | `recovery-dtb_alt` |
| 13 | 1,199,656 | 131,072 | 64 MiB | `esp_alt` |
| 14 | 1,330,752 | 819,200 | 400 MiB | `UDA` |
| 15 | 2,149,952 | 982,016 | 479.5 MiB | `reserved` |

Only partition 10 has the EFI System Partition type GUID. NVIDIA gives the
other partitions the Microsoft basic-data GUID, including `APP`.

Subiquity is then told that all 15 partitions already exist and must be
preserved as partition objects. It formats `APP` as ext4, formats `esp` as
FAT32, mounts them at `/` and `/boot/efi`, and leaves every other partition
unformatted.

## Boot finalization performed by NVIDIA

The late commands:

1. generate `/etc/nv_boot_control.conf` from UEFI variables or EEPROM data;
2. remove GRUB and its signed shim packages;
3. install the L4T kernel, initrd, DTB, OP-TEE, bootloader, and userspace;
4. run `nv-update-initrd`;
5. write `/boot/extlinux/extlinux.conf` with the `APP` PARTUUID;
6. copy L4TLauncher to `/boot/efi/EFI/BOOT/BOOTAA64.efi`;
7. reinstall `nvidia-l4t-bootloader`, which may stage a QSPI capsule update;
8. move the installer USB to the end of UEFI `BootOrder`.

The matching `nvidia-l4t-kernel-partitions` package also carries signed
kernel-only update payloads for the A/B kernel and DTB partitions. Lumina does
not need those partitions for the normal L4TLauncher/extlinux boot path, but
it preserves their exact layout so a future RPM can enable NVIDIA-compatible
A/B kernel updates and recovery.

## Lumina installer

The implementation is under `jetson/installer/`:

- `lumina-jetson-storage` performs board/target validation, creates or checks
  the GPT, and emits an Anaconda storage include;
- `layouts/orin.sfdisk.in` is the audited Orin layout;
- `lumina-jetson.ks` installs the Lumina desktop and complete Jetson RPM set,
  disables GRUB, and runs `lumina-jetson-boot-setup`;
- `grub.cfg.fragment` supplies explicit NVMe, eMMC, microSD, and USB entries.

Fresh mode requires root, a Tegra234 device tree, a supported whole disk of at
least 16 GiB, no mounted target partitions, and an exact erase confirmation.
The ISO menu supplies the confirmation only for entries whose label explicitly
says `ERASE`. USB autodetection succeeds only when exactly one non-installer
USB disk is present.

Reuse mode accepts an existing NVIDIA-created layout. It reformats `APP` but
does not format the ESP. The existing chain-reserved label variants used by
NVMe, eMMC, and SD are accepted.

## L4TLauncher asset

A fresh FAT ESP needs NVIDIA's 110,592-byte R39.2 `BOOTAA64.efi`. Build its
source archive reproducibly from the official ISO:

```bash
jetson/tools/extract_l4t_installer_assets.sh \
  /path/to/jetsoninstaller-r39.2.0-2026-06-01-23-53-13-arm64.iso
```

The extractor locates `nvidia-l4t-bootloader`, extracts only L4TLauncher and
its copyright file, verifies the known SHA-256, and creates the ignored source
archive consumed by `lumina-jetson-boot-assets.spec`.

## Building the offline ISO

The Fedora 44 Workstation Live ARM image is not a valid base for this flow.
Its `/usr/bin/liveinst` explicitly rejects every Kickstart argument and
continues interactively. An ISO made by merely adding this Kickstart to the
Workstation Live image would boot but would not use the Jetson partitioner.

`build-iso.sh` remasters Fedora's standard/Everything ARM64 network installer,
not `anaconda --liveinst`. It adds the Kickstart, storage helper, exact Orin
layout, GRUB menu, and an offline RPM repository. It also updates both GRUB
configurations: the copy in the ISO filesystem and the copy in the El Torito
EFI FAT image.

`remaster-runtime.sh` preserves Anaconda's dracut userspace while replacing
Fedora's installer kernel and the kernel modules in both the initramfs and
stage2 with `kernel-tegra-l4t`. It also changes the runtime buildstamp, OS
identity, console issue, and Anaconda profile to 1T Lumina. The installed
system uses the same Tegra kernel; the Kickstart excludes Fedora's generic
target kernel and GRUB packages.

The installer is local-media-only. The remaster removes Fedora dracut's iSCSI
root parser because it unconditionally probes `iscsi_tcp`, which NVIDIA's
Tegra kernel does not provide, even when no iSCSI root was requested.

The rootless compose omits SELinux xattrs from the rebuilt stage2 and boots
only the ephemeral installer runtime with `selinux=0`. The Kickstart explicitly
configures the installed Lumina system with SELinux enforcing.

The builder needs `xorriso`, `createrepo_c`, `mtools`, and `zstd`:

```bash
jetson/installer/build-iso.sh \
  /path/to/Fedora-Everything-netinst-aarch64-44-1.7.iso \
  /path/to/downloaded-workstation-rpms \
  /path/to/comps-Everything.aarch64.xml.zst \
  jetson/dist/Lumina-26.08-Jetson-Orin-aarch64.iso
```

The RPM root is searched recursively. It must contain the complete Fedora
Workstation transaction plus `dtc`, `i2c-tools`, `libi2c`, and `nvme-cli`.
Lumina and L4T RPMs are read from `jetson/dist/l4t-r39.2/RPMS`. The output is
accompanied by an `.iso.sha256` file.

Installer SSH can be enabled for a development image without committing a
personal key:

```bash
LUMINA_INSTALLER_SSH_KEY_FILE="${HOME}/.ssh/id_ed25519.pub" \
  jetson/installer/build-iso.sh BASE_ISO RPM_ROOT COMPS_XML OUTPUT_ISO
```

The key grants access only to the ephemeral installer environment. Release
images should omit it.

Before publishing an image, verify a complete offline dependency solve and
test the destructive install path on actual Jetson hardware.
