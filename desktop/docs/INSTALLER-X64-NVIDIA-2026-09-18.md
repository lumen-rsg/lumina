# Cassiopeia x64 NVIDIA installer candidate

**Superseded after a physical USB boot failure.** The user reports that the
monitor loses signal while booting this installer on the RTX 4090 desktop,
before target NVIDIA packages are installed. The historical checks below do
not establish hardware compatibility. Use the
[Nouveau replacement candidate](INSTALLER-X64-NOUVEAU-2026-09-18.md), whose USB
installer uses basic graphics and whose installed desktop uses Nouveau/Mesa.

`Lumina-26.9-Cassiopeia-x86_64-NVIDIA-shell3.iso` is a 1,619,722,240-byte
UEFI network installer for Lumina 26.9 Cassiopeia. Its SHA-256 is:

```text
81ea96e9ae61e2c8cef2025f0577229cc39a99461cd2e3fb71ed5c5b2b61c1b6
```

This candidate targets the requested Ryzen 9 9950X / RTX 4090 desktop with
Secure Boot disabled. Write the ISO to USB, boot it in UEFI mode, connect
to the network, choose the installation disk and create an administrator
account. Disk selection and partitioning remain interactive. Fedora packages
are downloaded during installation; this is not a live or offline image.

The ISO bundles ten signed Lumina RPMs and eight signed NVIDIA RPMs. Shell
release 3 includes the restored control center, settings, sidebar tasks and
timers, media controls and provider-selected assistant. The existing signed
x64 Chroma/Quickshell base is retained. NVIDIA's desktop driver and open DKMS
module are version 615.71.09. The target receives NVIDIA's official repository
for subsequent updates. Driver compilation and initramfs generation must
succeed before installation finishes.

## Verification

- The shell update completed LuminaCI build, scan, sign and promotion stages
  in delivery `70268518-d2dd-43bb-920d-1faba881a246`.
- All ten Lumina inputs matched public repository metadata and downloaded RPM
  hashes. All eighteen bundled RPM signatures passed validation. Composition
  also verified the signed Fedora base checksum, and used no unsigned override.
- A native x64 empty-root installation resolved and installed the desktop,
  Fedora core group, kernel and NVIDIA profile. The final RPM inventory has
  925 records, including imported signing keys. The entire 922-package
  selection also resolved in one transaction with only Fedora and the bundled
  media repository enabled, including core and enforcing-SELinux dependencies.
- NVIDIA's open modules built for `7.2.5-200.fc44.x86_64`. The target post-install
  script passed its version/license checks and regenerated the initramfs.
  NVIDIA, modeset, UVM and DRM modules plus GSP firmware were present.
- The signed, installed x64 shell ran on headless Chroma with Qt software
  rendering. Control center, settings, assistant and clock opened through IPC,
  with no QML errors. This does not test physical control actions.
- The installer stage contains Intel AX210 (`iwlwifi`/`iwlmvm`) and Realtek
  RTL8852CE drivers and their firmware. The corresponding motherboard family
  lists these alternatives by board revision in its
  [official specifications](https://www.gigabyte.com/fi/Motherboard/B650M-AORUS-ELITE-AX-ICE-rev-1x/sp).
- The final ISO passed its embedded media check and the transferred copy
  matched the server's SHA-256. Extracted installer scripts matched source and
  the embedded kickstart passed Fedora 44 validation.

The initial module build in an unmounted container root failed because a
regular `/dev/null` polluted compiler probes. A target-like environment with
real device/proc/sys mounts passed. The installer now checks these mounts
explicitly before DKMS. The retained logs also contain container-only service
and logging warnings. No compiler or package source patch was needed.

An earlier candidate booted but Anaconda rejected its software selection
because NVIDIA conditionally requires `nvidia-driver-selinux` when targeted
SELinux policy is present. The final profile explicitly includes that signed
policy RPM and requires it during composition.

During preflight, the native server's software-emulated UEFI VM stalled at root handover.
The same final ISO subsequently reached the branded graphical Anaconda
installation summary with its installation source ready and custom software
selection accepted without errors, in the previously validated
local QEMU 10.2.2 environment: x86-64 TCG on ARM64, four vCPUs, 4 GiB RAM,
OVMF UEFI, Virtio display and a fresh disposable disk.

This candidate has **not** completed a fresh end-to-end installation or first
desktop login from this exact ISO. The physical RTX 4090 USB boot test failed as recorded above; installed desktop
graphics, motherboard Wi-Fi, suspend and multi-monitor operation remain unqualified. Secure Boot
signing/enrollment is outside this profile.

The [machine-readable record](evidence/cassiopeia-x86_64-nvidia-shell3-20260918.json)
contains artifact identities and log hashes. Raw local evidence is retained
under `desktop/evidence/iso-x64-20260918/`. NVIDIA packaging follows its
[official Fedora instructions](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/fedora.html).
