Name:           google-sans-flex-vf-fonts
Version:        20260911
Release:        2.lu26
Summary:        Google Sans Flex variable typeface
License:        OFL-1.1
URL:            https://fonts.google.com/
BuildArch:      noarch
Requires:       fontconfig

# Recreate with desktop/tools/bundle-fonts.py google-sans-flex-vf-fonts; pins are in sources.json.
Source0:        %{name}-%{version}.tar.xz
Source1:        sources.json

%description
Google Sans Flex variable typeface, packaged from pinned upstream sources for Lumina.
This replaces the dotfiles' dependency on the ririko66z/dots-hyprland COPR.

%prep
echo 'a85d63163772b46947c3a982d1e82a2379a377b2e19ba5f46da7a94f3d4ffcf0  %{SOURCE0}' | sha256sum -c -
%setup -q -c
echo 'c31a482fbecbf2e07e6890134d20078723aadf732c9b9c6c9a44f86f8265b6fe  GoogleSansFlex.ttf' | sha256sum -c -
echo 'fc13d69f63e36d284b6e383d4d1463d8ad404f0aa065e57cf961252d51063137  GoogleSansFlex-OFL.txt' | sha256sum -c -

%build

%install
install -Dpm0644 GoogleSansFlex.ttf %{buildroot}%{_datadir}/fonts/google-sans-flex-vf-fonts/GoogleSansFlex.ttf
install -Dpm0644 GoogleSansFlex-OFL.txt %{buildroot}%{_licensedir}/google-sans-flex-vf-fonts/GoogleSansFlex-OFL.txt

%files
%license %{_licensedir}/google-sans-flex-vf-fonts/
%{_datadir}/fonts/google-sans-flex-vf-fonts/

%changelog
* Fri Sep 11 2026 Lumina Linux <packages@linux.1t.ru> - 20260911-2.lu26
- Bundle verified font and license inputs for offline native CI builds

* Fri Sep 11 2026 Lumina Linux <packages@linux.1t.ru> - 20260911-1.lu26
- Package pinned upstream font sources through LuminaCI
