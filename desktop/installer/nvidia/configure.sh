#!/bin/bash
# Runs only inside the installed target, after its kernel and driver transaction.
set -euo pipefail
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-nvidia-fedora44
rpm -q nvidia-driver kmod-nvidia-open-dkms
driver_version=$(rpm -q nvidia-driver --qf '%{VERSION}')
mapfile -t kernels < <(rpm -q kernel-core --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n')
[[ ${#kernels[@]} -gt 0 ]]
for kernel in "${kernels[@]}"; do
    test -d "/usr/src/kernels/$kernel"
    dkms autoinstall -k "$kernel" -j 4
    test "$(modinfo -k "$kernel" -F version nvidia)" = "$driver_version"
    test "$(modinfo -k "$kernel" -F license nvidia)" = 'Dual MIT/GPL'
    echo "NVIDIA_OPEN_MODULE_OK kernel=$kernel driver=$driver_version"
done
cat > /etc/modprobe.d/lumina-nvidia.conf <<'CONF'
options nvidia_drm modeset=1 fbdev=1
CONF
cat > /etc/dracut.conf.d/90-lumina-nvidia.conf <<'CONF'
add_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "
CONF
dracut --regenerate-all --force
