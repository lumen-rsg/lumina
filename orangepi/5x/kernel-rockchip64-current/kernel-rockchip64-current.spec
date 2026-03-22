%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post /usr/lib/rpm/brp-compress
%global __requires_exclude_from ^/usr/lib/modules/.*$|/usr/src/.*$
%global __provides_exclude_from ^/usr/lib/modules/.*$|/usr/src/.*$

%global kver 6.18.19-current-rockchip64

Name:           kernel-rockchip64-current
Version:        6.18.19
Release:        1.lu26
Summary:        Linux kernel for Rockchip64
License:        GPLv2

ExclusiveArch:  aarch64
Source0:        kernel-rockchip64-current-6.18.19.tar.gz

Requires:       dracut, kmod, lumina-bootconf, opi5x-fw
AutoReqProv:    no

%description
Linux kernel for Rockchip Devices.

# ==========================================
# DEVEL SUBPACKAGE
# ==========================================
%package devel
Summary:        Development headers for Kernel %{kver}
Requires:       %{name} = %{version}-%{release}
AutoReqProv:    no

%description devel
Header files and scripts for building third-party kernel modules (like DKMS) 
against the %{kver} kernel.
# ==========================================

%prep
%setup -c -q

%install
mkdir -p %{buildroot}
cp -a boot usr %{buildroot}/

# Safely recreate symlinks for the devel package.
# (This happens in /usr/lib which is ext4, so symlinks are perfectly safe here)
rm -rf %{buildroot}/usr/lib/modules/%{kver}/build
rm -rf %{buildroot}/usr/lib/modules/%{kver}/source
ln -sf /usr/src/linux-headers-%{kver} %{buildroot}/usr/lib/modules/%{kver}/build
ln -sf /usr/src/linux-headers-%{kver} %{buildroot}/usr/lib/modules/%{kver}/source


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
%defattr(-,root,root,-)
/boot/Image
/boot/vmlinuz-%{kver}
/boot/config-%{kver}
/boot/System.map-%{kver}
/boot/dtb/
/usr/lib/modules/%{kver}/
# We must exclude the symlinks from the main package so they go into devel
%exclude /usr/lib/modules/%{kver}/build
%exclude /usr/lib/modules/%{kver}/source

%files devel
%defattr(-,root,root,-)
# The wildcard handles the folder gracefully whether it ends with a slash or not
/usr/src/linux-headers-%{kver}*
/usr/lib/modules/%{kver}/build
/usr/lib/modules/%{kver}/source