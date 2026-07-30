# Neofetch for 1T Lumina

This package preserves upstream neofetch 7.1.0 and adds automatic recognition
of the `1T Lumina` name from `os-release`, along with Lumina's terminal art.

Neofetch is archived upstream, so Lumina carries the small downstream patch.
Fastfetch remains the preferred maintained utility.

## Build

```bash
rpmdev-setuptree
spectool -g -R common/neofetch/neofetch.spec
install -m 0644 common/neofetch/neofetch-7.1.0-lumina.patch \
  "${HOME}/rpmbuild/SOURCES/"
rpmbuild -ba common/neofetch/neofetch.spec
```
