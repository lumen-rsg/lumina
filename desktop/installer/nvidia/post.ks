%post --nochroot --erroronfail --log=/mnt/sysroot/var/log/lumina-nvidia-install.log
set -eu
install -Dpm0644 /run/install/repo/NvidiaSupport/RPM-GPG-KEY-nvidia-fedora44 /mnt/sysroot/etc/pki/rpm-gpg/RPM-GPG-KEY-nvidia-fedora44
install -Dpm0644 /run/install/repo/NvidiaSupport/nvidia-driver.repo /mnt/sysroot/etc/yum.repos.d/nvidia-driver.repo
# DKMS compiler probes require real devices and kernel interfaces. Reuse
# Anaconda's mounts, or provide them if this stage runs after their teardown.
for interface in dev proc sys; do
    mountpoint -q "/mnt/sysroot/$interface" || mount --bind "/$interface" "/mnt/sysroot/$interface"
done
chroot /mnt/sysroot /bin/bash < /run/install/repo/NvidiaSupport/configure.sh
%end
