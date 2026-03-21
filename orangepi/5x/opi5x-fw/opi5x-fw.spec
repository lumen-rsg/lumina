%global debug_package %{nil}

Name:           opi5x-fw
Version:        1.0
Release:        1.lu26
Summary:        Complete Firmware for Orange Pi 5 series (including Panthor)
License:        Proprietary
URL:            https://github.com/orangepi-xunlong/firmware
BuildArch:      noarch
Source0:        opi5x-fw-%{version}.tar.gz

%description
Provides all Wi-Fi, Bluetooth, and GPU (Mali Panthor/Panfrost) firmware blobs 
required for the Orange Pi 5 series on Lumina Linux.

%prep
%setup -q

%build
# Nothing to compile

%install
mkdir -p %{buildroot}/lib/firmware
cp -a * %{buildroot}/lib/firmware/
rm -rf %{buildroot}/lib/firmware/.git*

%files
/lib/firmware/*