%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post /usr/lib/rpm/brp-compress
%global __requires_exclude_from ^/usr/lib/modules/.*$
%global __provides_exclude_from ^/usr/lib/modules/.*$

%global kver 6.1.115-vendor-rk35xx

Name:           kernel-rk35xx-vendor
Version:        6.1.115
Release:        1.lu26
Summary:        Vendor Linux Kernel 6.1.115 for Rockchip RK3588 devices
License:        GPLv2

ExclusiveArch:  aarch64
Source0:        kernel-rk35xx-vendor-6.1.115.tar.gz

Requires:       dracut, kmod, devicetrees-rockchip, opi5x-fw
AutoReqProv:    no

%description
Rockchip Vendor Linux kernel. Excellent hardware support, but lacks Panthor and recent security updates.

%pre
echo -e "\e[1;31m================================================================================\e[0m"
echo -e "\e[1;33m NOTICE: VENDOR KERNEL WARNING\e[0m"
echo -e " While the vendor kernel provides the best support for most hardware,"
echo -e " \e[1;36mlumina Linux team highly encourages you to use the rockchip64 kernel\e[0m"
echo -e " because it has the Panthor GPU driver and countless security patches."
echo -e "\n Please proceed only if you know what you are doing."
echo -e "\e[1;31m================================================================================\e[0m"

%prep
%setup -c -q

%install
mkdir -p %{buildroot}
cp -a boot usr %{buildroot}/

%post
depmod -a %{kver} || :
if[ -x /usr/bin/dracut ]; then
    dracut -f /boot/initrd.img-%{kver} %{kver}
fi
if[ -x /usr/bin/mkimage ]; then
    mkimage -A arm64 -O linux -T ramdisk -C none -n "uInitrd" -d /boot/initrd.img-%{kver} /boot/uInitrd-%{kver} > /dev/null
    ln -sf uInitrd-%{kver} /boot/uInitrd 2>/dev/null || :
fi

%files
/boot/Image
/boot/vmlinuz-%{kver}
/boot/config-%{kver}
/boot/System.map-%{kver}
/boot/dtb/
/usr/lib/modules/%{kver}/