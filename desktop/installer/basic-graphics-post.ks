# Anaconda can copy installer video arguments into the installed boot entries.
# Basic graphics is a USB-installer workaround, not the installed Wayland mode.
%post --erroronfail --log=/var/log/lumina-basic-graphics-install.log
set -eu
grubby --update-kernel=ALL --remove-args="nomodeset"
for config in /etc/default/grub /etc/kernel/cmdline; do
    if [ -f "$config" ]; then
        sed -i 's/\bnomodeset\b//g' "$config"
    fi
done
if grubby --info=ALL | grep -qw nomodeset; then
    echo 'Installer-only nomodeset persisted in target boot entries' >&2
    exit 1
fi
%end
