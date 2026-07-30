%global debug_package %{nil}
%global _build_id_links none
# NVIDIA's redistribution terms require the proprietary binaries to remain
# unmodified. Disable stripping, build-id rewriting, and all other BRP passes.
%global __os_install_post %{nil}

Name:           nvidia-l4t-driver
Version:        39.2.0
Release:        2.lu26
Summary:        NVIDIA L4T GPU and CUDA driver for Jetson
License:        LicenseRef-NVIDIA-Driver AND BSD-3-Clause
URL:            https://developer.nvidia.com/embedded/jetson-linux
ExclusiveArch:  aarch64
Source0:        %{name}-%{version}.tar.gz

Requires:       kernel-tegra-l4t = %{version}-%{release}
Requires:       tegra-l4t-firmware = %{version}-%{release}
Requires:       glibc
Requires:       libgcc
Requires:       libstdc++
Requires:       libglvnd-egl
Requires:       libglvnd-gles
Requires:       libX11
Requires:       libXext
Requires:       libxcb
Requires:       libdrm
Requires:       libwayland-client
AutoReqProv:    no

%description
The unmodified NVIDIA Jetson Linux R39.2 GPU userspace: OpenRM and nvgpu CUDA
drivers, EGL/OpenGL/Vulkan integration, NVML, and NVIDIA initialization
services.

%prep
%setup -c -q

%install
mkdir -p %{buildroot}
cp -a . %{buildroot}/
# Fedora's alsa-lib owns the global configuration. Keep NVIDIA's named Tegra
# templates without replacing the system-wide default selected by PipeWire.
rm -f %{buildroot}%{_sysconfdir}/asound.conf
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
- Avoid conflicting with alsa-lib's global /etc/asound.conf

* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 39.2.0-1.lu26
- Initial NVIDIA Jetson Orin package
