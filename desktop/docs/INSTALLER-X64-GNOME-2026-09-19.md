# Cassiopeia offline x64 installer: Nautilus and GNOME utilities

`Lumina-26.9-Cassiopeia-x86_64-Offline-Ly-v6-shell3.iso` supersedes the
[v5 NVMe image](INSTALLER-X64-NVME-2026-09-19.md). It contains 764 signed RPMs
and is 2,535,260,160 bytes. SHA-256:

```text
ef4b74e17f8ab64ca3cac89f13ecff8e0650fda53ba2ac7a970873caa325f89c
```

The ISO, `.iso.sha256` and `.packages.sha256` files are in `desktop/dist/`.
Installation remains offline with interactive disk selection and account setup.

## Changes

- Nautilus with GVfs replaces Dolphin. GNOME Calculator, Text Editor, Archive
  Manager (File Roller), Disks, System Monitor and Papers are included.
- Chroma-specific MIME defaults select Nautilus for folders, Text Editor for
  plain text and Papers for PDFs. Existing user overrides take precedence.
- RPM Fusion Free and Nonfree `44-3` release RPMs supply the stable release and
  updates repositories and public keys. Package signature checks stay enabled.
  Anaconda uses only local media for the offline transaction.
- Explicit vendor firmware selection fixes the missing Realtek firmware that
  prevented RTL8922AE Wi-Fi on v5. Other common wireless, GPU, audio and AMD
  microcode packages are also included despite weak dependencies being disabled.
- `pciutils` and `usbutils` supplement the already-required `nvme-cli` tools.

Ly, Chroma, Lumina Shell release 3, Nouveau/Mesa, NetworkManager and
NetworkManager-wifi remain. No Dolphin, GNOME Shell/session, GDM or vendor NVIDIA
driver is bundled. The kernel remains `7.2.5-200.fc44`, used by the successful
physical HDMI boot of the repaired v5 installation.

## Signed package delivery

Source `d91362e876dfb3020a63d9311f5208586b6349b4` completed LuminaCI delivery
`fe8cf45b-fed4-4ff6-b0c8-46be3eb936dd`. Build
`075aa32d-541e-4f7d-a06e-233d206d6836` produced
`lumina-desktop-26.9-5.lu26.noarch.rpm`, SHA-256
`fa0da6ca578a8ba39f2525ab3d4367015422b7b852128e04e34014ec21528dc5`.
It was signed with Lumina key `EBE39C736CAC92CEC2139DC7620675824776D3D7`
and published at `2026-09-18T23:20:14.386814Z`. The public noarch repository's
metadata and downloaded RPM match the signed CI artifact exactly.

The installer-update manifest selects only the changed desktop package and
reuses the existing signed `lumina-release-26.9-3.lu26` package. Its noarch desktop
RPM and source profiles also cover ARM64; this new ISO is x86-64 only.

## Verification boundary

- All 764 RPM signatures and the signed Fedora base ISO checksum passed.
- The complete mandatory package group resolved from an empty RPM database in
  a container with networking disabled. This was download-only, not a new
  installed-system transaction or VM installation test.
- Required GNOME applications, firmware, network and storage tools are present;
  excluded desktop sessions and drivers are absent.
- The embedded kickstart exactly matches source. Both RPM Fusion public keys
  match the source overlay, and installer-only remote repository exclusions are
  present. Packaged GNOME desktop IDs match the MIME defaults.
- Embedded media check passed and the transferred local ISO's SHA-256 matches
  the builder. Nine installer profile tests and source-accounting checks passed.
- Emulator tests remain paused. On 2026-09-19 the user reported that v6 was
  installed and working on the physical workstation. This is user-reported
  installation acceptance, not a new remotely observed test of every application.

Private build logs are under `desktop/evidence/offline-x64-gnome-20260919/`.
[Machine-readable record](evidence/cassiopeia-x86_64-offline-gnome-20260919.json).
