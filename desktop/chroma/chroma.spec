%global commit 319c020a2eab9c8874547c2cd4ac88b732738492
%global _smp_ncpus_max 2
Name:           chroma-compositor
Version:        0.1.0^20260919git319c020
Release:        1.lu26
Summary:        Spatial Wayland compositor for Lumina
License:        MIT
URL:            https://github.com/lumen-rsg/chroma
Source0:        https://github.com/lumen-rsg/chroma/archive/%{commit}/chroma-%{commit}.tar.gz
Source1:        chroma-shell
Source2:        chroma-polkit-agent
Source3:        test-clipboard-integration.sh
Patch0:         0001-handle-clipboard-selection-requests.patch
ExclusiveArch:  aarch64 x86_64
BuildRequires:  gcc-c++
BuildRequires:  meson
BuildRequires:  ninja-build
BuildRequires:  pkgconfig(wlroots-0.20)
BuildRequires:  pkgconfig(wayland-server)
BuildRequires:  pkgconfig(wayland-client)
BuildRequires:  pkgconfig(wayland-protocols)
BuildRequires:  pkgconfig(xkbcommon)
BuildRequires:  pkgconfig(pixman-1)
BuildRequires:  pkgconfig(systemd)
BuildRequires:  python3
BuildRequires:  wl-clipboard
Requires:       lumina-shell >= 26.9-4.lu26
Requires:       xorg-x11-server-Xwayland
Requires:       wl-clip-persist
Requires:       swayidle
Requires:       swaylock
Requires:       wlopm
Requires:       wdisplays
Requires:       polkit-kde
Requires:       xdg-desktop-portal
Requires:       xdg-desktop-portal-gtk
Requires:       xdg-desktop-portal-wlr
Requires:       grim
Requires:       slurp
Requires:       wireplumber
Requires:       brightnessctl
Requires:       kitty
Requires:       python3
Requires:       dbus-tools
Requires:       /usr/bin/dbus-run-session
Requires:       systemd
# Fedora's unrelated puzzle game owns /usr/bin/chroma. Keep the RPM identity
# distinct so dependency solving cannot select that package as our compositor.
Conflicts:      chroma

%description
Chroma's infinite spatial canvas, teleport points, card stacks, Wayland
protocols and session helpers. This package uses Lumina Shell and explicitly
excludes the upstream Chroma Quickshell configuration.

%prep
echo '90b54d9dd6baf7c2aa8256232ec5eb5abcf5039ea3f87fc618e9047941f2be78  %{SOURCE0}' | sha256sum -c -
%autosetup -p1 -n chroma-%{commit}

%build
%meson
%meson_build

%install
%meson_install
# Do not ship Chroma's first-party shell or its desktop entry.
rm -rf %{buildroot}%{_datadir}/chroma/shell
rm -f %{buildroot}%{_datadir}/wayland-sessions/chroma.desktop
install -pm0755 %{SOURCE1} %{buildroot}%{_bindir}/chroma-shell
install -pm0755 %{SOURCE2} %{buildroot}%{_bindir}/chroma-polkit-agent

%check
# Integration requires a nested Wayland session; run it in desktop QA.
%meson_test --no-suite integration
python3 tests/test_shell_dispatch.py
bash %{SOURCE3} %{_vpath_builddir}/chroma

%files
%license LICENSE
%doc README.md
%{_bindir}/chroma
%{_bindir}/chroma-*
%{_userunitdir}/chroma-session.target
%{_datadir}/xdg-desktop-portal/chroma-portals.conf

%changelog
* Sat Sep 19 2026 Lumina Linux <packages@linux.1t.ru> - 0.1.0^20260919git319c020-1.lu26
- Pin Chroma with unified Cassiopeia startup and IPC delegation
- Require the matching spatial shell and retain the tested clipboard patch

* Fri Sep 11 2026 Lumina Linux <packages@linux.1t.ru> - 0.1.0^20260911gitc310258-2.lu26
- Handle regular and primary clipboard selection requests
- Run both clipboard round trips in an isolated headless compositor at build time

* Fri Sep 11 2026 Lumina Linux <packages@linux.1t.ru> - 0.1.0^20260911gitc310258-1.lu26
- Package pinned Chroma compositor and session helpers with Lumina Shell
- Use an unambiguous compositor package name and require the session bus tool
