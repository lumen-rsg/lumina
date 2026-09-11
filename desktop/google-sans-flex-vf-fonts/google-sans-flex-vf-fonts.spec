Name:           google-sans-flex-vf-fonts
Version:        20260911
Release:        1.lu26
Summary:        Google Sans Flex variable typeface
License:        OFL-1.1
URL:            https://fonts.google.com/
BuildArch:      noarch
Requires:       fontconfig
Source0:        https://raw.githubusercontent.com/google/fonts/c23730cd7f3c7f211ab4f5f5b0b1ad9fb6bedb2c/ofl/googlesansflex/GoogleSansFlex%5BGRAD%2CROND%2Copsz%2Cslnt%2Cwdth%2Cwght%5D.ttf#/GoogleSansFlex.ttf
Source1:        https://raw.githubusercontent.com/google/fonts/c23730cd7f3c7f211ab4f5f5b0b1ad9fb6bedb2c/ofl/googlesansflex/OFL.txt#/GoogleSansFlex-OFL.txt

%description
Google Sans Flex variable typeface, packaged from pinned upstream sources for Lumina.
This replaces the dotfiles' dependency on the ririko66z/dots-hyprland COPR.

%prep
echo 'c31a482fbecbf2e07e6890134d20078723aadf732c9b9c6c9a44f86f8265b6fe  %{SOURCE0}' | sha256sum -c -
echo 'fc13d69f63e36d284b6e383d4d1463d8ad404f0aa065e57cf961252d51063137  %{SOURCE1}' | sha256sum -c -

%build

%install
install -Dpm0644 %{SOURCE0} %{buildroot}%{_datadir}/fonts/google-sans-flex-vf-fonts/GoogleSansFlex.ttf
install -Dpm0644 %{SOURCE1} %{buildroot}%{_licensedir}/google-sans-flex-vf-fonts/GoogleSansFlex-OFL.txt

%files
%license %{_licensedir}/google-sans-flex-vf-fonts/
%{_datadir}/fonts/google-sans-flex-vf-fonts/

%changelog
* Fri Sep 11 2026 Lumina Linux <packages@linux.1t.ru> - 20260911-1.lu26
- Package pinned upstream font sources through LuminaCI
