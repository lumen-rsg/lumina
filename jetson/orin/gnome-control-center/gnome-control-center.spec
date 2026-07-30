%global blueprint_compiler_version 0.17
%global gcr_version 4.1.0
%global gnome_online_accounts_version 3.51.0
%global glib2_version 2.76.6
%global gnome_desktop_version 44.0-7
%global gsd_version 48~rc
%global gsettings_desktop_schemas_version 48~alpha-2
%global upower_version 1.90.6
%global gtk4_version 4.15.2
%global gnome_bluetooth_version 42~alpha
%global libadwaita_version 1.8~alpha
%global nm_version 1.52.0

Name:           gnome-control-center
Version:        50.0
Release:        2.lu26
Summary:        Utilities to configure the GNOME desktop
License:        GPL-2.0-or-later AND CC0-1.0
URL:            https://gitlab.gnome.org/GNOME/gnome-control-center/
Source0:        https://download.gnome.org/sources/%{name}/50/%{name}-%{version}.tar.xz
Patch0:         gnome-control-center-50.0-jetson-details.patch

BuildRequires:  blueprint-compiler >= %{blueprint_compiler_version}
BuildRequires:  desktop-file-utils
BuildRequires:  docbook-style-xsl
BuildRequires:  gcc
BuildRequires:  gettext
BuildRequires:  libxslt
BuildRequires:  meson
BuildRequires:  pkgconfig(accountsservice)
BuildRequires:  pkgconfig(colord)
BuildRequires:  pkgconfig(colord-gtk4)
BuildRequires:  pkgconfig(cups)
BuildRequires:  pkgconfig(gcr-4) >= %{gcr_version}
BuildRequires:  pkgconfig(gdk-pixbuf-2.0)
BuildRequires:  pkgconfig(gdk-wayland-3.0)
BuildRequires:  pkgconfig(gio-2.0) >= %{glib2_version}
BuildRequires:  pkgconfig(gnome-bluetooth-3.0) >= %{gnome_bluetooth_version}
BuildRequires:  pkgconfig(gnome-desktop-4) >= %{gnome_desktop_version}
BuildRequires:  pkgconfig(gnome-settings-daemon) >= %{gsd_version}
BuildRequires:  pkgconfig(goa-1.0) >= %{gnome_online_accounts_version}
BuildRequires:  pkgconfig(goa-backend-1.0)
BuildRequires:  pkgconfig(gsettings-desktop-schemas) >= %{gsettings_desktop_schemas_version}
BuildRequires:  pkgconfig(gsound)
BuildRequires:  pkgconfig(gtk4) >= %{gtk4_version}
BuildRequires:  pkgconfig(gudev-1.0)
BuildRequires:  pkgconfig(ibus-1.0)
BuildRequires:  pkgconfig(libadwaita-1) >= %{libadwaita_version}
BuildRequires:  pkgconfig(libgtop-2.0)
BuildRequires:  pkgconfig(libnm) >= %{nm_version}
BuildRequires:  pkgconfig(libnma-gtk4)
BuildRequires:  pkgconfig(libpulse)
BuildRequires:  pkgconfig(libpulse-mainloop-glib)
BuildRequires:  pkgconfig(libsecret-1)
BuildRequires:  pkgconfig(libsoup-3.0)
BuildRequires:  pkgconfig(libwacom)
BuildRequires:  pkgconfig(libxml-2.0)
BuildRequires:  pkgconfig(mm-glib)
BuildRequires:  pkgconfig(polkit-gobject-1)
BuildRequires:  pkgconfig(pwquality)
BuildRequires:  pkgconfig(smbclient)
BuildRequires:  pkgconfig(tecla)
BuildRequires:  pkgconfig(udisks2)
BuildRequires:  pkgconfig(upower-glib) >= %{upower_version}
BuildRequires:  pkgconfig(x11)
BuildRequires:  pkgconfig(xi)

