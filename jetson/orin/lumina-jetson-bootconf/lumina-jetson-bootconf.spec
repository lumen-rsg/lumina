%global debug_package %{nil}

Name:           lumina-jetson-bootconf
Version:        1.0
Release:        4.lu26
Summary:        Lumina boot configuration for NVIDIA Jetson UEFI
License:        MIT
URL:            https://linux.1t.ru
BuildArch:      noarch

Source0:        lumina-jetson-boot-setup

Requires:       coreutils
Requires:       util-linux
Recommends:     lumina-jetson-boot-assets = 39.2.0

%description
Creates an NVIDIA L4T UEFI-compatible extlinux configuration for Lumina while
preserving the pre-existing configuration as a recovery copy.

%prep

%build

%install
install -Dpm 0755 %{SOURCE0} %{buildroot}%{_sbindir}/lumina-jetson-boot-setup

%files
%{_sbindir}/lumina-jetson-boot-setup

%changelog
* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 1.0-4.lu26
- Install the packaged L4TLauncher onto a fresh EFI system partition

* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 1.0-3.lu26
- Preserve NVIDIA framebuffer handoff and ramoops boot parameters

* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 1.0-2.lu26
- Rebuild the coherent Jetson R39.2 package set

* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 1.0-1.lu26
- Initial NVIDIA Jetson Orin package
