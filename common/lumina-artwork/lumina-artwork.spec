Name:           lumina-artwork
Version:        26.08
Release:        1.lu26
Summary:        Desktop, installer, and boot artwork for 1T Lumina
License:        LicenseRef-1T-Lumina-Artwork
URL:            https://linux.1t.ru/
BuildArch:      noarch

Source0:        lumina-default.png
Source1:        lumina-logo.svg
Source2:        lumina-logo-white.svg
Source3:        lumina-backgrounds.xml
Source4:        90-lumina-background.gschema.override
Source5:        lumina.plymouth
Source6:        lumina.script

BuildRequires:  librsvg2-tools
Requires:       glib2
Requires:       hicolor-icon-theme
Requires:       plymouth
Requires:       plymouth-plugin-script
Supplements:    gnome-shell

%description
Original 1T Lumina wallpaper and logo artwork, GNOME desktop and lock-screen
defaults, application icon integration, and a Lumina Plymouth boot theme.

%prep

%build
rsvg-convert --width=256 --height=256 %{SOURCE2} \
    --output lumina-logo.png

%install
install -Dpm0644 %{SOURCE0} \
    %{buildroot}%{_datadir}/backgrounds/lumina/lumina-default.png
install -Dpm0644 %{SOURCE1} \
    %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/lumina-logo.svg
install -Dpm0644 %{SOURCE1} \
    %{buildroot}%{_datadir}/pixmaps/lumina-logo.svg
install -Dpm0644 %{SOURCE3} \
    %{buildroot}%{_datadir}/gnome-background-properties/lumina.xml
install -Dpm0644 %{SOURCE4} \
    %{buildroot}%{_datadir}/glib-2.0/schemas/90_lumina-background.gschema.override
install -Dpm0644 %{SOURCE5} \
    %{buildroot}%{_datadir}/plymouth/themes/lumina/lumina.plymouth
install -Dpm0644 %{SOURCE6} \
    %{buildroot}%{_datadir}/plymouth/themes/lumina/lumina.script
install -Dpm0644 lumina-logo.png \
    %{buildroot}%{_datadir}/plymouth/themes/lumina/lumina-logo.png

%posttrans
/usr/sbin/plymouth-set-default-theme lumina >/dev/null 2>&1 || :

%files
%{_datadir}/backgrounds/lumina/
%{_datadir}/glib-2.0/schemas/90_lumina-background.gschema.override
%{_datadir}/gnome-background-properties/lumina.xml
%{_datadir}/icons/hicolor/scalable/apps/lumina-logo.svg
%{_datadir}/pixmaps/lumina-logo.svg
%{_datadir}/plymouth/themes/lumina/

%changelog
* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 26.08-1.lu26
- Add original indigo wallpaper, Lumina icon, GNOME defaults, and boot theme
