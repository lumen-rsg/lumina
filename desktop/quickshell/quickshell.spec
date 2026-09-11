%global commit 2d3b3e9c70ef380dff751b61d334dc88df016c29
# Native CI workers have 2 CPUs and 4 GiB; RPM otherwise counts host CPUs.
%global _smp_ncpus_max 2
Name:           quickshell
Version:        0.3.1^20260911git2d3b3e9
Release:        2.lu26
Summary:        QtQuick desktop shell toolkit for Lumina
License:        LGPL-3.0-only AND GPL-3.0-only
URL:            https://github.com/quickshell-mirror/quickshell
Source0:        https://github.com/quickshell-mirror/quickshell/archive/%{commit}/quickshell-%{commit}.tar.gz
Patch0:         0001-wait-for-popup-polish-in-test.patch
ExclusiveArch:  aarch64 x86_64
BuildRequires:  gcc-c++
BuildRequires:  cmake
BuildRequires:  ninja-build
BuildRequires:  cmake(Qt6Core)
BuildRequires:  cmake(Qt6Qml)
BuildRequires:  cmake(Qt6Quick)
BuildRequires:  cmake(Qt6ShaderTools)
BuildRequires:  cmake(Qt6WaylandClient)
BuildRequires:  qt6-qtbase-private-devel
BuildRequires:  qt6-qtdeclarative-private-devel
BuildRequires:  cmake(CLI11)
BuildRequires:  pkgconfig(gbm)
BuildRequires:  pkgconfig(glib-2.0)
BuildRequires:  pkgconfig(jemalloc)
BuildRequires:  pkgconfig(libdrm)
BuildRequires:  pkgconfig(libpipewire-0.3)
BuildRequires:  pkgconfig(pam)
BuildRequires:  pkgconfig(polkit-agent-1)
BuildRequires:  pkgconfig(wayland-client)
BuildRequires:  pkgconfig(wayland-protocols)
BuildRequires:  pkgconfig(xcb)
BuildRequires:  spirv-tools
BuildRequires:  xorg-x11-server-Xvfb
BuildRequires:  xorg-x11-xauth
Requires:       qt6-qtsvg
Requires:       qt6-qtbase%{?_isa} = %{_qt6_evr}
# Quickshell uses private Qt ABI; Fedora's automatic private-API dependency
# generator and the versioned Qt libraries must both be preserved.
Provides:       quickshell-git = %{version}-%{release}
Obsoletes:      quickshell-git < %{version}-%{release}

%description
Pinned Quickshell source rebuilt natively in LuminaCI against Fedora's Qt.
The Lumina build enables Wayland, layer shell, sockets, capture and desktop
services. Hyprland integrations and the optional cpptrace crash reporter are
disabled; regular system coredump reporting remains available.

%prep
echo '794f7c190ffb3d0b885169be459caf4b787ef07ff9faf3f9e144087fe9cbfffb  %{SOURCE0}' | sha256sum -c -
%autosetup -p1 -n quickshell-%{commit}

%build
%cmake -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DDISTRIBUTOR="LuminaCI Cassiopeia" \
    -DGIT_REVISION=%{commit} \
    -DINSTALL_QML_PREFIX=%{_lib}/qt6/qml \
    -DCRASH_HANDLER=OFF \
    -DHYPRLAND=OFF \
    -DSCREENCOPY_HYPRLAND_TOPLEVEL=OFF \
    -DBUILD_TESTING=ON \
    -DCMAKE_AUTOGEN_PARALLEL=2
%cmake_build

%install
%cmake_install

%check
QT_QPA_PLATFORM=xcb xvfb-run -a ctest --test-dir %{__cmake_builddir} --output-on-failure -j%{_smp_build_ncpus}

%files
%license LICENSE LICENSE-GPL
%doc README.md BUILD.md
%{_bindir}/qs
%{_bindir}/quickshell
%{_datadir}/applications/org.quickshell.desktop
%{_datadir}/icons/hicolor/scalable/apps/org.quickshell.svg
%{_libdir}/qt6/qml/Quickshell/

%changelog
* Fri Sep 11 2026 Lumina Linux <packages@linux.1t.ru> - 0.3.1^20260911git2d3b3e9-2.lu26
- Bound compiler and Qt code-generation parallelism for native CI workers

* Fri Sep 11 2026 Lumina Linux <packages@linux.1t.ru> - 0.3.1^20260911git2d3b3e9-1.lu26
- Move the dotfiles toolkit build into LuminaCI with native Qt ABI matching
