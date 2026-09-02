%global driver_name brcmfmac-ap6611
%global kernel_version 7.1.12

Name:           orangepi5-ultra-brcmfmac-dkms
Version:        %{kernel_version}
Release:        1.lu26
Summary:        Mainline brcmfmac support for the Orange Pi 5 Ultra AP6611
License:        ISC
URL:            https://kernel.org/
BuildArch:      noarch

Source0:        https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-%{kernel_version}.tar.xz
Source1:        brcmfmac-ap6611.patch
Source2:        Makefile
Source3:        dkms.conf

Requires:       dkms >= 3.0
Requires:       gcc
Requires:       kernel-devel >= %{kernel_version}
Requires:       make
Requires:       orangepi5-ultra-firmware

%description
The upstream brcmfmac sources, with the minimal SDIO device support required
by the Synaptics BCM43711/AP6611 radio on the Orange Pi 5 Ultra. DKMS rebuilds
the module for compatible Fedora 7.1 kernels; the Fedora kernel itself remains
unmodified and comes directly from the distribution repositories.

%prep
mkdir -p %{driver_name}-%{version}
tar -xJf %{SOURCE0} --strip-components=1 -C %{driver_name}-%{version} \
    linux-%{kernel_version}/COPYING
tar -xJf %{SOURCE0} --strip-components=6 -C %{driver_name}-%{version} \
    linux-%{kernel_version}/drivers/net/wireless/broadcom/brcm80211/brcmfmac \
    linux-%{kernel_version}/drivers/net/wireless/broadcom/brcm80211/include
cd %{driver_name}-%{version}
patch --no-backup-if-mismatch -p1 < %{SOURCE1}
install -pm 0644 %{SOURCE2} Makefile
install -pm 0644 %{SOURCE3} dkms.conf

%build

%install
install -d %{buildroot}%{_usrsrc}/%{driver_name}-%{version}
cp -a %{driver_name}-%{version}/. \
    %{buildroot}%{_usrsrc}/%{driver_name}-%{version}/

%post
/usr/lib/dkms/common.postinst %{driver_name} %{version} "" aarch64 "$1" || :

%preun
if [ "$1" -eq 0 ]; then
    dkms remove -m %{driver_name} -v %{version} --all || :
fi

%files
%license %{_usrsrc}/%{driver_name}-%{version}/COPYING
%{_usrsrc}/%{driver_name}-%{version}

%changelog
* Thu Sep 03 2026 Lumina Linux <packages@linux.1t.ru> - 7.1.12-1.lu26
- Add DKMS support for the Synaptics BCM43711/AP6611 SDIO radio
- Ignore unsupported 6 GHz chanspec entries while retaining 2.4/5 GHz support
