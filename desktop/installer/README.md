# UEFI network installer with Mesa and Nouveau

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

## Default graphics

The default `--graphics mesa` profile installs Fedora's Mesa OpenGL/Vulkan
packages and in-kernel graphics drivers, including Nouveau for NVIDIA hardware.
`nvidia-gpu-firmware` is deliberately retained: Nouveau needs the GPU firmware.
Vendor NVIDIA drivers, CUDA libraries, DKMS/akmod modules and NVIDIA repository
configuration are not bundled or activated. The composer rejects vendor NVIDIA
RPMs accidentally supplied to the Mesa profile.

For the x64 replacement image, use `--graphics mesa --installer-graphics basic`.
The latter adds `nomodeset` to USB installer boot entries, following Fedora's
[basic graphics boot option](https://fedoraproject.org/wiki/QA:Testcase_Anaconda_User_Interface_Basic_Video_Driver).
The installed system must use native modesetting for Chroma/Wayland. A fatal-on-error
post-install step removes `nomodeset` from installed kernel entries, GRUB defaults
and the kernel command-line template. This intentionally differs from Fedora's
normal basic-mode persistence. ARM64 media retains standard boot graphics unless
explicitly requested otherwise.

The previous NVIDIA candidate lost monitor signal while booting the USB installer
on the user's RTX 4090 machine. At that stage its bundled target driver was not
installed. Basic installer graphics addresses that boot path; physical confirmation
is still required. See the [replacement image record](../docs/INSTALLER-X64-NOUVEAU-2026-09-18.md).

Users can opt into a vendor driver after installation. RPM Fusion calls its
package `akmod-nvidia` (not `nvidia-akmod`); see its
[Fedora 44 package listing](https://archive.rpmfusion.org/Mirrors/rpmfusion.org/nonfree/fedora/nvidia-driver/44/x86_64/a/)
and [setup guide](https://rpmfusion.org/Howto/NVIDIA). This is RPM Fusion packaging,
not a Fedora-provided driver. Repository/package naming must match the provider: NVIDIA's official Fedora guide currently uses
`nvidia-open` for the full stack, or `nvidia-driver kmod-nvidia-open-dkms` for a
desktop-only installation. See the
[official NVIDIA guide](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/fedora.html)
for repository setup. No driver installation runs automatically.

## Installer network compatibility profile

The x64 `Nouveau-netfix2-shell3` image is composed with
`--graphics mesa --installer-graphics basic --installer-network ipv4-dns`.
The network option reproduces the successful workaround for a physical install
that had a working IPv4 route but stalled fetching sources until its DNS and
IPv6 settings were overridden. The combined workaround succeeded; this does
not isolate DNS versus IPv6 as the sole cause.

This option adds `ipv6.disable=1` to USB boot entries and runs an error-checked
kickstart `%pre` before repository setup. The pre-script writes a per-boot
NetworkManager global DNS configuration under `/run/NetworkManager/conf.d`,
using `1.1.1.1` and `8.8.8.8`, selects NetworkManager's direct DNS backend and
points the live resolver symlink at its generated file, then reloads DNS.
The direct backend is necessary: the Fedora installer uses systemd-resolved,
which did not apply the NM global override in the initial boot test. Global DNS covers both existing
connections and Wi-Fi connections subsequently created in Anaconda. It does
not contain a device name, SSID or credentials. See
[NetworkManager global DNS configuration](https://networkmanager.dev/docs/api/latest/NetworkManager.conf.html#global-dns-section).

The target post-script removes the installer-only `ipv6.disable` argument from
kernel entries and persistent templates. The runtime DNS override is not
copied into the installed system. The post-script restores the installed
systemd-resolved stub symlink. This is an installer compatibility option;
it does not impose a permanent IPv4-only/public-DNS policy on installed desktops.
Public DNS must be reachable on the installation network. The default `auto`
profile keeps normal network-provided DNS and IPv6 for other networks, including
IPv6-only and split-DNS environments. [Verification record](../docs/INSTALLER-X64-NETFIX-2026-09-18.md).

## Historical NVIDIA compose profile

`--graphics nvidia-open --driver-rpms DIRECTORY` remains available for reproducing
historical package tests, but is not the default or the recommended replacement
image. It requires signed NVIDIA RPMs and the matching imported signing key;
its target script builds DKMS modules and configures NVIDIA updates. It targets
Secure Boot disabled and does not enroll a signing certificate. The
[previous candidate record](../docs/INSTALLER-X64-NVIDIA-2026-09-18.md)
retains those checks and the subsequent physical boot failure.

Implementation reference: [Lorax mkksiso](https://weldr.io/lorax/mkksiso.html).
