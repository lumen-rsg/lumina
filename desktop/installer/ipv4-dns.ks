# Apply before repository setup, including Wi-Fi connections created later in
# Anaconda. Runtime global DNS supersedes broken DHCP/RA-provided resolvers.
%pre --erroronfail --log=/tmp/lumina-installer-network.log
set -eu
mkdir -p /run/NetworkManager/conf.d
cat > /run/NetworkManager/conf.d/99-lumina-installer-dns.conf <<'DNS'
[main]
dns=default
rc-manager=symlink
systemd-resolved=false

[global-dns-domain-*]
servers=1.1.1.1,8.8.8.8
DNS
# The Fedora installer uses systemd-resolved, which does not consume this NM
# global override. Point libc at NM's generated file and use its direct backend.
# This changes only the live installer root, not /mnt/sysroot.
ln -sfn /run/NetworkManager/resolv.conf /etc/resolv.conf
nmcli general reload conf
nmcli general reload dns-full
echo 'Lumina installer DNS override enabled: 1.1.1.1, 8.8.8.8'
%end

# Do not impose the USB installer's kernel restriction on the desktop. The
# runtime DNS file is not one of Anaconda's copied global-DNS configuration files.
%post --erroronfail --log=/var/log/lumina-installer-network.log
set -eu
# Anaconda may copy the live resolver file for package/post-script operations.
# Restore Fedora's installed resolver rather than keeping a live /run NM link.
if [ -f /usr/lib/systemd/system/systemd-resolved.service ]; then
    ln -sfn /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
fi
grubby --update-kernel=ALL --remove-args="ipv6.disable"
for config in /etc/default/grub /etc/kernel/cmdline; do
    if [ -f "$config" ]; then
        sed -i 's/\bipv6\.disable=1\b//g' "$config"
    fi
done
if grubby --info=ALL | grep -Fq 'ipv6.disable=1'; then
    echo 'Installer-only IPv6 restriction persisted in target boot entries' >&2
    exit 1
fi
%end
