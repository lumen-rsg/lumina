%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}

Name:           nvidia-l4t-multimedia
Version:        39.2.0
Release:        2.lu26
Summary:        NVIDIA L4T camera and multimedia stack for Jetson
License:        LicenseRef-NVIDIA-Driver AND BSD-3-Clause
URL:            https://developer.nvidia.com/embedded/jetson-linux
ExclusiveArch:  aarch64
Source0:        %{name}-%{version}.tar.gz

Requires:       nvidia-l4t-driver = %{version}-%{release}
Requires:       alsa-lib
Requires:       cairo
Requires:       glib2
Requires:       gstreamer1
Requires:       gstreamer1-plugins-base
Requires:       gtk3
Requires:       pango
Requires:       zlib-ng-compat
AutoReqProv:    no

%description
The unmodified NVIDIA camera, Argus, NvSci, PVA, video codec, multimedia, and
accelerated GStreamer userspace for Jetson Linux R39.2.

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
* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 39.2.0-2.lu26
- Rebuild against the corrected NVIDIA L4T driver package

* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 39.2.0-1.lu26
- Initial NVIDIA Jetson Orin package
