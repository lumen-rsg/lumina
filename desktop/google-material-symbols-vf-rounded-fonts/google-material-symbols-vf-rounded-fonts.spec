Name:           google-material-symbols-vf-rounded-fonts
Version:        20260911
Release:        2.lu26
Summary:        Material Symbols Rounded variable icon font
License:        Apache-2.0
URL:            https://fonts.google.com/
BuildArch:      noarch
Requires:       fontconfig

# Recreate with desktop/tools/bundle-fonts.py google-material-symbols-vf-rounded-fonts; pins are in sources.json.
Source0:        %{name}-%{version}.tar.xz
Source1:        sources.json

%description
Material Symbols Rounded variable icon font, packaged from pinned upstream sources for Lumina.
This replaces the dotfiles' dependency on the ririko66z/dots-hyprland COPR.

%prep
echo '44f8854a6d45960f32eb8261a6af1cb076b447e35d0bcdb73139f7037404cf32  %{SOURCE0}' | sha256sum -c -
%setup -q -c
echo 'f1472f172c0fc4a922be22972e4752ccc54fe795ed82564ab6f6b097782f2dbc  MaterialSymbolsRounded.ttf' | sha256sum -c -
echo '58d1e17ffe5109a7ae296caafcadfdbe6a7d176f0bc4ab01e12a689b0499d8bd  MaterialSymbols-LICENSE' | sha256sum -c -

%build

%install
install -Dpm0644 MaterialSymbolsRounded.ttf %{buildroot}%{_datadir}/fonts/google-material-symbols-vf-rounded-fonts/MaterialSymbolsRounded.ttf
install -Dpm0644 MaterialSymbols-LICENSE %{buildroot}%{_licensedir}/google-material-symbols-vf-rounded-fonts/MaterialSymbols-LICENSE

%files
%license %{_licensedir}/google-material-symbols-vf-rounded-fonts/
%{_datadir}/fonts/google-material-symbols-vf-rounded-fonts/

%changelog
* Fri Sep 11 2026 Lumina Linux <packages@linux.1t.ru> - 20260911-2.lu26
- Bundle verified font and license inputs for offline native CI builds

* Fri Sep 11 2026 Lumina Linux <packages@linux.1t.ru> - 20260911-1.lu26
- Package pinned upstream font sources through LuminaCI
