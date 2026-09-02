%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}

Name:           orangepi-zero3-tools
Version:        1.0.6
Release:        6.lu26
Summary:        Board configuration and radio tools for Orange Pi Zero 3
License:        GPL-2.0-or-later
URL:            https://github.com/orangepi-xunlong/orangepi-build
ExclusiveArch:  aarch64
Source0:        %{name}-%{version}.tar.gz
Source1:        orangepi-config
Source2:        orangepi-release
Source3:        orangepi-zero3-bluetooth.service
Source4:        orangepi-zero3-wifi.service
Source5:        86-orangepi-zero3.preset
Source6:        orangepi-zero3-wait-wifi
Source7:        orangepi-zero3-wait-bluetooth
Source8:        orangepi-zero3-networkmanager.conf
Source9:        orangepimonitor

BuildRequires:  systemd-rpm-macros
Requires:       bash
Requires:       bluez
Requires:       coreutils
Requires:       dtc
Requires:       dialog
Requires:       iproute
Requires:       iw
Requires:       memtester
Requires:       NetworkManager-tui
Requires:       NetworkManager-wifi
Requires:       procps-ng
Requires:       systemd
Requires:       util-linux
Requires:       wpa_supplicant
Requires:       orangepi-zero3-firmware = %{version}-1.lu26

%description
Lumina-native Orange Pi configuration and read-only monitoring frontends plus
the user overlay compiler and Unisoc Bluetooth attach helper extracted from
the Orange Pi 1.0.6 Zero 3 image. The original Debian-oriented orangepi-config
library is retained under a vendor data directory for provenance, but is not
executed by the Lumina frontends.

%prep
%autosetup

%build

%install
install -Dpm 0755 %{SOURCE1} %{buildroot}%{_sbindir}/orangepi-config
install -Dpm 0644 %{SOURCE2} %{buildroot}%{_sysconfdir}/orangepi-release
install -Dpm 0755 usr/bin/hciattach_opi %{buildroot}%{_bindir}/hciattach_opi
install -Dpm 0755 %{SOURCE9} %{buildroot}%{_bindir}/orangepimonitor
install -Dpm 0755 usr/bin/memtester.sh %{buildroot}%{_bindir}/memtester.sh
install -Dpm 0755 usr/sbin/orangepi-add-overlay %{buildroot}%{_sbindir}/orangepi-add-overlay
mkdir -p %{buildroot}%{_prefix}/lib/orangepi-config-vendor
cp -a usr/lib/orangepi-config/. %{buildroot}%{_prefix}/lib/orangepi-config-vendor/
install -Dpm 0644 %{SOURCE3} %{buildroot}%{_unitdir}/orangepi-zero3-bluetooth.service
install -Dpm 0644 %{SOURCE4} %{buildroot}%{_unitdir}/orangepi-zero3-wifi.service
install -Dpm 0644 %{SOURCE5} %{buildroot}%{_presetdir}/86-orangepi-zero3.preset
install -Dpm 0755 %{SOURCE6} %{buildroot}%{_libexecdir}/orangepi-zero3-wait-wifi
install -Dpm 0755 %{SOURCE7} %{buildroot}%{_libexecdir}/orangepi-zero3-wait-bluetooth
install -Dpm 0644 %{SOURCE8} %{buildroot}%{_sysconfdir}/NetworkManager/conf.d/90-orangepi-zero3.conf

%post
%systemd_post orangepi-zero3-wifi.service orangepi-zero3-bluetooth.service

%preun
%systemd_preun orangepi-zero3-wifi.service orangepi-zero3-bluetooth.service

%postun
%systemd_postun_with_restart orangepi-zero3-wifi.service orangepi-zero3-bluetooth.service

%files
%config(noreplace) %{_sysconfdir}/orangepi-release
%config(noreplace) %{_sysconfdir}/NetworkManager/conf.d/90-orangepi-zero3.conf
%{_bindir}/hciattach_opi
%{_bindir}/orangepimonitor
%{_bindir}/memtester.sh
%{_sbindir}/orangepi-add-overlay
%{_sbindir}/orangepi-config
%{_prefix}/lib/orangepi-config-vendor/
%{_unitdir}/orangepi-zero3-bluetooth.service
%{_unitdir}/orangepi-zero3-wifi.service
%{_presetdir}/86-orangepi-zero3.preset
%{_libexecdir}/orangepi-zero3-wait-wifi
%{_libexecdir}/orangepi-zero3-wait-bluetooth

%changelog
* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 1.0.6-6.lu26
- Replace the Debian-only monitor frontend and require its memory-test backend

* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 1.0.6-5.lu26
- Keep the vendor Wi-Fi MAC stable and start bluetoothd after hci0 appears

* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 1.0.6-4.lu26
- Load the UWE5622 stack after the real root and firmware are available

* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 1.0.6-3.lu26
- Install the Fedora Wi-Fi plugin, WPA supplicant, and wireless diagnostics

* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 1.0.6-2.lu26
- Sequence Bluetooth after Wi-Fi readiness without a failing restart loop

* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 1.0.6-1.lu26
- Add a Fedora-native Zero 3 configuration UI and extracted board tools
