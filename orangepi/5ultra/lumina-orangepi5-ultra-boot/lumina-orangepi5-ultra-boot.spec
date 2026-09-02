%global debug_package %{nil}
%global uboot_version 2026.07
%global rkbin_commit 3e288fe814e059dd06833495f845cab04ac20a5c
%global ddr_version 1.24

Name:           lumina-orangepi5-ultra-boot
Version:        %{uboot_version}
Release:        4.lu26
Summary:        Upstream U-Boot and boot configuration for Orange Pi 5 Ultra
License:        GPL-2.0-or-later AND MIT AND LicenseRef-Rockchip-Binary-Only
URL:            https://www.u-boot.org/
ExclusiveArch:  aarch64

Source0:        https://ftp.denx.de/pub/u-boot/u-boot-%{uboot_version}.tar.bz2
Source1:        rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v%{ddr_version}.bin
Source2:        extlinux.conf.in
Source3:        lumina-orangepi5-ultra-boot-setup
Source4:        lumina-orangepi5-ultra-dtb-setup
Source5:        95-lumina-orangepi5-ultra.install
Source6:        lumina-orangepi5-ultra-kernel-setup

BuildRequires:  arm-trusted-firmware-armv8
BuildRequires:  bc
BuildRequires:  bison
BuildRequires:  dtc
BuildRequires:  flex
BuildRequires:  gcc
BuildRequires:  gnutls-devel
BuildRequires:  make
BuildRequires:  openssl-devel
BuildRequires:  openssl-devel-engine
BuildRequires:  perl
BuildRequires:  python3-devel
BuildRequires:  python3-pyelftools
BuildRequires:  python3-setuptools
BuildRequires:  swig

Requires:       coreutils
Requires:       dtc
Requires:       sed
Requires:       util-linux
Requires:       kernel-core >= 6.18
Requires:       zstd
Recommends:     orangepi5-ultra-firmware
Provides:       bundled(rockchip-rkbin) = %{rkbin_commit}

%description
U-Boot %{uboot_version}, built from the upstream U-Boot source for the
Orange Pi 5 Ultra, and Lumina's extlinux configuration. The only binary-only
boot component is Rockchip's DDR training payload; BL31 comes from Fedora's
open-source Trusted Firmware-A build.

The package also generates a versioned DTB with the AP6611 SDIO wiring until
that wiring is part of the upstream Orange Pi 5 Ultra device tree. This works
with distribution DTBs that omit overlay symbols. Installing the RPM never
writes a disk boot sector.

%prep
%autosetup -n u-boot-%{uboot_version}

%build
make orangepi-5-ultra-rk3588_defconfig
make %{?_smp_mflags} \
    BL31=/usr/share/arm-trusted-firmware/rk3588/bl31.elf \
    ROCKCHIP_TPL=%{SOURCE1}

%install
install -Dpm 0644 u-boot-rockchip.bin \
    %{buildroot}%{_prefix}/lib/lumina-orangepi5-ultra/u-boot-rockchip.bin
install -Dpm 0644 %{SOURCE2} \
    %{buildroot}%{_prefix}/lib/lumina-orangepi5-ultra/extlinux.conf.in
install -Dpm 0755 %{SOURCE3} \
    %{buildroot}%{_sbindir}/lumina-orangepi5-ultra-boot-setup
install -Dpm 0755 %{SOURCE4} \
    %{buildroot}%{_libexecdir}/lumina-orangepi5-ultra-dtb-setup
install -Dpm 0755 %{SOURCE5} \
    %{buildroot}%{_prefix}/lib/kernel/install.d/95-lumina-orangepi5-ultra.install
install -Dpm 0755 %{SOURCE6} \
    %{buildroot}%{_libexecdir}/lumina-orangepi5-ultra-kernel-setup

%post
if [ -x %{_sbindir}/lumina-orangepi5-ultra-boot-setup ]; then
    %{_sbindir}/lumina-orangepi5-ultra-boot-setup || :
fi

%files
%{_prefix}/lib/lumina-orangepi5-ultra/u-boot-rockchip.bin
%{_prefix}/lib/lumina-orangepi5-ultra/extlinux.conf.in
%{_prefix}/lib/kernel/install.d/95-lumina-orangepi5-ultra.install
%{_sbindir}/lumina-orangepi5-ultra-boot-setup
%{_libexecdir}/lumina-orangepi5-ultra-dtb-setup
%{_libexecdir}/lumina-orangepi5-ultra-kernel-setup

%changelog
* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 2026.07-4.lu26
- Correct the AP6611 SDIO mux 0 cells and validate its GPIO2 wiring

* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 2026.07-3.lu26
- Route the onboard AP6611 through the Orange Pi 5 Ultra SDIO mux 0 pins

* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 2026.07-2.lu26
- Extract Fedora EFI-zboot kernels into ARM64 Images for U-Boot extlinux

* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 2026.07-1.lu26
- Build the Orange Pi 5 Ultra bootloader from upstream U-Boot
- Use Fedora Trusted Firmware-A and a pinned Rockchip DDR training payload
- Add extlinux and deterministic AP6611 mainline device-tree generation
