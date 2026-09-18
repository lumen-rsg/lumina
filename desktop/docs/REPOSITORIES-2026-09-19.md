# RPM Fusion and desktop application update

RPM Fusion Free and Nonfree release and updates repositories were installed on
the physical Cassiopeia workstation using upstream `44-3.noarch` release RPMs.
Their signature checks passed, metadata refresh succeeded and `akmod-nvidia`
was visible in stable Nonfree repositories. Nouveau remained bound to the RTX
4090. Only the two release RPMs were installed by this operation; no vendor
driver or codec replacement was installed. All enabled RPM Fusion repositories
have `gpgcheck=1`; testing, source and debug repositories remain disabled.

The installer source selects both release packages for ARM64 and x86-64. Its
offline preparation downloads them directly, pins their SHA-256 values and
checks signatures in an isolated RPM database. Network images carry them in
the media repository. Both signing keys are included in the Anaconda overlay;
remote RPM Fusion repositories are disabled during offline installation.

Upstream sources:

- [Free release package](https://download1.rpmfusion.org/free/fedora/updates/44/x86_64/r/rpmfusion-free-release-44-3.noarch.rpm)
- [Nonfree release package](https://download1.rpmfusion.org/nonfree/fedora/updates/44/x86_64/r/rpmfusion-nonfree-release-44-3.noarch.rpm)
- [Free signing key source](https://github.com/rpmfusion/rpmfusion-free-release/blob/master/RPM-GPG-KEY-rpmfusion-free-fedora-2020)
- [Nonfree signing key source](https://github.com/rpmfusion/rpmfusion-nonfree-release/blob/master/RPM-GPG-KEY-rpmfusion-nonfree-fedora-2020)

The key files matched between those upstream repositories and the HTTPS
download server. Reviewed fingerprints:

```text
Free:    E9A491A3DE247814E7E067EAE06F8ECDD651FF2E
Nonfree: 79BDB88F9BBF73910FD4095B6A2AF96194843C65
```

The bootstrap ran successfully on the Fedora builder with fresh downloads.
A download-only transaction using those two local RPMs and no enabled network
repositories passed against the existing installed Lumina package database.
Nine installer profile tests pass, including corrupted bootstrap RPM rejection.

`lumina-desktop-26.9-5.lu26` replaces Dolphin with Nautilus/GVfs and adds GNOME
Calculator, Text Editor, File Roller, Disks, System Monitor and Papers. It ships
Chroma-specific MIME defaults for folders, text and PDF documents. The local
noarch RPM build and offline source-accounting check passed. The package was
subsequently signed and published, and included in the
[v6 offline ISO](INSTALLER-X64-GNOME-2026-09-19.md). Its media, package signatures,
offline dependency resolution and transferred checksum passed. Emulator tests
remain paused; application runtime testing is pending.
