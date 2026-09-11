%global commit 35ccfe209a808e40d6c2ca60a46cbe4faf68b690
Name:           bibata-cursor-theme
Version:        2.0.7
Release:        1.lu26
Summary:        Bibata Modern Ice cursor artwork for Lumina
License:        GPL-3.0-or-later
URL:            https://github.com/ful1e5/Bibata_Cursor
Source0:        https://github.com/ful1e5/Bibata_Cursor/releases/download/v%{version}/Bibata-Modern-Ice.tar.xz
Source1:        https://github.com/ful1e5/Bibata_Cursor/archive/%{commit}/Bibata_Cursor-%{commit}.tar.gz
BuildArch:      noarch
Requires:       hicolor-icon-theme

%description
Bibata Modern Ice cursor artwork, packaged by LuminaCI. The upstream release
contains architecture-independent Xcursor images. Its corresponding editable
SVG source archive is retained in the source RPM.

%prep
echo 'a68cae60c4dc706350e194ebc91c5fe48bc7bc9d59e119555834a2a7ee5078ef  %{SOURCE0}' | sha256sum -c -
echo 'a7aa077fd573956bc26aa889637164ce84d876df86d34076508a7fb1ef0bec86  %{SOURCE1}' | sha256sum -c -
%setup -q -c -T
tar -xf %{SOURCE0}
tar -xf %{SOURCE1}

%build

%install
mkdir -p %{buildroot}%{_datadir}/icons
cp -a Bibata-Modern-Ice %{buildroot}%{_datadir}/icons/

%files
%license Bibata_Cursor-%{commit}/LICENSE
%{_datadir}/icons/Bibata-Modern-Ice/

%changelog
* Fri Sep 11 2026 Lumina Linux <packages@linux.1t.ru> - 2.0.7-1.lu26
- Move the dotfiles cursor dependency into LuminaCI with pinned source artwork
