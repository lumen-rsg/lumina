Name:           neofetch
Version:        7.1.0
Release:        2.lu26
Summary:        Command-line system information tool with 1T Lumina artwork
License:        MIT
URL:            https://github.com/dylanaraps/neofetch
Source0:        %{url}/archive/%{version}/%{name}-%{version}.tar.gz
Patch0:         neofetch-7.1.0-lumina.patch
BuildArch:      noarch

Requires:       bash
Requires:       coreutils
Requires:       pciutils
Requires:       procps-ng

%description
Neofetch displays information about the operating system, software, and
hardware. This Lumina build adds automatic recognition and terminal artwork
for 1T Lumina.

%prep
%autosetup -p1

%build

%install
%make_install PREFIX=%{_prefix}

%files
%license LICENSE.md
%doc README.md
%{_bindir}/neofetch
%{_mandir}/man1/neofetch.1*

%changelog
* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 7.1.0-2.lu26
- Render Lumina artwork in indigo

* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 7.1.0-1.lu26
- Add automatic 1T Lumina identity and artwork
