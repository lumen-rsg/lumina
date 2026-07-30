Name:           lumina-jetson-installer
Version:        0.1
Release:        1.lu26
Summary:        Storage preparation for Lumina on NVIDIA Jetson Orin
License:        MIT
URL:            https://github.com/lumen-rsg/lumina
Source0:        lumina-jetson-storage
Source1:        orin.sfdisk.in

BuildArch:      noarch
Requires:       bash
Requires:       coreutils
Requires:       gptfdisk
Requires:       grep
Requires:       sed
Requires:       util-linux

%description
Guarded NVIDIA-compatible partitioning and Anaconda storage generation for
installing 1T Lumina on pre-flashed Jetson Orin systems.

%prep

%build

%install
install -Dpm 0755 %{SOURCE0} \
    %{buildroot}%{_libexecdir}/lumina-jetson-installer/lumina-jetson-storage
install -Dpm 0644 %{SOURCE1} \
    %{buildroot}%{_datadir}/lumina-jetson-installer/orin.sfdisk.in

%files
%{_libexecdir}/lumina-jetson-installer/lumina-jetson-storage
%{_datadir}/lumina-jetson-installer/orin.sfdisk.in

%changelog
* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 0.1-1.lu26
- Add guarded fresh and reuse storage preparation for Jetson Orin
