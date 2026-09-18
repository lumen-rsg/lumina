# Cassiopeia offline x64 installer: NVMe utilities

Superseded by the [v6 firmware, RPM Fusion and GNOME utilities image](INSTALLER-X64-GNOME-2026-09-19.md).

`Lumina-26.9-Cassiopeia-x86_64-Offline-Ly-v5-shell3.iso` replaces the
[v4 offline Ly image](INSTALLER-X64-OFFLINE-LY-2026-09-18.md). It contains
739 signed RPMs and is 2,291,531,776 bytes. SHA-256:

```text
bc54efbca5cedf78ef380f6edbce5d2b97acdcfd148a4b804914da3385921c40
```

The ISO and its `.iso.sha256` and `.packages.sha256` sidecars are in
`desktop/dist/`. Flash this replacement and use its normal install entry.
Installation remains offline, with interactive disk selection and account creation.

## Fix

The user reported that Anaconda crashed on physical NVMe storage because
`nvme-cli` was missing. The base installer runtime already contains
`/usr/bin/nvme`; the gap was the target RPM in the offline package repository.
The previous VM used a Virtio disk and did not qualify NVMe installation.

`nvme-cli` is now an explicit installer package and part of the mandatory
Lumina Desktop environment. The offline composer rejects snapshots without it.
The updated regression assertion covers package retention when Software
Selection is revisited, for both supported architecture profiles.

The frozen v4 snapshot was extended with only
`nvme-cli-2.16-3.fc44.x86_64.rpm`; all 738 previous RPMs are byte-identical.
Its required `libnvme-1.16.2-1.fc44.x86_64` was already included. Ly,
NetworkManager, NetworkManager-wifi, Mesa/Nouveau, the existing firmware RPMs, Lumina branding
and the signing-key correction are retained.

## Verification boundary

- All 739 bundled RPM signatures and the signed base ISO checksum passed
  the composer gates. The added NVMe RPM also passed an independent signature check.
- An empty-root dependency transaction resolved and downloaded all 739 packages
  using only the local repository in a container with networking disabled.
  This checks dependency completeness; it is not another installation test.
- The final ISO contains both NVMe RPMs. Its extracted kickstart matches the
  source exactly and explicitly selects `nvme-cli`.
- The embedded media check passed, and the transferred local ISO's SHA-256
  matches the builder's copy. All eight installer profile tests passed.
- Emulator tests remain paused at the user's request. The v4 installation and
  first-login results do not qualify this new exact image or physical NVMe storage.
  Physical installation testing remains with the user.

## Subsequent physical report

The user reports that installation completed, but installed boot lost video
before Ly and Wi-Fi was unavailable. An installed-system terminal was later
available. The subsequent SSH findings and HDMI recovery are recorded below.

Inspection of the exact v5 manifest found only `linux-firmware`,
`linux-firmware-whence` and `nvidia-gpu-firmware`. Querying the bundled
`linux-firmware-20260916-1.fc44` RPM showed that the AMD/Intel GPU and common
wireless vendor firmware packages are Recommends, omitted by our explicit
weak-dependency exclusion. Intel wireless firmware packages were also absent.
`pciutils` and `usbutils` were missing as well.

The installer source now explicitly selects those firmware and diagnostic
packages, and composition requires every explicit target package in an offline
snapshot. This does not alter the existing v5 ISO. The user subsequently reported
failed firmware loads for `rtw89` and `rtl_bt/rtl8922au`. The downloaded signed
`realtek-firmware-20260916-1.fc44.noarch.rpm` contains `rtw89` firmware and both
`rtl8922au` Bluetooth files. A reported SELinux undefined-permission warning
does not by itself establish a firmware access denial; enforcement is unchanged.
NVIDIA firmware was already present; subsequent investigation localized video
loss to DisplayPort link training. Emulator testing remains paused.

An offline repair archive, `Lumina-26.9-x86_64-firmware-repair-20260919.tar`,
contains 19 added firmware/diagnostic RPMs, checksums and instructions. All RPM
signatures passed, and `rpm --test -Uvh` passed against the native v4 installed
database (v5 adds only `nvme-cli`). Archive size: 258,457,600 bytes; SHA-256:

```text
5777ca63d7afae61c9e989207d4d1c472a1a6cc4083ed0bfa047df839614e4b1
```

The Realtek RPM is also provided separately for a minimal USB Wi-Fi repair.
The ISO has not been rebuilt. All eight installer profile tests pass with the
updated firmware retention assertions; physical recovery is described below.

## SSH inspection after the Realtek repair

Direct inspection of the installed workstation confirmed RTL8922AE
`10ec:8922` bound to `rtw89_8922ae`, successful loading of
`rtw89/rtw8922a_fw-4.bin`, and connected Wi-Fi. Bluetooth also loaded its
`rtl8922au` firmware/configuration successfully (peripheral operation untested).
The previous boot recorded missing-file errors (`-2`) for those firmware files.
SELinux remained enforcing; the kernel explicitly said unknown permissions
would be allowed. Installed `pciutils` and `usbutils` for further diagnosis.

The original native-modesetting boot identified the Palit RTX 4090
`10de:2684`, initialized Nouveau with GSP firmware 570.144, then repeatedly
failed DisplayPort link training (`DP_TRAIN`, `ret:-5`, control `0x00731343`).
The initial recovered boot used a temporary `nomodeset` argument and simpledrm.
Ly is running, and no system units are failed. These observations localize
video loss to the native DisplayPort path; the exact driver/firmware/link
cause is not yet established.

## Physical HDMI recovery

The user reports that the screen works after switching from DisplayPort to
HDMI and booting with modesetting enabled. SSH verification confirms no
`nomodeset` in the running kernel arguments, Nouveau bound to the RTX 4090,
`HDMI-A-1` connected, and Chroma plus `/usr/share/lumina-shell` Quickshell
running. Wi-Fi remains connected and no system units are failed. The successful
boot has no `DP_TRAIN` errors; all three DisplayPort connectors are disconnected.

This confirms native Nouveau display and desktop startup over HDMI on the
installed workstation after the Realtek firmware repair. It does not isolate
whether the DisplayPort cable, port, monitor or driver interoperability caused
the failed link, and does not qualify DisplayPort, suspend or gaming workloads.
SSH was enabled across boots with explicit user approval for diagnosis.

Raw kernel logs are retained privately under
`desktop/evidence/physical-x64-20260919/`. The existing v5 ISO remains unchanged.

[Machine-readable record](evidence/cassiopeia-x86_64-offline-nvme-20260919.json).
