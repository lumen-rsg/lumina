# Cassiopeia offline x64 installer: NVMe utilities

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
NetworkManager, NetworkManager-wifi, Mesa/Nouveau, firmware, Lumina branding
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

[Machine-readable record](evidence/cassiopeia-x86_64-offline-nvme-20260919.json).
