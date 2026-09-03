Name:           jetson-stats
Version:        7.2.0
Release:        2.lu26
Summary:        Interactive NVIDIA Jetson monitoring and control utility
License:        AGPL-3.0-or-later
URL:            https://github.com/rbonghi/jetson_stats
Source0:        %{url}/archive/refs/tags/%{version}/%{name}-%{version}.tar.gz
Source1:        jtop.service
Source2:        86-jetson-stats.preset
Patch0:         jetson-stats-7.2.0-lumina.patch
BuildArch:      noarch

BuildRequires:  python3-devel
BuildRequires:  python3-setuptools
BuildRequires:  python3-wheel
BuildRequires:  pyproject-rpm-macros
BuildRequires:  systemd-rpm-macros
Requires:       nvidia-l4t-driver >= 39.2.1
Requires:       nvidia-l4t-tools >= 39.2.1
Requires:       python3-distro
Requires:       python3-nvidia-ml-py >= 13.595.45
Requires:       python3-smbus2
Requires:       shadow-utils
%{?systemd_requires}

%description
jetson-stats provides jtop, an interactive monitor for NVIDIA Jetson CPU, GPU,
memory, engine, thermal, fan, and power data. It also exposes controlled access
to NVPModel, fan profiles, and jetson_clocks through a privileged system
service. Lumina grants access to administrator accounts in the wheel group.

%prep
%autosetup -n jetson_stats-%{version} -p1

%generate_buildrequires
# Runtime dependencies are declared explicitly above and are not needed to
# construct the wheel. Keep staged Lumina runtime packages out of BuildRequires.
%pyproject_buildrequires -R

%build
%pyproject_wheel

%install
%pyproject_install
%pyproject_save_files jtop
install -Dpm0644 %{SOURCE1} %{buildroot}%{_unitdir}/jtop.service
install -Dpm0644 %{SOURCE2} \
    %{buildroot}%{_prefix}/lib/systemd/system-preset/86-jetson-stats.preset
install -Dpm0644 scripts/jtop_env.sh \
    %{buildroot}%{_sysconfdir}/profile.d/jtop_env.sh

%check
%pyproject_check_import

%post
%systemd_post jtop.service

%preun
%systemd_preun jtop.service

%postun
%systemd_postun_with_restart jtop.service

%files -f %{pyproject_files}
%license LICENSE
%doc README.md
%config(noreplace) %{_sysconfdir}/profile.d/jtop_env.sh
%{_unitdir}/jtop.service
%{_prefix}/lib/systemd/system-preset/86-jetson-stats.preset
%{_bindir}/jetson_config
%{_bindir}/jetson_release
%{_bindir}/jetson_swap
%{_bindir}/jtop
%{_datadir}/jetson_stats/

%changelog
* Thu Sep 03 2026 Lumina Linux <packages@linux.1t.ru> - 7.2.0-2.lu26
- Keep explicitly declared runtime dependencies out of wheel BuildRequires

* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 7.2.0-1.lu26
- Package jtop with L4T 39.2.1 detection and wheel-group administration
