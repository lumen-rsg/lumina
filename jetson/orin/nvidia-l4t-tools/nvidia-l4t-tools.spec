%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}

Name:           nvidia-l4t-tools
Version:        39.2.1
Release:        1.lu26
Summary:        NVIDIA platform tools for Jetson
License:        LicenseRef-NVIDIA-Driver AND BSD-3-Clause
URL:            https://developer.nvidia.com/embedded/jetson-linux
ExclusiveArch:  aarch64
Source0:        %{name}-%{version}.tar.gz

Requires:       nvidia-l4t-driver = %{version}-%{release}
Requires:       dtc
Requires:       i2c-tools
Requires:       python3
Requires:       util-linux
AutoReqProv:    no

%description
NVIDIA Jetson platform tools including tegrastats, nvpmodel, fan control,
Jetson-IO, and OP-TEE integration.

%prep
%setup -c -q

%install
mkdir -p %{buildroot}
cp -a . %{buildroot}/
find %{buildroot} \( -type f -o -type l \) -printf '/%%P\n' | sort |
    sed '\#^/etc/# s#^#%%config(noreplace) #' > %{_builddir}/%{name}.files

%post
/usr/sbin/ldconfig
/usr/bin/systemctl daemon-reload >/dev/null 2>&1 || :
/usr/bin/udevadm control --reload >/dev/null 2>&1 || :

%postun
/usr/sbin/ldconfig
/usr/bin/systemctl daemon-reload >/dev/null 2>&1 || :

%files -f %{_builddir}/%{name}.files

%changelog
* Tue Sep 01 2026 Lumina Linux <packages@linux.1t.ru> - 39.2.1-1.lu26
- Update NVIDIA platform tools to L4T R39.2.1

* Sat Aug 01 2026 Lumina Linux <packages@linux.1t.ru> - 39.2.0-4.lu26
- Validate the coherent Jetson R39.2 set through the native LuminaCI fabric

* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 39.2.0-3.lu26
- Allow compatible NVIDIA L4T driver package revisions

* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 39.2.0-2.lu26
- Rebuild against the corrected NVIDIA L4T driver package

* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 39.2.0-1.lu26
- Initial NVIDIA Jetson Orin package
