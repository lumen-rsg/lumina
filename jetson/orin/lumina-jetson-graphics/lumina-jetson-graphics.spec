Name:           lumina-jetson-graphics
Version:        1.0
Release:        3.lu26
Summary:        Fedora desktop integration for NVIDIA Jetson graphics
License:        MIT
URL:            https://github.com/Lumina-Linux/lumina
ExclusiveArch:  aarch64

Source0:        lumina-jetson-gpu-uaccess.rules
Source1:        lumina-jetson-gpu-modes.rules

Requires:       nvidia-l4t-driver >= 39.2.0
Requires:       systemd-udev

%description
Fedora integration for NVIDIA's Jetson L4T graphics userspace. This package
exposes the NVIDIA GBM backends in Fedora's library search path and grants the
active local seat access to the non-DRM Tegra runtime device nodes required by
the Wayland compositor.

%prep

%build

%install
install -Dpm0644 %{SOURCE0} \
    %{buildroot}/usr/lib/udev/rules.d/70-lumina-jetson-gpu-uaccess.rules
install -Dpm0644 %{SOURCE1} \
    %{buildroot}/usr/lib/udev/rules.d/99-z-lumina-jetson-gpu-modes.rules

mkdir -p %{buildroot}/usr/lib64/gbm
ln -s ../../lib/aarch64-linux-gnu/gbm/nvidia-drm_gbm.so \
    %{buildroot}/usr/lib64/gbm/nvidia-drm_gbm.so
ln -s ../../lib/aarch64-linux-gnu/gbm/tegra_gbm.so \
    %{buildroot}/usr/lib64/gbm/tegra_gbm.so

%post
udevadm control --reload >/dev/null 2>&1 || :
udevadm trigger --action=change --name-match=nvmap >/dev/null 2>&1 || :
udevadm trigger --action=change --subsystem-match=nvidia-gpu >/dev/null 2>&1 || :
udevadm trigger --action=change --subsystem-match=nvidia-gpu-v2 >/dev/null 2>&1 || :
udevadm trigger --action=change --subsystem-match=nvidia-gpu-v2-power >/dev/null 2>&1 || :

%postun
udevadm control --reload >/dev/null 2>&1 || :

%files
/usr/lib/udev/rules.d/70-lumina-jetson-gpu-uaccess.rules
/usr/lib/udev/rules.d/99-z-lumina-jetson-gpu-modes.rules
/usr/lib64/gbm/nvidia-drm_gbm.so
/usr/lib64/gbm/tegra_gbm.so

%changelog
* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 1.0-3.lu26
- Grant greeter bootstrap access to the R39 nvidia-gpu-v2 runtime nodes

* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 1.0-2.lu26
- Preserve greeter bootstrap access across logind ACL transitions

* Thu Jul 30 2026 Lumina Linux <packages@linux.1t.ru> - 1.0-1.lu26
- Add Fedora GBM search-path compatibility links
- Grant active-seat access to Tegra GPU runtime devices
