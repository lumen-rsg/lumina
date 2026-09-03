%undefine _hardened_build

Name:           btop
Version:        1.4.7
Release:        3.lu26
Summary:        Modern resource monitor with NVIDIA Jetson GPU support
License:        Apache-2.0 AND ISC AND MIT AND LicenseRef-Fedora-Public-Domain
URL:            https://github.com/aristocratos/btop
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz
Patch0:         btop-1.4.7-tegra-gpu.patch

BuildRequires:  desktop-file-utils
BuildRequires:  gcc
BuildRequires:  gcc-c++
BuildRequires:  lowdown
BuildRequires:  make
Requires:       hicolor-icon-theme

Provides:       bundled(igt-gpu-tools) = 1.28
Provides:       bundled(widecharwidth)

%description
C++ resource monitor for processors, memory, disks, networking, processes, and
GPUs. This Lumina build enables GPU support on aarch64 and reads the Tegra
nvgpu load interface when Jetson's NVML implementation does not expose GPU
utilization.

%prep
%autosetup -p1

%build
export CXXFLAGS="${CXXFLAGS} -g"
%{__make} -j2 GPU_SUPPORT=true INTEL_GPU_SUPPORT=true

%install
%make_install PREFIX=%{_prefix} GPU_SUPPORT=true INTEL_GPU_SUPPORT=true
rm -f %{buildroot}%{_datadir}/btop/README.md
desktop-file-validate %{buildroot}%{_datadir}/applications/btop.desktop

%files
%license LICENSE
%doc README.md CHANGELOG.md
%{_bindir}/btop
%{_datadir}/applications/btop.desktop
%{_datadir}/btop
%{_datadir}/icons/hicolor/*/apps/btop.*
%{_mandir}/man1/btop.1.*

%changelog
* Thu Sep 03 2026 Lumina Linux <packages@linux.1t.ru> - 1.4.7-3.lu26
- Limit compile parallelism for memory-constrained aarch64 builders

* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 1.4.7-2.lu26
- Enable aarch64 GPU monitoring and Tegra nvgpu utilization
