# 1T Lumina 26.08 installer profile for NVIDIA Jetson Orin.
#
# The installer ISO must contain lumina-jetson-storage at the path below and
# the Lumina Jetson RPM repository. Select the target with the kernel arguments
# documented in README.md.

# Install Anaconda's payload unattended, then boot the installed system into
# GNOME Initial Setup. The temporary password only satisfies Anaconda's
# account validation and is locked in %post before the first boot.
graphical
eula --agreed
keyboard --xlayouts=us
lang en_US.UTF-8
network --bootproto=dhcp --device=link --activate
repo --name="lumina-offline" --baseurl=file:///run/install/repo/LuminaPackages
# Temporary installer-only credential; %post locks it before first boot.
rootpw --plaintext root
selinux --enforcing
services --enabled=NetworkManager,sshd,gdm
shutdown
timezone Europe/Moscow --utc

%pre --erroronfail --log=/tmp/lumina-jetson-pre.log
clock_seed=/run/install/repo/jetson/build.env
if [ ! -r "${clock_seed}" ]; then
    echo "Installer clock seed is missing: ${clock_seed}" >&2
    exit 1
fi
. "${clock_seed}"
case "${LUMINA_INSTALLER_MIN_EPOCH:-}" in
    ''|*[!0-9]*)
        echo "Invalid installer clock seed" >&2
        exit 1
        ;;
esac
current_epoch=$(date -u +%s)
if [ "${current_epoch}" -lt "${LUMINA_INSTALLER_MIN_EPOCH}" ]; then
    date -u --set="@${LUMINA_INSTALLER_MIN_EPOCH}"
    if command -v hwclock >/dev/null; then
        hwclock --systohc --utc ||
            echo "Warning: could not persist installer time to the RTC" >&2
    fi
fi

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
@gnome-desktop
gnome-initial-setup
gnome-control-center
gnome-shell-extension-appindicator
lumina-artwork
lumina-release
kernel-tegra-l4t
tegra-l4t-firmware
nvidia-l4t-driver
nvidia-l4t-multimedia
nvidia-l4t-tools
nvidia-l4t-power-gui
nvidia-cuda-runtime
nvidia-cuda-toolkit
jetson-stats
nvme-cli
efibootmgr
lumina-jetson-graphics
lumina-jetson-boot-assets
lumina-jetson-bootconf
NetworkManager
NetworkManager-wifi
openssh-server
dnf5
rpm
sudo
pciutils
usbutils
iw
btop
-grub2-efi-aa64
-grub2-efi-aa64-cdboot
-grub2-tools-efi
-kernel
-kernel-core
-kernel-modules
-kernel-modules-core
%end

%post --erroronfail --log=/root/lumina-jetson-post.log
test -f /boot/Image-6.8.12-1021-tegra

# rtl8822ce is host-only hardware and is therefore pulled into the initramfs.
# Its firmware is not declared in the vendor module metadata, so dracut cannot
# discover it automatically. Without the explicit files the first probe fails
# in the initramfs; unloading and reloading the module after switch-root works.
install -d -m 0755 /etc/dracut.conf.d
cat >/etc/dracut.conf.d/91-lumina-realtek.conf <<'REALTEK_DRACUT_EOF'
install_items+=" /usr/lib/firmware/rtl8822_setting.bin /usr/lib/firmware/rtl8822cu_config /usr/lib/firmware/rtl8822cu_fw "
REALTEK_DRACUT_EOF
/usr/bin/dracut --force \
    /boot/initramfs-6.8.12-1021-tegra.img \
    6.8.12-1021-tegra
test -f /boot/initramfs-6.8.12-1021-tegra.img

# GNOME Initial Setup starts from GDM when no regular account exists. Lock the
# installer-only root password first; the new administrator account receives
# sudo access and can deliberately enable direct root login later if desired.
/usr/bin/passwd --lock root
/usr/bin/systemctl set-default graphical.target
/usr/bin/systemctl enable gdm.service

# The installer runtime is intentionally booted with SELinux disabled. Restore
# the complete local-account authentication path explicitly before the first
# enforcing boot instead of relying on implicit transaction-time labeling.
/usr/sbin/restorecon -RF \
    /etc/passwd \
    /etc/shadow \
    /etc/group \
    /etc/gshadow \
    /etc/security \
    /etc/pam.d \
    /usr/bin/passwd \
    /usr/sbin/unix_chkpwd

/usr/bin/ls -ldZ \
    /etc/passwd \
    /etc/shadow \
    /etc/group \
    /etc/gshadow \
    /etc/security \
    /etc/pam.d \
    /usr/bin/passwd \
    /usr/sbin/unix_chkpwd \
    >/root/lumina-account-labels.log
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
