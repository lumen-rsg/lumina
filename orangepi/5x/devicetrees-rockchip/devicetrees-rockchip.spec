%global debug_package %{nil}

Name:           devicetrees-rockchip
Version:        1.0
Release:        1.lu26
Summary:        Lumina Boot Scripts and Devicetree Configurator
License:        GPLv2
URL:            https://linux.1t.ru
BuildArch:      aarch64

Source0:        boot.cmd
Source1:        lumina-boot-setup.sh

Requires:       uboot-tools, util-linux

%description
Provides the U-Boot execution scripts and the interactive 'lumina-boot-setup' 
tool for selecting RootFS UUIDs and mapping active device trees.

%prep
# None

%build
# None

%install
mkdir -p %{buildroot}/boot
mkdir -p %{buildroot}/usr/sbin

install -m 644 %{SOURCE0} %{buildroot}/boot/boot.cmd
install -m 755 %{SOURCE1} %{buildroot}/usr/sbin/lumina-boot-setup

# Create a blank env file so it is tracked by RPM
touch %{buildroot}/boot/luminaEnv.txt

%post
echo "Run 'sudo lumina-boot-setup' to configure your boot parameters."

%files
/boot/boot.cmd
/usr/sbin/lumina-boot-setup
%ghost /boot/luminaEnv.txt