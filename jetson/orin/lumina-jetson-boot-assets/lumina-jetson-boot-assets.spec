%global debug_package %{nil}

Name:           lumina-jetson-boot-assets
Version:        39.2.1
Release:        1.lu26
Summary:        NVIDIA L4TLauncher asset for Lumina on Jetson Orin
License:        LicenseRef-NVIDIA-Proprietary
URL:            https://developer.nvidia.com/embedded/jetson-linux
Source0:        %{name}-%{version}.tar.gz

ExclusiveArch:  aarch64

%description
The NVIDIA L4TLauncher EFI binary used by flashed Jetson Orin QSPI/UEFI to
load the root filesystem's extlinux configuration. The source archive is
extracted, without modification, from NVIDIA's matching Jetson Installer ISO.

%prep
%autosetup

%build

%install
install -Dpm 0644 BOOTAA64.efi \
    %{buildroot}%{_prefix}/lib/lumina-jetson/BOOTAA64.efi

%files
%license copyright
%{_prefix}/lib/lumina-jetson/BOOTAA64.efi

%changelog
* Tue Sep 01 2026 Lumina Linux <packages@linux.1t.ru> - 39.2.1-1.lu26
- Package the matching R39.2.1 L4TLauncher

* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 39.2.0-1.lu26
- Package the R39.2 L4TLauncher for fresh Jetson storage installs
