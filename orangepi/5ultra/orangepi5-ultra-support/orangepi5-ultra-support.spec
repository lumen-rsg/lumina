%global debug_package %{nil}

Name:           orangepi5-ultra-support
Version:        1.0
Release:        3.lu26
Summary:        Runtime support and qualification tools for Orange Pi 5 Ultra
License:        MIT
URL:            https://linux.1t.ru/
BuildArch:      noarch

Source0:        lumina-orangepi5-ultra-grow-rootfs
Source1:        lumina-orangepi5-ultra-grow-rootfs.service
Source2:        80-orangepi5-ultra.preset
Source3:        lumina-orangepi5-ultra-qualify
Source4:        orangepi5-ultra-btsdio.conf

Requires:       cloud-utils-growpart
Requires:       e2fsprogs
Requires:       kernel-core >= 6.18
Requires:       kmod
Requires:       rpm
Requires:       systemd
Recommends:     lumina-orangepi5-ultra-boot
Recommends:     orangepi5-ultra-firmware

%description
Board-specific lifecycle support for the Orange Pi 5 Ultra. It expands a raw
image root filesystem on first boot and provides a hardware qualification
command covering the mainline GPU, NPU, networking, display, audio, storage,
systemd, taint, and kernel-log contracts.

%prep

%build

%install
install -Dpm 0755 %{SOURCE0} \
    %{buildroot}%{_libexecdir}/lumina-orangepi5-ultra-grow-rootfs
install -Dpm 0644 %{SOURCE1} \
    %{buildroot}/usr/lib/systemd/system/lumina-orangepi5-ultra-grow-rootfs.service
install -Dpm 0644 %{SOURCE2} \
    %{buildroot}/usr/lib/systemd/system-preset/80-orangepi5-ultra.preset
install -Dpm 0755 %{SOURCE3} \
    %{buildroot}%{_bindir}/lumina-orangepi5-ultra-qualify
install -Dpm 0644 %{SOURCE4} \
    %{buildroot}%{_prefix}/lib/modprobe.d/orangepi5-ultra-btsdio.conf

%files
%{_bindir}/lumina-orangepi5-ultra-qualify
%{_libexecdir}/lumina-orangepi5-ultra-grow-rootfs
%{_prefix}/lib/modprobe.d/orangepi5-ultra-btsdio.conf
/usr/lib/systemd/system-preset/80-orangepi5-ultra.preset
/usr/lib/systemd/system/lumina-orangepi5-ultra-grow-rootfs.service

%changelog
* Thu Sep 03 2026 Lumina Linux <packages@linux.1t.ru> - 1.0-3.lu26
- Blacklist the spurious SDIO Bluetooth transport on the UART-wired AP6611
- Accept only the expected DKMS module taint flags during qualification

* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 1.0-2.lu26
- Qualify the RPM owning the running kernel and preserve query errors

* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 1.0-1.lu26
- Add idempotent SD/eMMC/NVMe growth and mainline hardware qualification
