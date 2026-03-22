%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post /usr/lib/rpm/brp-compress
%global __requires_exclude_from ^/usr/lib/modules/.*$|/usr/src/.*$
%global __provides_exclude_from ^/usr/lib/modules/.*$|/usr/src/.*$

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

# ==========================================
# DEVEL SUBPACKAGE
# ==========================================
%package devel
Summary:        Development headers for Vendor Kernel %{kver}
Requires:       %{name} = %{version}-%{release}
AutoReqProv:    no

%description devel
Header files and scripts for building third-party kernel modules (like DKMS) 
against the vendor %{kver} kernel.
# ==========================================


%pre
# If installed interactively, halt and ask for permission.
if [ -t 0 ]; then
    exec < /dev/tty
    echo -e "\n\e[1;31m================================================================================\e[0m"
    echo -e "\e[1;33m NOTICE: VENDOR KERNEL WARNING\e[0m"
    echo -e " While the vendor kernel provides the best support for most hardware,"
    echo -e " \e[1;36mLumina Linux team highly encourages you to use the rockchip64 kernel\e[0m"
    echo -e " because it has the Panthor GPU driver and countless security patches."
    echo -e "\n Please proceed only if you know what you are doing."
    echo -e "\e[1;31m================================================================================\e[0m\n"
    while true; do
        read -p " Agree to install vendor kernel? [y/N]: " yn
        case $yn in
            [Yy]* ) echo " Proceeding with installation..."; break;;[Nn]*|"" ) echo -e "\e[1;31m Installation aborted by user.\e[0m"; exit 1;;
            * ) echo " Please answer yes or no.";;
        esac
    done
else
    # Non-interactive fallback (e.g., automated image builder)
    echo "WARNING: Non-interactive install. Proceeding with Vendor Kernel automatically."
fi


%prep
%setup -c -q


%install
mkdir -p %{buildroot}
cp -a boot usr %{buildroot}/

# Safely recreate symlinks for the devel package.
rm -rf %{buildroot}/usr/lib/modules/%{kver}/build
rm -rf %{buildroot}/usr/lib/modules/%{kver}/source
ln -sf /usr/src/linux-headers-%{kver} %{buildroot}/usr/lib/modules/%{kver}/build
ln -sf /usr/src/linux-headers-%{kver} %{buildroot}/usr/lib/modules/%{kver}/source


%post
depmod -a %{kver} || :

if [ -x /usr/bin/dracut ]; then
    dracut -f /boot/initrd.img-%{kver} %{kver}
fi

if [ -x /usr/bin/mkimage ]; then
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
# Exclude the symlinks from the main package
%exclude /usr/lib/modules/%{kver}/build
%exclude /usr/lib/modules/%{kver}/source

%files devel
%defattr(-,root,root,-)
/usr/src/linux-headers-%{kver}*
/usr/lib/modules/%{kver}/build
/usr/lib/modules/%{kver}/source