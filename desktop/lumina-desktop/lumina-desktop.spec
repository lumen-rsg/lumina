Name:           lumina-desktop
Version:        26.9
Release:        4.lu26
Summary:        Lumina Cassiopeia desktop composition
License:        MIT
URL:            https://github.com/lumen-rsg/lumina
Source0:        lumina.desktop
Source1:        lumina.repo
Source2:        lumina-user-template
Source3:        ly-config.ini
Source4:        ly-lumina.conf
Source5:        50-lumina-display-manager.preset
BuildArch:      noarch
BuildRequires:  systemd-rpm-macros
Requires:       lumina-release >= 2:26.9
Requires:       lumina-artwork >= 26.9-2.lu26
Requires:       lumina-shell = 26.9
Requires:       chroma-compositor >= 0.1.0^20260911gitc310258-2.lu26
Requires:       ly >= 1.4.0
# Session launch needs the session bus executable even without weak dependencies.
Requires:       dbus-daemon
# Register logind sessions and start the user's systemd manager without relying
# on Fedora's weak dependencies in the minimal installer profile.
Requires:       systemd-pam
Requires:       selinux-policy-targeted
Requires:       policycoreutils-python-utils
Requires:       accountsservice
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
for role in standard administrator; do
    install -Dpm0644 %{SOURCE2} %{buildroot}%{_sysconfdir}/accountsservice/user-templates/$role
done
install -Dpm0644 %{SOURCE3} %{buildroot}%{_sysconfdir}/lumina/ly/config.ini
ln -s /etc/ly/lang %{buildroot}%{_sysconfdir}/lumina/ly/lang
install -Dpm0644 %{SOURCE4} %{buildroot}%{_unitdir}/ly@tty1.service.d/50-lumina.conf
install -Dpm0644 %{SOURCE5} %{buildroot}%{_presetdir}/50-lumina-display-manager.preset

%posttrans
# Fedora Ly's %%post attempts this before semanage is necessarily available.
# Finish its documented display-manager labeling after the whole transaction.
semanage fcontext -a -t xdm_exec_t /usr/bin/ly 2>/dev/null || \
    semanage fcontext -m -t xdm_exec_t /usr/bin/ly
restorecon /usr/bin/ly

%files
%{_datadir}/wayland-sessions/lumina.desktop
%config(noreplace) %{_sysconfdir}/yum.repos.d/lumina.repo
%config(noreplace) %{_sysconfdir}/accountsservice/user-templates/standard
%config(noreplace) %{_sysconfdir}/accountsservice/user-templates/administrator
%dir %{_sysconfdir}/lumina
%dir %{_sysconfdir}/lumina/ly
%config(noreplace) %{_sysconfdir}/lumina/ly/config.ini
%{_sysconfdir}/lumina/ly/lang
%{_unitdir}/ly@tty1.service.d/
%{_presetdir}/50-lumina-display-manager.preset

%changelog
* Fri Sep 18 2026 Lumina Linux <packages@linux.1t.ru> - 26.9-4.lu26
- Use the lightweight Ly greeter with a Lumina Wayland session and branding

* Fri Sep 11 2026 Lumina Linux <packages@linux.1t.ru> - 26.9-3.lu26
- Require the compositor clipboard selection fix

* Fri Sep 11 2026 Lumina Linux <packages@linux.1t.ru> - 26.9-2.lu26
- Select the compositor RPM explicitly and include D-Bus and PAM session support
- Default new accounts to Lumina and brand the graphical greeter

* Fri Sep 11 2026 Lumina Linux <packages@linux.1t.ru> - 26.9-1.lu26
- Compose the Cassiopeia desktop for ARM64 and x86-64 systems
