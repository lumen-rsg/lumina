%global debug_package %{nil}
%global firmware_commit db5e86200ae592c467c4cfa50ec0c66cbc40b158

Name:           orangepi5-ultra-firmware
Version:        20250319
Release:        1.lu26
Summary:        AP6611 Wi-Fi and Bluetooth firmware for Orange Pi 5 Ultra
License:        LicenseRef-Synaptics-Proprietary
URL:            https://github.com/orangepi-xunlong/firmware
BuildArch:      noarch

Source0:        fw_syn43711a0_sdio.bin
Source1:        clm_syn43711a0.blob
Source2:        nvram_ap6611s.txt-orangepi5ultra
Source3:        SYN43711A0.hcd

Requires:       linux-firmware
Provides:       bundled(orangepi-firmware) = %{firmware_commit}

%description
Board-calibrated firmware for the Orange Pi 5 Ultra AP6611 Wi-Fi 6E and
Bluetooth 5.3 module. The files come from the Orange Pi firmware repository,
not from an Armbian root filesystem.

The upstream brcmfmac driver identifies the AP6611 SDIO function as BCM43752,
so this package installs the vendor payload under the standard mainline
brcmfmac firmware names.

%prep

%build

%install
install -Dpm 0644 %{SOURCE0} \
    %{buildroot}%{_prefix}/lib/firmware/brcm/brcmfmac43752-sdio.bin
install -Dpm 0644 %{SOURCE1} \
    %{buildroot}%{_prefix}/lib/firmware/brcm/brcmfmac43752-sdio.clm_blob
install -Dpm 0644 %{SOURCE2} \
    %{buildroot}%{_prefix}/lib/firmware/brcm/brcmfmac43752-sdio.xunlong,orangepi-5-ultra.txt
install -Dpm 0644 %{SOURCE2} \
    %{buildroot}%{_prefix}/lib/firmware/brcm/brcmfmac43752-sdio.txt
install -Dpm 0644 %{SOURCE3} \
    %{buildroot}%{_prefix}/lib/firmware/brcm/SYN43711A0.hcd

%files
%{_prefix}/lib/firmware/brcm/brcmfmac43752-sdio.bin
%{_prefix}/lib/firmware/brcm/brcmfmac43752-sdio.clm_blob
%{_prefix}/lib/firmware/brcm/brcmfmac43752-sdio.xunlong,orangepi-5-ultra.txt
%{_prefix}/lib/firmware/brcm/brcmfmac43752-sdio.txt
%{_prefix}/lib/firmware/brcm/SYN43711A0.hcd

%changelog
* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 20250319-1.lu26
- Package the Orange Pi AP6611 payload under mainline brcmfmac names
