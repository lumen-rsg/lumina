%global debug_package %{nil}

Name:           lumina-zero3-boot
Version:        1.0.6
Release:        4.lu26
Summary:        SPL, U-Boot, and boot configuration for Orange Pi Zero 3
License:        GPL-2.0-or-later AND MIT
URL:            https://linux.1t.ru
ExclusiveArch:  aarch64
Source0:        lumina-zero3-boot-assets-%{version}.tar.gz
Source1:        boot.cmd
Source2:        orangepiEnv.txt
Source3:        lumina-zero3-boot-setup

Requires:       coreutils
Requires:       uboot-tools
Requires:       util-linux
Recommends:     kernel-sun50iw9 >= 6.1.31-1.lu26

%description
The exact Orange Pi 1.0.6 SPL/U-Boot image for the Allwinner H618-based
Orange Pi Zero 3, plus Lumina's U-Boot script and boot setup helper. Fresh SD
images place the combined SPL/U-Boot payload at the Allwinner 8 KiB ROM offset.

%prep
%autosetup -n lumina-zero3-boot-assets-%{version}

%build

%install
install -Dpm 0644 \
    usr/lib/linux-u-boot-next-orangepizero3_%{version}_arm64/u-boot-sunxi-with-spl.bin \
    %{buildroot}%{_prefix}/lib/lumina-zero3/u-boot-sunxi-with-spl.bin
install -Dpm 0644 usr/lib/u-boot/orangepi_zero3_defconfig \
    %{buildroot}%{_prefix}/lib/lumina-zero3/orangepi_zero3_defconfig
install -Dpm 0644 usr/lib/u-boot/LICENSE \
    %{buildroot}%{_licensedir}/%{name}/LICENSE
install -Dpm 0644 %{SOURCE1} %{buildroot}/boot/boot.cmd
install -Dpm 0644 %{SOURCE2} %{buildroot}/boot/orangepiEnv.txt
install -Dpm 0755 %{SOURCE3} %{buildroot}%{_sbindir}/lumina-zero3-boot-setup

%post
if [ -x %{_sbindir}/lumina-zero3-boot-setup ]; then
    %{_sbindir}/lumina-zero3-boot-setup --non-interactive || :
fi

%files
%license %{_licensedir}/%{name}/LICENSE
%{_prefix}/lib/lumina-zero3/u-boot-sunxi-with-spl.bin
%{_prefix}/lib/lumina-zero3/orangepi_zero3_defconfig
/boot/boot.cmd
%config(noreplace) /boot/orangepiEnv.txt
%{_sbindir}/lumina-zero3-boot-setup

%changelog
* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 1.0.6-4.lu26
- Enable the H618 Mali GPU overlay and the Fedora SELinux boot path

* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 1.0.6-3.lu26
- Restore simultaneous HDMI and serial boot output

* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 1.0.6-2.lu26
- Make the serial console the reliable first-boot default

* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 1.0.6-1.lu26
- Add the verified Allwinner SPL/U-Boot payload and direct-boot configuration
