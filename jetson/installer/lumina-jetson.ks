# 1T Lumina 26.08 installer profile for NVIDIA Jetson Orin.
#
# The installer ISO must contain lumina-jetson-storage at the path below and
# the Lumina Jetson RPM repository. Select the target with the kernel arguments
# documented in README.md.

text
eula --agreed
firstboot --enable
keyboard --xlayouts=us
lang en_US.UTF-8
network --bootproto=dhcp --device=link --activate
repo --name="lumina-offline" --baseurl=file:///run/install/repo/LuminaPackages
rootpw --lock
selinux --enforcing
services --enabled=NetworkManager,gdm
shutdown
timezone Europe/Moscow --utc

%pre --erroronfail --log=/tmp/lumina-jetson-pre.log
helper=/run/install/repo/jetson/lumina-jetson-storage
if [ ! -x "${helper}" ]; then
    helper=/usr/libexec/lumina-jetson-installer/lumina-jetson-storage
fi
"${helper}" \
    prepare --from-cmdline \
    --kickstart-output /tmp/lumina-jetson-storage.ks
%end

%include /tmp/lumina-jetson-storage.ks

%packages --inst-langs=en
@^workstation-product-environment
lumina-release
kernel-tegra-l4t
tegra-l4t-firmware
nvidia-l4t-driver
nvidia-l4t-multimedia
nvidia-l4t-tools
lumina-jetson-graphics
lumina-jetson-boot-assets
lumina-jetson-bootconf
-grub2-efi-aa64
-grub2-efi-aa64-cdboot
-grub2-tools-efi
-kernel
-kernel-core
-kernel-modules
-kernel-modules-core
%end

%post --erroronfail --log=/root/lumina-jetson-post.log
/usr/sbin/lumina-jetson-boot-setup --non-interactive
%end
