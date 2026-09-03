%global fedora_version 44

Name:           lumina-release
Epoch:          2
Version:        26.08
Release:        5.lu26
Summary:        1T Lumina release identity and defaults
License:        MIT AND LicenseRef-1T-Lumina-Logo
URL:            https://linux.1t.ru/
BuildArch:      noarch

Source0:        os-release
Source1:        lumina-release
Source2:        system-release-cpe
Source3:        issue
Source4:        issue.net
Source5:        macros.dist
Source6:        20-lumina-defaults.conf
Source7:        lumina-workstation.conf
Source8:        fastfetch.jsonc
Source9:        logo.txt
Source10:       update-boot-branding
Source11:       85-display-manager.preset
Source12:       90-default.preset
Source13:       90-default-user.preset
Source14:       99-default-disable.preset
Source15:       80-workstation.preset
Source16:       81-desktop.preset
Source17:       90-lumina-repositories.repo
Source18:       RPM-GPG-KEY-lumina-2026

Requires:       fedora-repos(%{fedora_version})
Requires:       bash
Requires:       coreutils
Requires:       grep
Requires:       sed

Provides:       fedora-release = 1:%{fedora_version}-%{release}
Provides:       fedora-release-common = 1:%{fedora_version}-%{release}
Provides:       fedora-release-identity = 1:%{fedora_version}-%{release}
Provides:       fedora-release-identity-basic = 1:%{fedora_version}-%{release}
Provides:       fedora-release-identity-container = 1:%{fedora_version}-%{release}
Provides:       fedora-release-identity-server = 1:%{fedora_version}-%{release}
Provides:       fedora-release-identity-workstation = 1:%{fedora_version}-%{release}
Provides:       fedora-release-variant = 1:%{fedora_version}-%{release}
Provides:       fedora-release-container = 1:%{fedora_version}-%{release}
Provides:       fedora-release-server = 1:%{fedora_version}-%{release}
Provides:       fedora-release-workstation = 1:%{fedora_version}-%{release}
Provides:       generic-release = %{epoch}:%{version}-%{release}
Provides:       redhat-release = %{epoch}:%{version}-%{release}
Provides:       system-release = %{epoch}:%{version}-%{release}
Provides:       system-release(%{version})
Provides:       system-release(%{fedora_version})
Provides:       system-release(releasever) = %{fedora_version}
Provides:       rpm_macro(dist)
Provides:       rpm_macro(dist_bug_report_url)
Provides:       rpm_macro(dist_home_url)
Provides:       rpm_macro(dist_name)
Provides:       rpm_macro(dist_packages_url)
Provides:       rpm_macro(dist_purl_namespace)
Provides:       rpm_macro(dist_vendor)
Provides:       rpm_macro(fc44)
Provides:       rpm_macro(fedora)
Provides:       rpm_macro(lu26)
Provides:       rpm_macro(lu2608)
Provides:       rpm_macro(lumina)
Provides:       rpm_macro(lumina_version)

Obsoletes:      fedora-release < 1:45
Obsoletes:      fedora-release-common < 1:45
Obsoletes:      fedora-release-identity-basic < 1:45
Obsoletes:      fedora-release-identity-container < 1:45
Obsoletes:      fedora-release-identity-server < 1:45
Obsoletes:      fedora-release-identity-workstation < 1:45
Obsoletes:      fedora-release-container < 1:45
Obsoletes:      fedora-release-server < 1:45
Obsoletes:      fedora-release-workstation < 1:45
Obsoletes:      generic-release < 1:45

%description
Release metadata, compatibility links, RPM macros, Fedora-derived service
presets, terminal artwork, and boot-loader branding for 1T Lumina.

%prep

%build

%install
install -Dpm0644 %{SOURCE0} %{buildroot}%{_prefix}/lib/os-release
install -Dpm0644 %{SOURCE1} %{buildroot}%{_prefix}/lib/lumina-release
install -Dpm0644 %{SOURCE2} %{buildroot}%{_prefix}/lib/system-release-cpe
install -Dpm0644 %{SOURCE3} %{buildroot}%{_prefix}/lib/issue
install -Dpm0644 %{SOURCE4} %{buildroot}%{_prefix}/lib/issue.net
install -Dpm0644 %{SOURCE5} %{buildroot}%{_prefix}/lib/rpm/macros.d/macros.dist
install -Dpm0644 %{SOURCE6} %{buildroot}%{_datadir}/dnf5/libdnf.conf.d/20-lumina-defaults.conf
install -Dpm0644 %{SOURCE7} %{buildroot}%{_sysconfdir}/dnf/protected.d/fedora-workstation.conf
install -Dpm0644 %{SOURCE8} %{buildroot}%{_sysconfdir}/xdg/fastfetch/config.jsonc
install -Dpm0644 %{SOURCE9} %{buildroot}%{_datadir}/lumina/logo.txt
install -Dpm0755 %{SOURCE10} %{buildroot}%{_libexecdir}/lumina-release/update-boot-branding

