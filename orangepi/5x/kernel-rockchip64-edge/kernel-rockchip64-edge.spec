%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post /usr/lib/rpm/brp-compress
%global __requires_exclude_from ^/usr/lib/modules/.*$
%global __provides_exclude_from ^/usr/lib/modules/.*$

%global kver 7.0.0-rc3-edge-rockchip64

Name:           kernel-rockchip64-edge
Version:        7.0.0
Release:        0.rc3.1.lu26
Summary:        Mainline Linux Kernel 7.0-rc3 for Rockchip64
License:        GPLv2

ExclusiveArch:  aarch64
Source0:        kernel-rockchip64-edge-7.0.0.tar.gz

Requires:       dracut, kmod, devicetrees-rockchip, opi5x-fw
AutoReqProv:    no

%description
Mainline Linux kernel (7.0-rc3) for Rockchip Devices.

%prep
%setup -c -q

%install
mkdir -p %{buildroot}
cp -a boot usr %{buildroot}/

%post
depmod -a %{kver} || :
if [ -x /usr/bin/dracut ]; then
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