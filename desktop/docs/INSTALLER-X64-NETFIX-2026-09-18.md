# Cassiopeia x64 installer network compatibility fix

**Superseded by the [offline installer with Ly](INSTALLER-X64-OFFLINE-LY-2026-09-18.md).**
The subsequent physical installation failures and replacement are documented there.

`Lumina-26.9-Cassiopeia-x86_64-Nouveau-netfix2-shell3.iso` is a 1,353,383,936-byte
UEFI network installer. SHA-256:

```text
2c9d9f693455af5eb39fec6751b0505f241e1a281b09ddaf5fef41b52c51c417
```

Flash this replacement and use the normal install entry. Join Wi-Fi in Anaconda;
the installer applies the network workaround automatically. Disk selection and
account creation remain interactive. Internet access is required for Fedora
packages. The ten bundled signed Lumina RPMs are unchanged from the preceding
Nouveau shell3 image, including the restored shell panels and settings.

## Problem and change

The user confirmed that the preceding Nouveau image booted on the physical
RTX 4090 system. Wi-Fi had a DHCP IPv4 address and default route, and numeric-IP
pings succeeded, but installation stalled fetching sources. Temporarily selecting
public IPv4 DNS and disabling IPv6 restored access. This identifies a successful
combined workaround; it does not establish DNS versus IPv6 as the sole cause.

The `--installer-network ipv4-dns` compose option sets `ipv6.disable=1` for USB
boot. An error-checked `%pre` installs a runtime NetworkManager global DNS override
using `1.1.1.1` and `8.8.8.8` before repository setup. It selects NetworkManager's
direct DNS backend, points the live resolver symlink at its generated file,
and reloads DNS. Global DNS
also covers Wi-Fi connections created or activated later in the installer.
No hardware interface name, SSID or credentials are embedded.

The override lives under `/run` and is not copied to the target. A checked
post-install step removes `ipv6.disable` from installed boot entries, GRUB defaults
and the kernel command-line template, and restores the installed systemd-resolved
stub symlink. This does not permanently disable IPv6 or
set public DNS on the installed desktop. The existing Nouveau/Mesa selection and
installer-only basic graphics workaround remain in place.

Other installers can retain `--installer-network auto`, the default, for networks
requiring IPv6 or local/split DNS. The compatibility mode requires access to its
public IPv4 DNS servers. See the [compose documentation](../installer/README.md).

## Verification

- All six installer profile tests passed. Embedded kickstart matches source and
  passes Fedora 44 validation; every boot entry has the selected compatibility
  arguments. Fedora base and bundled RPM signatures were checked during compose.
- In an isolated native x64 environment with systemd-resolved auto-detected from
  its stub symlink (as in the installer), a connection deliberately
  configured with an unreachable resolver failed repository access with a DNS
  timeout. The actual embedded pre-script restored access; reactivating the bad-DNS
  profile still used the direct public-DNS override and fetched Fedora metadata.
- The actual target post-script removed the IPv6 argument from BLS entries and
  both persistent command-line templates and restored the target resolved stub
  symlink. Source inspection confirms Anaconda
  copies only its named global-DNS files, not this runtime override.
- The embedded media check and transferred SHA-256 passed. The RPM manifest is
  identical to the preceding signed Nouveau image.
- The final exact ISO booted into graphical Anaconda in QEMU 10.2.2 x64 TCG
  on ARM64, with OVMF UEFI, 4 vCPUs, 4 GiB and standard VGA. Runtime inspection
  confirmed `ipv6.disable=1` and the successful pre-script. The active
  `/etc/resolv.conf` listed exactly `1.1.1.1` and `8.8.8.8`. Installation Source
  then became ready and Software Selection reported `Custom software selected`.
  Disk selection and account creation remain intentionally interactive.

The first network candidate reached Anaconda but runtime inspection showed that
systemd-resolved still used DHCP DNS. That candidate is rejected, with SHA-256
`741c85819d0611836cb4b0e322c44120298fcb582141eb3c75746139d5213a4a`.
The replacement explicitly selects the direct DNS backend. Source fetching
alone was insufficient evidence that the DNS override was active.

Physical acceptance applies to the user-reported predecessor and manual
workaround; the new exact ISO still needs physical confirmation. No complete
Anaconda installation or first installed desktop login is claimed.

[Machine-readable evidence](evidence/cassiopeia-x86_64-netfix-shell3-20260918.json)
records hashes and checks. Raw evidence is under
`desktop/evidence/iso-x64-netfix-20260918/`.
