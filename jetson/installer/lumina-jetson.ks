# 1T Lumina 26.08 installer profile for NVIDIA Jetson Orin.
#
# The installer ISO must contain lumina-jetson-storage at the path below and
# the Lumina Jetson RPM repository. Select the target with the kernel arguments
# documented in README.md.

text
eula --agreed
keyboard --xlayouts=us
lang en_US.UTF-8
network --bootproto=dhcp --device=link --activate
repo --name="lumina-offline" --baseurl=file:///run/install/repo/LuminaPackages
rootpw --lock
selinux --enforcing
services --enabled=NetworkManager,sshd
shutdown
timezone Europe/Moscow --utc

%pre --erroronfail --log=/tmp/lumina-jetson-pre.log
installer_key=/run/install/repo/jetson/installer_authorized_key
if [ -s "${installer_key}" ]; then
    install -d -m 0700 /root/.ssh
    install -m 0600 "${installer_key}" /root/.ssh/authorized_keys
    if [ ! -e /etc/ssh/sshd_config ]; then
        install -d -m 0755 /etc/ssh
        printf '%s\n' \
            'PermitRootLogin prohibit-password' \
            'PasswordAuthentication no' \
            'PubkeyAuthentication yes' \
            'AuthorizedKeysFile .ssh/authorized_keys' \
            >/etc/ssh/sshd_config
    fi
    ssh-keygen -A
    systemctl restart anaconda-sshd.service ||
        systemctl restart sshd.service
fi

helper=/run/install/repo/jetson/lumina-jetson-storage
if [ ! -x "${helper}" ]; then
    helper=/usr/libexec/lumina-jetson-installer/lumina-jetson-storage
fi
"${helper}" \
    prepare --from-cmdline \
    --kickstart-output /tmp/lumina-jetson-storage.ks
%end

%include /tmp/lumina-jetson-storage.ks

%pre-install --erroronfail --log=/tmp/lumina-jetson-bootstrap.log
/run/install/repo/jetson/lumina-jetson-bootstrap /mnt/sysroot
%end

%packages --inst-langs=en
@core
lumina-release
kernel-tegra-l4t
tegra-l4t-firmware
nvidia-l4t-driver
nvidia-l4t-multimedia
nvidia-l4t-tools
nvme-cli
lumina-jetson-graphics
lumina-jetson-boot-assets
lumina-jetson-bootconf
NetworkManager
openssh-server
dnf5
rpm
sudo
-grub2-efi-aa64
-grub2-efi-aa64-cdboot
-grub2-tools-efi
-kernel
-kernel-core
-kernel-modules
-kernel-modules-core
-gdm
-gnome-shell
%end

%post --erroronfail --log=/root/lumina-jetson-post.log
test -f /boot/Image-6.8.12-1021-tegra
/usr/bin/dracut --force \
    /boot/initramfs-6.8.12-1021-tegra.img \
    6.8.12-1021-tegra
test -f /boot/initramfs-6.8.12-1021-tegra.img
%end

%post --nochroot --erroronfail --log=/mnt/sysroot/root/lumina-jetson-boot.log
/run/install/repo/jetson/lumina-jetson-finalize \
    /mnt/sysroot /tmp/lumina-jetson-storage.ks
%end

%post --nochroot --erroronfail --log=/mnt/sysroot/root/lumina-jetson-ssh.log
installer_key=/run/install/repo/jetson/installer_authorized_key
if [ -s "${installer_key}" ]; then
    mkdir -p /mnt/sysroot/root/.ssh
    cp "${installer_key}" /mnt/sysroot/root/.ssh/authorized_keys
    chmod 0700 /mnt/sysroot/root/.ssh
    chmod 0600 /mnt/sysroot/root/.ssh/authorized_keys

    mkdir -p /mnt/sysroot/etc/ssh/sshd_config.d
    printf '%s\n' \
        'PermitRootLogin prohibit-password' \
        'PasswordAuthentication no' \
        'PubkeyAuthentication yes' \
        >/mnt/sysroot/etc/ssh/sshd_config.d/10-lumina-installer.conf
    chmod 0600 \
        /mnt/sysroot/etc/ssh/sshd_config.d/10-lumina-installer.conf

    chroot /mnt/sysroot /usr/sbin/restorecon -RF \
        /root/.ssh /etc/ssh/sshd_config.d/10-lumina-installer.conf
fi
%end
