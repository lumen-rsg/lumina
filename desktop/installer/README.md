# Generic UEFI network installer

`build-iso.py` remasters a **Fedora 44 Everything netinstall ISO** with the
ten Lumina desktop RPMs and an Anaconda package profile. It supports
`aarch64` and `x86_64`; package architecture and base ISO signature/checksum
are checked before composition. It is a network installer, not a live desktop
or an offline Fedora mirror. Network access is needed for Fedora packages.

Run on a Fedora 44 builder of the **same architecture as the target ISO**
with `lorax`, `pykickstart`, `createrepo_c`, `rpm`,
`gnupg2`, `dosfstools`, `mtools`, and `squashfs-tools` installed.
Lorax rejects cross-architecture composition even when the RPMs and base ISO
are valid; use the native ARM64 or x64 builder for its respective image.
Import the reviewed Lumina signing key into that
builder's RPM keyring before composing release media. Example:

```sh
python3 desktop/installer/build-iso.py \
  --arch aarch64 \
  --base-iso Fedora-Everything-netinst-aarch64-44-1.7.iso \
  --checksum Fedora-Everything-44-1.7-aarch64-CHECKSUM \
  --fedora-key /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-44-primary \
  --rpms desktop/dist/RPMS \
  --output desktop/dist/Lumina-Cassiopeia-26.9-aarch64.iso
```

Use a directory containing only the matching native and noarch RPMs.
For local testing only, `--allow-unsigned-development-rpms` produces a
volume explicitly marked `-dev`; it does not relax installed repository
signature policy. Development media must not be promoted as a signed release.

The build uses an isolated `mkefiboot` helper to construct the FAT EFI image
with mtools. It preserves the Fedora EFI loaders and updated GRUB configuration
without mounting loop devices, allowing an unprivileged container builder.
An Anaconda product image supplies Lumina identity, installer colors and the
Lumina vector mark. Development images retain Anaconda's prerelease indication.

The profile leaves disk selection, partitioning and account creation to
Anaconda. It includes no automatic disk erasure command and no predefined
password. It enables GDM with the Lumina session and retains Fedora SELinux.
The installed RPM supplies signed Lumina repositories for subsequent updates.

ARM64 requires generic UEFI firmware, ACPI/device-tree and mainline graphics
support. This does not replace the board boot flows for Jetson or Orange Pi.
Firmware loading, graphical installation, account creation, first boot,
Secure Boot and physical-device operation require separate qualification.

Implementation reference: [Lorax mkksiso](https://weldr.io/lorax/mkksiso.html).