install -Dpm0644 %{SOURCE11} %{buildroot}%{_prefix}/lib/systemd/system-preset/85-display-manager.preset
install -Dpm0644 %{SOURCE12} %{buildroot}%{_prefix}/lib/systemd/system-preset/90-default.preset
install -Dpm0644 %{SOURCE13} %{buildroot}%{_prefix}/lib/systemd/user-preset/90-default-user.preset
install -Dpm0644 %{SOURCE14} %{buildroot}%{_prefix}/lib/systemd/system-preset/99-default-disable.preset
install -Dpm0644 %{SOURCE14} %{buildroot}%{_prefix}/lib/systemd/user-preset/99-default-disable.preset
install -Dpm0644 %{SOURCE15} %{buildroot}%{_prefix}/lib/systemd/system-preset/80-workstation.preset
install -Dpm0644 %{SOURCE16} %{buildroot}%{_prefix}/lib/systemd/system-preset/81-desktop.preset
install -Dpm0644 %{SOURCE17} %{buildroot}%{_datadir}/dnf5/repos.override.d/90-lumina-repositories.repo
install -Dpm0644 %{SOURCE18} %{buildroot}%{_sysconfdir}/pki/rpm-gpg/RPM-GPG-KEY-lumina-2026

ln -s ../usr/lib/os-release %{buildroot}%{_sysconfdir}/os-release
ln -s ../usr/lib/lumina-release %{buildroot}%{_sysconfdir}/lumina-release
ln -s ../usr/lib/lumina-release %{buildroot}%{_sysconfdir}/fedora-release
ln -s lumina-release %{buildroot}%{_sysconfdir}/redhat-release
ln -s lumina-release %{buildroot}%{_sysconfdir}/system-release
ln -s ../usr/lib/system-release-cpe %{buildroot}%{_sysconfdir}/system-release-cpe
ln -s ../usr/lib/issue %{buildroot}%{_sysconfdir}/issue
ln -s ../usr/lib/issue.net %{buildroot}%{_sysconfdir}/issue.net
ln -s lumina-release %{buildroot}%{_prefix}/lib/fedora-release
ln -s lumina-release %{buildroot}%{_prefix}/lib/system-release

%posttrans
%{_libexecdir}/lumina-release/update-boot-branding || :

%transfiletriggerin -P 2000000 -- %{_sysconfdir}/default/grub
%{_libexecdir}/lumina-release/update-boot-branding || :

%files
%{_sysconfdir}/fedora-release
%{_sysconfdir}/issue
%{_sysconfdir}/issue.net
%{_sysconfdir}/lumina-release
%{_sysconfdir}/os-release
%{_sysconfdir}/pki/rpm-gpg/RPM-GPG-KEY-lumina-2026
%{_sysconfdir}/redhat-release
%{_sysconfdir}/system-release
%{_sysconfdir}/system-release-cpe
%config(noreplace) %{_sysconfdir}/dnf/protected.d/fedora-workstation.conf
%config(noreplace) %{_sysconfdir}/xdg/fastfetch/config.jsonc
%{_prefix}/lib/fedora-release
%{_prefix}/lib/issue
%{_prefix}/lib/issue.net
%{_prefix}/lib/lumina-release
%{_prefix}/lib/os-release
%{_prefix}/lib/rpm/macros.d/macros.dist
%{_prefix}/lib/system-release
%{_prefix}/lib/system-release-cpe
%{_prefix}/lib/systemd/system-preset/80-workstation.preset
%{_prefix}/lib/systemd/system-preset/81-desktop.preset
%{_prefix}/lib/systemd/system-preset/85-display-manager.preset
%{_prefix}/lib/systemd/system-preset/90-default.preset
%{_prefix}/lib/systemd/system-preset/99-default-disable.preset
%{_prefix}/lib/systemd/user-preset/90-default-user.preset
%{_prefix}/lib/systemd/user-preset/99-default-disable.preset
%{_datadir}/dnf5/libdnf.conf.d/20-lumina-defaults.conf
%{_datadir}/dnf5/repos.override.d/90-lumina-repositories.repo
%{_datadir}/lumina/logo.txt
%{_libexecdir}/lumina-release/update-boot-branding

%changelog
* Thu Sep 03 2026 Lumina Linux <packages@linux.1t.ru> - 2:26.08-5.lu26
- Install the Lumina 2026 RPM repository signing key

* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 2:26.08-4.lu26
- Disable the geographically unreliable Cisco OpenH264 repository by default

* Fri Jul 31 2026 Lumina Linux <packages@linux.1t.ru> - 2:26.08-3.lu26
- Rebuild through the immutable Kubernetes package pipeline

* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 2:26.08-2.lu26
- Preserve the Fedora 44 system-release capability

* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 2:26.08-1.lu26
- Establish the 1T Lumina distribution identity
