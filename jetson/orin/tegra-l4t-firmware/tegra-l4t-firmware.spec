%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}

Name:           tegra-l4t-firmware
Version:        39.2.1
Release:        1.lu26
Summary:        NVIDIA L4T firmware for Jetson Orin
License:        LicenseRef-NVIDIA-Driver AND LicenseRef-Various
URL:            https://developer.nvidia.com/embedded/jetson-linux
BuildArch:      noarch
Source0:        %{name}-%{version}.tar.gz

AutoReqProv:    no

%description
Unmodified NVIDIA firmware for the GPU, display, camera, multimedia engines,
and peripheral devices in Jetson Orin systems.

%prep
%setup -c -q

%install
mkdir -p %{buildroot}
cp -a . %{buildroot}/
find %{buildroot} \( -type f -o -type l \) -printf '/%%P\n' | sort > %{_builddir}/%{name}.files

%files -f %{_builddir}/%{name}.files

%changelog
* Tue Sep 01 2026 Lumina Linux <packages@linux.1t.ru> - 39.2.1-1.lu26
- Update NVIDIA firmware to L4T R39.2.1

* Sat Aug 01 2026 Lumina Linux <packages@linux.1t.ru> - 39.2.0-3.lu26
- Validate the coherent Jetson R39.2 set through the native LuminaCI fabric

* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 39.2.0-2.lu26
- Rebuild the coherent Jetson R39.2 package set

* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 39.2.0-1.lu26
- Initial NVIDIA Jetson Orin package
