# Cassiopeia x64 offline installer with Ly

**Superseded by the [NVMe utilities update](INSTALLER-X64-NVME-2026-09-19.md).**
The user reported a physical NVMe installation failure because this image lacked
the `nvme-cli` RPM. Its successful Virtio-disk VM test did not cover that path.

The replacement installer includes Ly, Chroma, Lumina Shell release 3,
Mesa/Nouveau, NetworkManager, its NetworkManager-wifi plugin, and hardware
firmware on the ISO. Installation
does not need a network connection. Storage selection and account creation
remain interactive; the ISO contains no predefined user or password.

## Failure addressed

The second physical installation completed its RPM transaction, then failed
with `AnacondaError: Error enabling service gdm: 1` because `gdm.service` did
not exist. Anaconda's Software Selection screen had replaced the kickstart
package selection with `custom-environment` and the standard groups. The
target contained neither GDM nor the Lumina desktop, shell or compositor.

The installer now defines a **Lumina Desktop** environment whose mandatory
group includes the complete resolved desktop package set. Its local comps
metadata also defines the `core` group that Anaconda requests implicitly.
Revisiting Software Selection can therefore preserve the intended desktop.
The snapshot also includes Anaconda's partitioning and bootloader requirements
(Btrfs, FAT, ext4, XFS, encryption, LVM, RAID and GRUB tools) and locale data.
Ly replaces GDM, owns TTY1, and offers the Lumina Wayland session. Its packaged
configuration uses Cassiopeia colors and branding, with interactive PAM
authentication and enforcing SELinux. Other text consoles remain available.

The preceding download failure involved a transient failed RPM transfer;
the same RPM subsequently downloaded with the expected metadata checksum.
Its underlying transport cause was not established. Bundling the complete
package closure removes remote downloads from the installation transaction.

## Signing keys and identity

The earlier installer also tried to import the nonexistent
`RPM-GPG-KEY-fedora-26.9-x86_64`, deriving Fedora's key filename from Lumina's
version. Anaconda now explicitly imports Fedora's **44** architecture key and
the Lumina 2026 key. The composer verifies every bundled RPM signature, and
installed repositories retain GPG verification.

The product overlay supplies Lumina installer identity in both os-release
locations, a matching Anaconda profile, hostname, issue text and system-release
text. Boot menus, installer title, software environment and Ly use Lumina
branding. Installed base and updates repository display names are also Lumina.
Technical Fedora compatibility metadata, signing identities, repository IDs
and EFI paths are retained.

The signed packages were built from `0af68f905909ad35c86dbeabb34253be37816ad2`
through immutable-source LuminaCI delivery
`f62f94ff-2232-46ef-922b-f14d0223e090`. It published
`lumina-release-26.9-3.lu26.noarch` and `lumina-desktop-26.9-4.lu26.noarch`.
The remaining Lumina packages, including shell release 3 and Chroma release 2,
are unchanged. See the [machine-readable record](evidence/cassiopeia-x86_64-offline-ly-20260918.json).

## Artifact

`Lumina-26.9-Cassiopeia-x86_64-Offline-Ly-v4-shell3.iso` is a
2,290,352,128-byte UEFI offline installer containing 738 signed RPMs.
SHA-256:

```text
a45de9b503ef794cc878f3fad12baf90463da0b277c19d7aa50c56aa4dbea8d3
```

The image and its `.iso.sha256` and `.packages.sha256` sidecars are in
`desktop/dist/`. Write the ISO to USB and boot its normal install entry.
Installation does not require Wi-Fi or Ethernet. Select the intended disk and
create your account interactively. The installer uses basic graphics; the
installed desktop uses normal Mesa/Nouveau modesetting.

## Validation

The native empty-root transaction installed all 738 bundled RPMs using only
a local file repository inside a container with networking disabled. It
verified the desktop, compositor, shell, Ly, Wi-Fi and firmware packages;
Ly's SELinux executable type was `xdm_exec_t`. GDM and vendor NVIDIA drivers
were absent, and both expected signing keys imported successfully. Eight
installer profile tests passed.

The exact ISO passed the embedded media check and matched its SHA-256 after
transfer. In a fresh x86-64 QEMU 10.2.2 TCG VM with OVMF UEFI, 2 vCPUs, 4 GiB
RAM and a 32 GiB disk, Anaconda completed installation with the virtual network
cable disconnected. Reopening Software Selection retained Lumina Desktop.
Anaconda imported the Fedora 44 and Lumina keys successfully and automatically
rebooted into the installed Lumina UEFI entry. Lumina boot artwork appeared;
interactive Ly authentication launched Chroma and the Cassiopeia shell.
The control center and settings window both opened. No package or configuration
repair was needed to reach the desktop.

The user requested that emulator testing stop after these results. The VM is
paused with its state preserved. The final post-login audit of active services,
boot arguments, resolver state and SELinux AVCs was not completed; the native
empty-root checks above must not be represented as running-system checks.
The emulated text greeter showed malformed box-border glyphs, although its
session selection and login worked; physical console rendering is unverified.
Physical RTX 4090 graphics, Wi-Fi and other workstation testing remain with the
user. No current result qualifies ARM64 offline media or Secure Boot.
