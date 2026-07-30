# 1T Lumina release package

`lumina-release` replaces Fedora's common, edition-identity, and variant
release packages while retaining their compatibility capabilities. It owns
the canonical operating-system metadata and the Fedora 44 systemd presets
needed by a Fedora-derived installation.

Lumina's public release is `26.08`. The package separately provides
`system-release(44)` and `system-release(releasever) = 44`, so
`fedora-repos` remains installable and DNF continues to resolve Fedora 44
repository paths instead of treating the Lumina version as a Fedora release.

The package provides:

- `1T Lumina` metadata through `os-release`, release compatibility links,
  CPE data, issue banners, and RPM distribution macros;
- the `.lu26` RPM distribution suffix;
- `GRUB_DISTRIBUTOR="1T Lumina"` and migration of existing Fedora-titled
  Boot Loader Specification entries;
- automatic reapplication of the GRUB label after `grub2-tools` updates;
- `/usr/share/lumina/logo.txt` and a system fallback configuration for
  fastfetch;
- Fedora repository and release-package compatibility for Fedora 44.

User fastfetch configuration continues to take precedence over the system
fallback.

## Build

Stage the package sources and build the RPM:

```bash
rpmdev-setuptree
install -m 0644 common/lumina-release/files/* "${HOME}/rpmbuild/SOURCES/"
install -m 0755 common/lumina-release/files/update-boot-branding \
  "${HOME}/rpmbuild/SOURCES/update-boot-branding"
install -m 0644 art/logo.txt "${HOME}/rpmbuild/SOURCES/logo.txt"
rpmbuild -ba common/lumina-release/lumina-release.spec
```

The install transaction intentionally obsoletes Fedora's basic, container,
server, or workstation release identity. It does not remove `fedora-repos`,
which remains the repository source for the Fedora 44 base.
