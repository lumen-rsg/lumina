Name:           lumina-desktop
Version:        26.9
Release:        1.lu26
Summary:        Lumina Cassiopeia desktop composition
License:        MIT
URL:            https://github.com/lumen-rsg/lumina
Source0:        lumina.desktop
Source1:        lumina.repo
BuildArch:      noarch
Requires:       lumina-release >= 2:26.9
Requires:       lumina-artwork >= 26.9
Requires:       lumina-shell = 26.9
Requires:       chroma >= 0.1.0^20260911gitc310258
Requires:       gdm
Requires:       NetworkManager
Requires:       NetworkManager-wifi
Requires:       pipewire
Requires:       pipewire-pulseaudio
Requires:       wireplumber
Requires:       bluez
Requires:       gnome-keyring
Requires:       gnome-keyring-pam
Requires:       xdg-user-dirs
Requires:       xdg-utils
Requires:       adw-gtk3-theme
Requires:       breeze-icon-theme
Requires:       bibata-cursor-theme
Requires:       kitty
Requires:       dolphin
Requires:       firefox
Requires:       wl-clipboard
Requires:       cliphist
Requires:       libnotify
Requires:       power-profiles-daemon
Requires:       upower

%description
Common desktop package set for ARM64 and x86-64 Lumina systems. This session
uses the Chroma compositor and Lumina's end-4-derived Quickshell configuration.

%prep
%build
%install
install -Dpm0644 %{SOURCE0} %{buildroot}%{_datadir}/wayland-sessions/lumina.desktop
install -Dpm0644 %{SOURCE1} %{buildroot}%{_sysconfdir}/yum.repos.d/lumina.repo

%files
%{_datadir}/wayland-sessions/lumina.desktop
%config(noreplace) %{_sysconfdir}/yum.repos.d/lumina.repo

%changelog
* Fri Sep 11 2026 Lumina Linux <packages@linux.1t.ru> - 26.9-1.lu26
- Compose the Cassiopeia desktop for ARM64 and x86-64 systems
