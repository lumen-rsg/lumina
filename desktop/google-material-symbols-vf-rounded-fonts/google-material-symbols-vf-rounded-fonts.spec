Name:           google-material-symbols-vf-rounded-fonts
Version:        20260911
Release:        1.lu26
Summary:        Material Symbols Rounded variable icon font
License:        Apache-2.0
URL:            https://fonts.google.com/
BuildArch:      noarch
Requires:       fontconfig
Source0:        https://raw.githubusercontent.com/google/material-design-icons/40a7a292a79d9394157e1ea24f83d52d5e17c556/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf#/MaterialSymbolsRounded.ttf
Source1:        https://raw.githubusercontent.com/google/material-design-icons/40a7a292a79d9394157e1ea24f83d52d5e17c556/LICENSE#/MaterialSymbols-LICENSE

%description
Material Symbols Rounded variable icon font, packaged from pinned upstream sources for Lumina.
This replaces the dotfiles' dependency on the ririko66z/dots-hyprland COPR.

%prep
echo 'f1472f172c0fc4a922be22972e4752ccc54fe795ed82564ab6f6b097782f2dbc  %{SOURCE0}' | sha256sum -c -
echo '58d1e17ffe5109a7ae296caafcadfdbe6a7d176f0bc4ab01e12a689b0499d8bd  %{SOURCE1}' | sha256sum -c -

%build

%install
install -Dpm0644 %{SOURCE0} %{buildroot}%{_datadir}/fonts/google-material-symbols-vf-rounded-fonts/MaterialSymbolsRounded.ttf
install -Dpm0644 %{SOURCE1} %{buildroot}%{_licensedir}/google-material-symbols-vf-rounded-fonts/MaterialSymbols-LICENSE

%files
%license %{_licensedir}/google-material-symbols-vf-rounded-fonts/
%{_datadir}/fonts/google-material-symbols-vf-rounded-fonts/

%changelog
* Fri Sep 11 2026 Lumina Linux <packages@linux.1t.ru> - 20260911-1.lu26
- Package pinned upstream font sources through LuminaCI
