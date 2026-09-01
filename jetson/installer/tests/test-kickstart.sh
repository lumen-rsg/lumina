#!/usr/bin/env bash

set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly TEST_DIR
readonly KICKSTART="${TEST_DIR}/../lumina-jetson.ks"
readonly BUILD_SCRIPT="${TEST_DIR}/../build-iso.sh"
readonly GRUB_CONFIG="${TEST_DIR}/../grub.cfg.fragment"
readonly REPO_OVERRIDE="${TEST_DIR}/../../../common/lumina-release/files/90-lumina-repositories.repo"
readonly RELEASE_SPEC="${TEST_DIR}/../../../common/lumina-release/lumina-release.spec"

fail()
{
    echo "FAIL: $*" >&2
    exit 1
}

grep -Fqx 'rootpw --plaintext root' "${KICKSTART}" ||
    fail "temporary Anaconda password is not configured"
if grep -Fq '/usr/bin/chage --lastday 0 root' "${KICKSTART}"; then
    fail "hard password expiry can lock the operator out"
fi
grep -Fq '/usr/bin/passwd --lock root' "${KICKSTART}" ||
    fail "temporary root password is not locked before first boot"
if grep -Fq '/var/lib/lumina/temporary-root-password' "${KICKSTART}"; then
    fail "desktop image retains the obsolete shared-password marker"
fi
grep -Fq '/usr/sbin/restorecon -RF' "${KICKSTART}" ||
    fail "authentication paths are not explicitly relabeled"
grep -Fq 'clock_seed=/run/install/repo/jetson/build.env' "${KICKSTART}" ||
    fail "offline installer clock seed is not loaded"
grep -Fq "printf 'LUMINA_INSTALLER_MIN_EPOCH=%s\\n'" "${BUILD_SCRIPT}" ||
    fail "ISO builder does not emit the offline clock seed"
# shellcheck disable=SC2016
grep -Fq 'date -u --set="@${LUMINA_INSTALLER_MIN_EPOCH}"' "${KICKSTART}" ||
    fail "stale installer clocks are not advanced"
grep -Fq 'PermitRootLogin prohibit-password' "${KICKSTART}" ||
    fail "SSH root access is not restricted to keys"
grep -Fq 'PasswordAuthentication no' "${KICKSTART}" ||
    fail "SSH password authentication is not disabled"
for package in NetworkManager-wifi pciutils usbutils iw btop; do
    grep -Fqx "${package}" "${KICKSTART}" ||
        fail "installed system is missing ${package}"
    grep -Fq "    ${package} \\" "${BUILD_SCRIPT}" ||
        fail "ISO builder does not require ${package} in its offline repository"
done
grep -Fqx '@gnome-desktop' "${KICKSTART}" ||
    fail "GNOME desktop group is not installed"
grep -Fqx 'gnome-initial-setup' "${KICKSTART}" ||
    fail "GNOME Initial Setup is not explicitly installed"
grep -Fqx 'gnome-control-center' "${KICKSTART}" ||
    fail "GNOME Control Center is not explicitly installed"
for package in \
    gdm \
    gnome-initial-setup \
    gnome-control-center \
    gnome-shell; do
    grep -Fq "    ${package} \\" "${BUILD_SCRIPT}" ||
        fail "ISO builder does not require ${package} in its offline repository"
done
for package in \
    gnome-shell-extension-appindicator \
    lumina-artwork \
    nvidia-l4t-power-gui \
    nvidia-cuda-runtime \
    nvidia-cuda-toolkit \
    jetson-stats; do
    grep -Fqx "${package}" "${KICKSTART}" ||
        fail "installed desktop is missing ${package}"
    grep -Fq "    ${package} \\" "${BUILD_SCRIPT}" ||
        fail "ISO builder does not require ${package} in its offline repository"
done
grep -Fq 'services --enabled=NetworkManager,sshd,gdm' "${KICKSTART}" ||
    fail "GDM is not enabled"
grep -Fq '/usr/bin/systemctl set-default graphical.target' "${KICKSTART}" ||
    fail "installed system does not default to graphical boot"
grep -Fqx '[fedora-cisco-openh264]' "${REPO_OVERRIDE}" ||
    fail "Cisco OpenH264 override targets the wrong repository"
grep -Fqx 'enabled=false' "${REPO_OVERRIDE}" ||
    fail "Cisco OpenH264 repository is not disabled"
grep -Fq '90-lumina-repositories.repo' "${RELEASE_SPEC}" ||
    fail "lumina-release does not package the repository override"
grep -Fq '/etc/dracut.conf.d/91-lumina-realtek.conf' "${KICKSTART}" ||
    fail "Realtek initramfs configuration is not installed"
for firmware in rtl8822_setting.bin rtl8822cu_config rtl8822cu_fw; do
    grep -Fq "/usr/lib/firmware/${firmware}" "${KICKSTART}" ||
        fail "initramfs does not explicitly include ${firmware}"
done
for artwork in lumina-logo.svg lumina-logo-white.svg; do
    grep -Fq "lumina-artwork/files/${artwork}" \
        "${TEST_DIR}/../remaster-runtime.sh" ||
        fail "installer runtime does not embed ${artwork}"
done

rescue_entry=$(sed -n \
    '/^menuentry "Rescue installed 1T Lumina/,/^}/p' "${GRUB_CONFIG}")
grep -Fq 'inst.rescue' <<<"${rescue_entry}" ||
    fail "non-destructive rescue entry is missing"
if grep -Fq 'lumina.jetson.erase' <<<"${rescue_entry}"; then
    fail "rescue entry contains a destructive erase argument"
fi

echo "PASS: Kickstart desktop, account, repository, and SSH policy"
