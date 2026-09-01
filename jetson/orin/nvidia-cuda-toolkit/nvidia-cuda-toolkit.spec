%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}

Name:           nvidia-cuda-toolkit
Version:        13.2.2
Release:        1.lu26
Summary:        NVIDIA CUDA 13.2 compiler and development tools for Jetson
License:        LicenseRef-NVIDIA-CUDA
URL:            https://developer.nvidia.com/cuda-toolkit
ExclusiveArch:  aarch64
Source0:        %{name}-%{version}.tar.gz

Requires:       nvidia-cuda-runtime = %{version}-%{release}
Requires:       gcc-c++
Requires:       glibc-devel
Requires:       libstdc++ >= 16.2.1
Requires:       libstdc++-devel
Requires:       make
Requires:       python3
AutoReqProv:    no

%description
The NVIDIA CUDA 13.2 command-line development toolkit for Jetson. It includes
nvcc, CUDA headers and static development libraries, cuda-gdb, Compute
Sanitizer, CUPTI, nvdisasm, cuobjdump, nvprune, NVTX, and compiler support.
Large Nsight GUI applications are intentionally kept out of the base image.

%prep
%setup -c -q

%install
mkdir -p %{buildroot}
cp -a . %{buildroot}/
mkdir -p %{buildroot}%{_bindir}
ln -s /usr/local/cuda/bin/nvcc %{buildroot}%{_bindir}/nvcc
find %{buildroot} \( -type f -o -type l \) -printf '/%%P\n' | sort |
    sed '\#^/etc/# s#^#%%config(noreplace) #' > %{_builddir}/%{name}.files

%files -f %{_builddir}/%{name}.files

%changelog
* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 13.2.2-1.lu26
- Package the CUDA 13.2 compiler, headers, libraries, and CLI diagnostics