Requires:       %{name}-filesystem = %{version}-%{release}
Requires:       accountsservice
Requires:       alsa-lib
Requires:       colord
Requires:       cups-pk-helper
Requires:       dbus
Requires:       glib2%{?_isa} >= %{glib2_version}
Requires:       gnome-desktop4%{?_isa} >= %{gnome_desktop_version}
Requires:       gnome-online-accounts%{?_isa} >= %{gnome_online_accounts_version}
Requires:       gnome-settings-daemon%{?_isa} >= %{gsd_version}
Requires:       gsettings-desktop-schemas%{?_isa} >= %{gsettings_desktop_schemas_version}
Requires:       gtk4%{?_isa} >= %{gtk4_version}
Requires:       iso-codes
Requires:       libadwaita%{?_isa} >= %{libadwaita_version}
Requires:       /usr/bin/tecla
Requires:       upower%{?_isa} >= %{upower_version}
Recommends:     bolt
Recommends:     gnome-bluetooth%{?_isa} >= 1:%{gnome_bluetooth_version}
Recommends:     gnome-color-manager
Recommends:     gnome-remote-desktop
Recommends:     NetworkManager-wifi
Recommends:     nm-connection-editor
Recommends:     rygel
Recommends:     switcheroo-control
Suggests:       tuned-ppd

Provides:       control-center = 1:%{version}-%{release}
Provides:       control-center%{?_isa} = 1:%{version}-%{release}
Obsoletes:      control-center < 1:%{version}-%{release}

%description
GNOME desktop configuration utilities. This Lumina build adds robust hardware
reporting for NVIDIA Jetson platform GPUs, ARM Cortex-A78AE processors, and
NVMe drives whose controllers do not expose an aggregate capacity.

%package filesystem
Summary:        GNOME Control Center directories
BuildArch:      noarch
Provides:       control-center-filesystem = 1:%{version}-%{release}
Obsoletes:      control-center-filesystem < 1:%{version}-%{release}

%description filesystem
Directories used as GNOME Control Center extension points.

%prep
%autosetup -p1

%build
%meson \
  -Ddocumentation=true \
  -Dlocation-services=enabled \
  -Ddistributor_logo=%{_datadir}/pixmaps/fedora_logo_med.png \
  -Ddark_mode_distributor_logo=%{_datadir}/pixmaps/fedora_whitelogo_med.png \
  -Dmalcontent=false
%meson_build

%install
%meson_install
mkdir -p %{buildroot}%{_datadir}/gnome/wm-properties
rm -rf %{buildroot}%{_datadir}/gnome/autostart
rm -rf %{buildroot}%{_datadir}/gnome/cursor-fonts
%find_lang %{name} --all-name --with-gnome

%files -f %{name}.lang
%license COPYING
%doc NEWS README.md
%{_bindir}/gnome-control-center
%{_datadir}/applications/*.desktop
%{_datadir}/bash-completion/completions/gnome-control-center
%{_datadir}/dbus-1/services/org.gnome.Settings.SearchProvider.service
%{_datadir}/dbus-1/services/org.gnome.Settings.service
%{_datadir}/dbus-1/services/org.gnome.Settings.GlobalShortcutsProvider.service
%{_datadir}/dbus-1/interfaces/org.gnome.GlobalShortcutsRebind.xml
%{_datadir}/gettext/
%{_datadir}/glib-2.0/schemas/org.gnome.Settings.gschema.xml
%{_datadir}/gnome-control-center/keybindings/*.xml
%{_datadir}/gnome-control-center/pixmaps
%{_datadir}/gnome-shell/search-providers/org.gnome.Settings.search-provider.ini
%{_datadir}/icons/gnome-logo-text*.svg
%{_datadir}/icons/hicolor/*/*/*
%{_mandir}/man1/gnome-control-center.1*
%{_metainfodir}/org.gnome.Settings.metainfo.xml
%{_datadir}/pixmaps/faces
%{_datadir}/pkgconfig/gnome-keybindings.pc
%{_datadir}/polkit-1/actions/org.gnome.controlcenter.*.policy
%{_datadir}/polkit-1/rules.d/gnome-control-center.rules
%{_datadir}/sounds/gnome/default/*/*.ogg
%{_libexecdir}/gnome-control-center-search-provider
%{_libexecdir}/gnome-control-center-print-renderer
%{_libexecdir}/gnome-control-center-global-shortcuts-provider

%files filesystem
%dir %{_datadir}/gnome-control-center
%dir %{_datadir}/gnome-control-center/keybindings
%dir %{_datadir}/gnome/wm-properties

%changelog
* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 50.0-2.lu26
- Report Jetson GPU, Cortex-A78AE CPU, and NVMe namespace capacity
