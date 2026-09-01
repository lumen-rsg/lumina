%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}

Name:           nvidia-cuda-runtime
Version:        13.2.2
Release:        1.lu26
Summary:        NVIDIA CUDA 13.2 runtime libraries for Jetson
License:        LicenseRef-NVIDIA-CUDA
URL:            https://developer.nvidia.com/cuda-toolkit
ExclusiveArch:  aarch64
Source0:        %{name}-%{version}.tar.gz

Requires:       nvidia-l4t-driver >= 39.2.1
Requires:       glibc
Requires:       libgcc
Requires:       libstdc++
Requires:       systemd-libs
AutoReqProv:    no

%description
The NVIDIA CUDA 13.2 runtime for Jetson, including CUDA Runtime, NVRTC,
cuBLAS, cuFFT, cuFile, cuDLA, cuRAND, cuSOLVER, cuSPARSE, NPP, nvJitLink,
nvFatbin, and nvJPEG. The payload comes from NVIDIA's public R39.2 Jetson
repository and is installed without binary rewriting.

%prep
%setup -c -q

%install
mkdir -p %{buildroot}
cp -a . %{buildroot}/
find %{buildroot} \( -type f -o -type l \) -printf '/%%P\n' | sort |
    sed '\#^/etc/# s#^#%%config(noreplace) #' > %{_builddir}/%{name}.files

%post
/usr/sbin/ldconfig

%postun
/usr/sbin/ldconfig

%files -f %{_builddir}/%{name}.files

%changelog
* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 13.2.2-1.lu26
- Package the CUDA 13.2 Jetson runtime and accelerated math libraries
