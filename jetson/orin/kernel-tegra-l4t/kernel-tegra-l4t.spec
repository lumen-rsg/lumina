%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}
%global __requires_exclude_from ^/usr/lib/modules/.*$
%global __provides_exclude_from ^/usr/lib/modules/.*$
%global kver 6.8.12-1021-tegra

Name:           kernel-tegra-l4t
Version:        39.2.0
Release:        3.lu26
Summary:        NVIDIA L4T kernel for Jetson Orin
License:        GPL-2.0-only AND LicenseRef-NVIDIA-Driver
URL:            https://developer.nvidia.com/embedded/jetson-linux
ExclusiveArch:  aarch64
Source0:        %{name}-%{version}.tar.gz

Requires:       dracut
Requires:       kmod
Requires:       tegra-l4t-firmware = %{version}-%{release}
Recommends:     lumina-jetson-bootconf
AutoReqProv:    no

%description
NVIDIA Jetson Linux R39.2 kernel, device trees, and in-tree and out-of-tree
modules for Tegra234 Jetson Orin systems.

%prep
%setup -c -q

%install
mkdir -p %{buildroot}
cp -a . %{buildroot}/

mv %{buildroot}/boot/Image %{buildroot}/boot/Image-%{kver}
find %{buildroot} \( -type f -o -type l \) -printf '/%%P\n' | sort > %{_builddir}/%{name}.files

%post
/usr/sbin/depmod -a %{kver} || :
if [ -x /usr/bin/dracut ]; then
    /usr/bin/dracut --force /boot/initramfs-%{kver}.img %{kver} || :
fi
if [ -x /usr/sbin/lumina-jetson-boot-setup ]; then
    /usr/sbin/lumina-jetson-boot-setup --non-interactive || :
fi

%postun
if [ "$1" -eq 0 ]; then
    /usr/sbin/depmod -a || :
fi

%files -f %{_builddir}/%{name}.files

%changelog
* Sat Aug 01 2026 Lumina Linux <packages@linux.1t.ru> - 39.2.0-3.lu26
- Validate the coherent Jetson R39.2 set through the native LuminaCI fabric

* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 39.2.0-2.lu26
- Rebuild the coherent Jetson R39.2 package set

* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 39.2.0-1.lu26
- Initial NVIDIA Jetson Orin package
