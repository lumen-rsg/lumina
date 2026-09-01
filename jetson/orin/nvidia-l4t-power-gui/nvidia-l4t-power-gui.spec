%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}

Name:           nvidia-l4t-power-gui
Version:        39.2.1
Release:        1.lu26
Summary:        NVIDIA Jetson Power GUI and NVPModel desktop indicator
License:        BSD-3-Clause
URL:            https://developer.nvidia.com/embedded/jetson-linux
ExclusiveArch:  aarch64
Source0:        %{name}-%{version}.tar.gz
Source1:        nvidia-jetson-power.desktop

Requires:       nvidia-l4t-driver = %{version}-%{release}
Requires:       nvidia-l4t-tools = %{version}-%{release}
Requires:       libayatana-appindicator-gtk3
Requires:       polkit
Requires:       ptyxis
Requires:       python3
Requires:       python3-gobject
Requires:       python3-matplotlib
Requires:       python3-tkinter
AutoReqProv:    no

%description
NVIDIA's Jetson Power graphical monitor and the NVPModel desktop indicator.
The monitor reads the official libjetsonpower interface, while the indicator
can display and switch the active NVIDIA power profile through polkit.

%prep
%setup -c -q

%install
mkdir -p %{buildroot}
cp -a . %{buildroot}/

# NVIDIA's Ubuntu integration invokes Debian's x-terminal-emulator wrapper.
# Fedora Workstation uses Ptyxis, whose explicit command separator is `--`.
sed -i 's#x-terminal-emulator -e pkexec tegrastats#ptyxis -- pkexec tegrastats#' \
    %{buildroot}%{_datadir}/nvpmodel_indicator/nvpmodel_indicator.py
install -Dpm0644 %{SOURCE1} \
    %{buildroot}%{_datadir}/applications/nvidia-jetson-power.desktop

find %{buildroot} \( -type f -o -type l \) -printf '/%%P\n' | sort |
    sed '\#^/etc/# s#^#%%config(noreplace) #' > %{_builddir}/%{name}.files

%files -f %{_builddir}/%{name}.files

%changelog
* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 39.2.1-1.lu26
- Package NVIDIA Jetson Power GUI and NVPModel indicator for GNOME
