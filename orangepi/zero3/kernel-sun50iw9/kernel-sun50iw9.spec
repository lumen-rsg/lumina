%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}
%global __requires_exclude_from ^/usr/lib/modules/.*$
%global __provides_exclude_from ^/usr/lib/modules/.*$
%global board_version 1.0.6
%global kver 6.1.31-sun50iw9

Name:           kernel-sun50iw9
Version:        6.1.31
Release:        2.lu26
Summary:        Orange Pi vendor kernel for the Allwinner H618
License:        GPL-2.0-only
URL:            https://github.com/orangepi-xunlong/orangepi-build
ExclusiveArch:  aarch64
Source0:        %{name}-%{board_version}.tar.gz

Requires:       dracut
Requires:       kmod
Requires:       orangepi-zero3-firmware = %{board_version}-1.lu26
Recommends:     lumina-zero3-boot >= %{board_version}-3.lu26
Provides:       kernel-uname-r = %{kver}
AutoReqProv:    no

%description
Orange Pi build 1.0.6 Linux 6.1.31 kernel, H616/H618 device trees, and
matching modules for the Allwinner H618-based Orange Pi Zero 3.

%prep
%autosetup -n %{name}-%{board_version}

%build

%install
mkdir -p %{buildroot}
cp -a boot usr %{buildroot}/
find %{buildroot} \( -type f -o -type l \) -printf '/%%P\n' | sort >%{_builddir}/%{name}.files

%post
/usr/sbin/depmod -a %{kver} || :
if [ -x /usr/bin/dracut ]; then
    /usr/bin/dracut --force --no-hostonly --add selinux /boot/initramfs-%{kver}.img %{kver} || :
fi
if [ -x /usr/sbin/lumina-zero3-boot-setup ]; then
    /usr/sbin/lumina-zero3-boot-setup --non-interactive || :
fi

%postun
if [ "$1" -eq 0 ]; then
    /usr/sbin/depmod -a || :
fi

%files -f %{_builddir}/%{name}.files

%changelog
* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 6.1.31-2.lu26
- Generate an initramfs that loads SELinux before the real root

* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 6.1.31-1.lu26
- Package the Orange Pi 1.0.6 H618 kernel, DTBs, and modules
