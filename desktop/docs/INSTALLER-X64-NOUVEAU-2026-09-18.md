# Cassiopeia x64 Nouveau installer candidate

`Lumina-26.9-Cassiopeia-x86_64-Nouveau-shell3.iso` is a 1,353,383,936-byte
UEFI network installer. SHA-256:

```text
d489a0a391222c9b937c8c1ed81a07ffbfc6d09fd6ba64aed4f48747c1c86487
```

Write this replacement ISO to USB and select the normal install entry. All USB
boot entries now use basic graphics (`nomodeset`), including the default media
check. During installation connect to the network, select the disk and create
an administrator account. Partitioning remains interactive. This is a network
installer, not a live or offline image.

## Graphics change

The user reported monitor signal loss during USB boot of the previous NVIDIA
candidate on the RTX 4090 / Ryzen 9 9950X machine, with Secure Boot disabled.
At that stage the bundled target driver had not been installed. This image
therefore changes both the installer boot mode and the installed graphics stack.

The installed desktop uses Nouveau and Mesa. Fedora GPU firmware is retained,
including AD102 GSP files. No NVIDIA vendor driver, CUDA runtime, DKMS/akmod
module, NVIDIA repository configuration or Nouveau blacklist is installed by
the profile. An error-checked post-install step removes installer-only
`nomodeset` from target boot entries and persistent templates, enabling native
modesetting for Chroma/Wayland. Optional vendor drivers remain a later user
choice; see [driver packaging notes](../installer/README.md#default-graphics).

The ten signed Lumina RPMs retain shell release 3, including control center,
settings, sidebar tasks/timers/media and the provider-selected assistant.

## Verification

- Signed Fedora base checksum, all ten bundled RPM signatures, embedded media
  checksum and transferred SHA-256 passed. Embedded kickstart matches the
  committed source and passes Fedora 44 validation. ISO inventory contains
  no `NvidiaSupport` directory or bundled vendor NVIDIA RPMs.
- A fresh native x64 target installed all 823 packages in one transaction using
  only Fedora and the signed Lumina media repository. It contains kernel
  `7.2.5-200.fc44`, Mesa `26.2.2-6.fc44` and firmware `20260916-1.fc44`.
- Native target inventory confirms absence of the vendor driver and Nouveau
  blacklist. Default generic initramfs generation includes `nouveau.ko` and
  AD102 GSP firmware, without forcing an extra driver in the generation command.
- The actual post-install cleanup removed `nomodeset` from a fixture BLS entry,
  existing native target entries, GRUB defaults and `/etc/kernel/cmdline`.
- The exact transferred ISO passed the media check and reached the branded
  graphical Anaconda summary in QEMU 10.2.2 x64 TCG on ARM64, OVMF UEFI,
  four vCPUs, 4 GiB RAM, standard VGA and a fresh 32 GiB disk. Installation
  Source was ready and Software Selection reported `Custom software selected`,
  with no dependency error. Disk/account setup remains intentionally interactive.

The native container checks log an unavailable syslog socket; initramfs
generation completed successfully. The initial Virtio GPU VM preview had no
active display with basic graphics, so the framebuffer boot check uses QEMU's
standard VGA device instead. This is a VM display change, not an ISO modification.

Physical RTX 4090 boot/display, motherboard Wi-Fi and installed desktop operation
remain unqualified. The exact image has not completed a full Anaconda install
and first desktop login. The previous image's physical failure is retained in
[its historical record](INSTALLER-X64-NVIDIA-2026-09-18.md).

[Machine-readable evidence](evidence/cassiopeia-x86_64-nouveau-shell3-20260918.json)
records package hashes and checks. Raw evidence is under
`desktop/evidence/iso-x64-nouveau-20260918/`.
