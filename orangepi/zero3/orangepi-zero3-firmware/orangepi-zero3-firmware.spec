%global debug_package %{nil}
%global __os_install_post %{nil}

Name:           orangepi-zero3-firmware
Version:        1.0.6
Release:        1.lu26
Summary:        Unisoc UWE5622 firmware for Orange Pi Zero 3
License:        LicenseRef-OrangePi-Firmware
URL:            https://github.com/orangepi-xunlong/firmware
BuildArch:      noarch
Source0:        %{name}-%{version}.tar.gz

AutoReqProv:    no

%description
The focused firmware and radio configuration set loaded by the onboard Unisoc
UWE5622 Wi-Fi and Bluetooth controller on Orange Pi Zero 3. The files are
extracted from the matching Orange Pi 1.0.6 reference system.

%prep
%autosetup

%build

%install
mkdir -p %{buildroot}
cp -a usr %{buildroot}/

%files
%{_prefix}/lib/firmware/wcnmodem.bin
%{_prefix}/lib/firmware/wifi_2355b001_1ant.ini
%{_prefix}/lib/firmware/bt_configure_pskey.ini
%{_prefix}/lib/firmware/bt_configure_rf.ini

%changelog
* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 1.0.6-1.lu26
- Package the firmware used by the onboard Zero 3 UWE5622 radio
