#!/usr/bin/env bash

set -euo pipefail

readonly rpm_dir="${1:-}"
readonly output_file="${2:-}"
readonly requested_image_size="${3:-auto}"
readonly profile="${4:-workstation}"
readonly source_epoch="${SOURCE_DATE_EPOCH:-1788292800}"
readonly partition_start=32768
readonly gpt_tail_sectors=33
readonly sector_bytes=512
readonly mebibyte=$((1024 * 1024))
readonly gibibyte=$((1024 * 1024 * 1024))
readonly auto_free_bytes=$((512 * mebibyte))
readonly image_alignment_bytes=$((64 * mebibyte))

die()
{
    printf 'build-rootfs: %s\n' "$*" >&2
    exit 1
}

round_up()
{
    local value="$1"
    local alignment="$2"

    printf '%s\n' "$(( (value + alignment - 1) / alignment * alignment ))"
}

size_to_bytes()
{
    local size="$1"
    local value

    case "${size}" in
        *[Mm])
            value="${size%?}"
            printf '%s\n' "$((value * mebibyte))"
            ;;
        *[Gg])
            value="${size%?}"
            printf '%s\n' "$((value * gibibyte))"
            ;;
        *)
            printf '%s\n' "$((size * gibibyte))"
            ;;
    esac
}

[[ -d "${rpm_dir}" && -n "${output_file}" ]] ||
    die 'usage: build-rootfs-in-container.sh RPM_DIR OUTPUT.raw.zst [auto|SIZE] [workstation|server]'
[[ "${requested_image_size}" == auto || "${requested_image_size}" =~ ^[1-9][0-9]*[MmGg]?$ ]] ||
    die 'image size must be auto, a GiB integer, or an integer with M/G suffix'
[[ "${profile}" == workstation || "${profile}" == server ]] ||
    die 'profile must be workstation or server'
[[ ! -e "${output_file}" ]] || die "output already exists: ${output_file}"

dnf -y -q install dracut e2fsprogs fakeroot uboot-tools util-linux zstd >/dev/null

readonly work_dir="$(mktemp -d /output/.lumina-orangepi5-ultra.XXXXXX)"
cleanup()
{
    rm -rf -- "${work_dir}"
}
trap cleanup EXIT
readonly rootfs="${work_dir}/rootfs"
readonly root_image="${work_dir}/root.ext4"
readonly raw_image="${work_dir}/lumina-orangepi5-ultra.raw"
mkdir -p "${rootfs}"

shopt -s nullglob
rpms=("${rpm_dir}"/*.rpm)
[[ ${#rpms[@]} -eq 5 ]] || die 'Orange Pi 5 Ultra RPM set must contain exactly five packages'

base_packages=(
    alsa-utils
    basesystem
    bash
    bluez
    btop
    coreutils
    dnf5
    dracut
    dracut-network
    dtc
    e2fsprogs
    ethtool
    fastfetch
    fedora-gpg-keys
    fedora-repos
    filesystem
    glibc-langpack-en
    hostname
    i2c-tools
    iproute
    iputils
    iw
    kbd
    kernel
    kernel-modules
    kernel-modules-extra
    kmod
    less
    libgpiod-utils
    NetworkManager
    NetworkManager-tui
    NetworkManager-wifi
    openssh-server
    passwd
    policycoreutils
    procps-ng
    rootfiles
    rpm
    selinux-policy-targeted
    shadow-utils
    sudo
    systemd
    systemd-udev
    usbutils
    util-linux
    vim-minimal
    wpa_supplicant
    wireless-regdb
    zram-generator-defaults
)

profile_packages=()
if [[ "${profile}" == workstation ]]; then
    profile_packages=(
        @gnome-desktop
        firefox
        gdm
        mesa-dri-drivers
        mesa-libEGL
        mesa-libGL
        mesa-vulkan-drivers
    )
fi

# Seed a runnable shell and C library first. RPM 6 may otherwise schedule a
# package pre-install script between unpacking /bin/sh and its dynamic loader
# while constructing an empty installroot.
dnf -y -q --installroot="${rootfs}" --releasever=44 --use-host-config \
    --setopt=install_weak_deps=False \
    --setopt=keepcache=False \
    install bash coreutils filesystem glibc setup

# The kernel initramfs is created explicitly below. Running dracut from the
# kernel RPM transaction would incorrectly inspect the container host.
install -d -m 0755 "${rootfs}/etc/kernel"
printf 'initrd_generator=none\n' >"${rootfs}/etc/kernel/install.conf"
dnf -y -q --installroot="${rootfs}" --releasever=44 --use-host-config \
    --setopt=install_weak_deps=False \
    --setopt=keepcache=False \
    install "${base_packages[@]}" "${profile_packages[@]}" "${rpms[@]}"
rm -f -- "${rootfs}/etc/kernel/install.conf"

cp -a /image/rootfs/. "${rootfs}/"
chmod 0755 "${rootfs}/usr/libexec/lumina-orangepi5-ultra-grow-rootfs"
chmod 0440 "${rootfs}/etc/sudoers.d/10-lumina-wheel"

printf 'LABEL=lumina_root / ext4 defaults,noatime 0 1\n' >"${rootfs}/etc/fstab"
printf 'lumina-orangepi5-ultra\n' >"${rootfs}/etc/hostname"
printf 'LANG=en_US.UTF-8\n' >"${rootfs}/etc/locale.conf"
: >"${rootfs}/etc/machine-id"
rm -f -- "${rootfs}/var/lib/dbus/machine-id"
rm -f -- "${rootfs}"/etc/ssh/ssh_host_*_key "${rootfs}"/etc/ssh/ssh_host_*_key.pub
passwd --root "${rootfs}" --lock root >/dev/null
readonly lumina_password_hash='$6$lumina-opi5u$s0Yaq4SCTH20qM.BTSCljAcdtDR7jGo0LpmnAh/i/w.Xv.3DaX.J3keYJCDsgrzHCirDRX9Wkz76txDeSeQOm1'
useradd --root "${rootfs}" --no-create-home --uid 1000 \
    --groups wheel,audio,video,render \
    --shell /bin/bash --password "${lumina_password_hash}" lumina
install -d -m 0700 -o 1000 -g 1000 "${rootfs}/home/lumina"
cp -a "${rootfs}/etc/skel/." "${rootfs}/home/lumina/"
chown -R 1000:1000 "${rootfs}/home/lumina"

sed -i 's/^SELINUX=.*/SELINUX=enforcing/' "${rootfs}/etc/selinux/config"

services=(
    NetworkManager.service
    systemd-timesyncd.service
    sshd.service
    lumina-orangepi5-ultra-grow-rootfs.service
)
default_target=multi-user.target
if [[ "${profile}" == workstation ]]; then
    services+=(gdm.service)
    default_target=graphical.target
fi
SYSTEMD_OFFLINE=1 chroot "${rootfs}" /usr/bin/systemctl enable "${services[@]}" >/dev/null
SYSTEMD_OFFLINE=1 chroot "${rootfs}" /usr/bin/systemctl set-default "${default_target}" >/dev/null

chroot "${rootfs}" /usr/sbin/setfiles -F \
    /etc/selinux/targeted/contexts/files/file_contexts / >/dev/null

mapfile -t kernel_versions < <(
    find "${rootfs}/usr/lib/modules" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V
)
[[ ${#kernel_versions[@]} -eq 1 ]] || die 'expected exactly one installed Fedora kernel'
readonly kver="${kernel_versions[0]}"
readonly kernel_config="${rootfs}/usr/lib/modules/${kver}/config"
readonly module_board_dtb="${rootfs}/usr/lib/modules/${kver}/dtb/rockchip/rk3588-orangepi-5-ultra.dtb"
readonly board_dtb="${rootfs}/boot/lumina/rk3588-orangepi-5-ultra-${kver}.dtb"

[[ "${kver}" != *armbian* ]] || die "Armbian kernel leaked into image: ${kver}"
install -Dpm 0644 "${rootfs}/usr/lib/modules/${kver}/vmlinuz" \
    "${rootfs}/boot/vmlinuz-${kver}"
[[ -r "${module_board_dtb}" ]] || die 'Fedora kernel does not contain the Orange Pi 5 Ultra DTB'
for config in \
    CONFIG_BRCMFMAC=m \
    CONFIG_DRM_ACCEL_ROCKET=m \
    CONFIG_DRM_PANTHOR=m \
    CONFIG_R8169=m; do
    grep -Fqx "${config}" "${kernel_config}" || die "kernel config is missing ${config}"
done
fdtget "${module_board_dtb}" / model | grep -Fqx 'Xunlong Orange Pi 5 Ultra' ||
    die 'Orange Pi 5 Ultra DTB model mismatch'
chroot "${rootfs}" /usr/libexec/lumina-orangepi5-ultra-dtb-setup "${kver}"
fdtget "${board_dtb}" /mmc@fe2d0000/wifi@1 compatible |
    grep -Fqw brcm,bcm43752-fmac || die 'merged DTB does not enable the AP6611 radio'

rm -f "${rootfs}/boot/initramfs-${kver}.img"
fakeroot -- dracut --force --no-hostonly --add selinux --sysroot "${rootfs}" \
    "${rootfs}/boot/initramfs-${kver}.img" "${kver}"
chroot "${rootfs}" /usr/bin/lumina-orangepi5-ultra-boot-setup \
    --kernel "${kver}" --root LABEL=lumina_root

chroot "${rootfs}" /usr/sbin/setfiles -F \
    /etc/selinux/targeted/contexts/files/file_contexts / >/dev/null

find "${rootfs}" -depth -exec touch --no-dereference --date="@${source_epoch}" {} +

readonly rootfs_used_bytes="$(du -sx --block-size=1 "${rootfs}" | awk '{ print $1 }')"
if [[ "${requested_image_size}" == auto ]]; then
    root_bytes="$(round_up \
        "$((rootfs_used_bytes + rootfs_used_bytes / 16 + auto_free_bytes))" \
        "${image_alignment_bytes}")"
    readonly required_free_bytes="${auto_free_bytes}"
else
    total_bytes="$(size_to_bytes "${requested_image_size}")"
    root_bytes=$((total_bytes - partition_start * sector_bytes))
    readonly required_free_bytes=$((128 * mebibyte))
    (( root_bytes >= rootfs_used_bytes + rootfs_used_bytes / 16 + required_free_bytes )) ||
        die 'requested image is too small for the installed root and free-space requirement'
fi

filesystem_value()
{
    local field="$1"

    LC_ALL=C dumpe2fs -h "${root_image}" 2>/dev/null |
        awk -F: -v field="${field}" '$1 == field {
            gsub(/[[:space:]]/, "", $2)
            print $2
        }'
}

readonly mkfs_log="${work_dir}/mkfs-ext4.log"
auto_growth_steps=0
while :; do
    truncate -s "${root_bytes}" "${root_image}"
    sizing_probe_result='ext4 population failed'
    if mkfs.ext4 -q -F -L lumina_root \
        -U 4c554d49-4e41-4035-8000-000000000001 \
        -m 1 -E root_owner=0:0 -d "${rootfs}" "${root_image}" \
        >"${mkfs_log}" 2>&1; then
        tune2fs -c 0 -i 0 "${root_image}" >/dev/null

        filesystem_block_size="$(filesystem_value 'Block size')"
        filesystem_free_blocks="$(filesystem_value 'Free blocks')"
        filesystem_reserved_blocks="$(filesystem_value 'Reserved block count')"
        [[ "${filesystem_block_size}" =~ ^[0-9]+$ &&
           "${filesystem_free_blocks}" =~ ^[0-9]+$ &&
           "${filesystem_reserved_blocks}" =~ ^[0-9]+$ ]] ||
            die 'could not determine ext4 free space'
        available_root_bytes=$((
            (filesystem_free_blocks - filesystem_reserved_blocks) * filesystem_block_size
        ))
        if (( available_root_bytes >= required_free_bytes )); then
            break
        fi
        sizing_probe_result="only $((available_root_bytes / mebibyte)) MiB usable free"
    elif [[ "${requested_image_size}" != auto ]]; then
        cat "${mkfs_log}" >&2
        die 'could not populate ext4 filesystem'
    fi

    [[ "${requested_image_size}" == auto ]] || die 'ext4 has less usable free space than requested'
    (( ++auto_growth_steps <= 64 )) || die 'automatic ext4 sizing did not converge'
    root_bytes=$((root_bytes + image_alignment_bytes))
    printf 'Ext4 sizing probe %s (%s): growing root filesystem to %s MiB\n' \
        "${auto_growth_steps}" "${sizing_probe_result}" "$((root_bytes / mebibyte))"
done
rm -f -- "${mkfs_log}"
e2fsck -fn "${root_image}" >/dev/null

readonly root_bytes
readonly total_bytes=$(((partition_start + gpt_tail_sectors) * sector_bytes + root_bytes))
readonly total_sectors=$((total_bytes / sector_bytes))
readonly root_sectors=$((root_bytes / sector_bytes))
readonly available_root_bytes
readonly uboot="${rootfs}/usr/lib/lumina-orangepi5-ultra/u-boot-rockchip.bin"
readonly uboot_size="$(stat -c %s "${uboot}")"
(( 64 * sector_bytes + uboot_size <= partition_start * sector_bytes )) ||
    die 'U-Boot does not fit before the root partition'

verify_image_context()
{
    local path="$1"
    local expected_context="$2"

    debugfs -R "ea_get ${path} security.selinux" "${root_image}" 2>/dev/null |
        grep -Fq -- "${expected_context}\\000" ||
        die "SELinux context was not preserved for ${path}: ${expected_context}"
}

verify_image_context / system_u:object_r:root_t:s0
verify_image_context /dev system_u:object_r:device_t:s0
verify_image_context /sys system_u:object_r:sysfs_t:s0
verify_image_context /run system_u:object_r:var_run_t:s0

truncate -s "${total_bytes}" "${raw_image}"
printf 'label: gpt\nunit: sectors\nfirst-lba: 34\n\nstart=%s, size=%s, type=L\n' \
    "${partition_start}" "${root_sectors}" | sfdisk --no-reread "${raw_image}" >/dev/null
dd if="${root_image}" of="${raw_image}" bs=512 seek="${partition_start}" \
    conv=notrunc status=none
dd if="${uboot}" of="${raw_image}" bs=512 seek=64 conv=notrunc status=none

expected_uboot_hash="$(sha256sum "${uboot}" | awk '{ print $1 }')"
actual_uboot_hash="$(dd if="${raw_image}" bs=1 skip=32768 count="${uboot_size}" status=none |
    sha256sum | awk '{ print $1 }')"
[[ "${actual_uboot_hash}" == "${expected_uboot_hash}" ]] ||
    die 'raw U-Boot verification failed'
sfdisk --verify "${raw_image}" >/dev/null

printf 'Image profile: %s; kernel: %s\n' "${profile}" "${kver}"
printf 'Image geometry: %s MiB raw, %s MiB root, at least %s MiB initially free\n' \
    "$((total_bytes / mebibyte))" "$((root_bytes / mebibyte))" \
    "$((available_root_bytes / mebibyte))"

mkdir -p "$(dirname -- "${output_file}")"
zstd -q -T0 -15 -f "${raw_image}" -o "${output_file}"
touch --date="@${source_epoch}" "${output_file}"
(
    cd -- "$(dirname -- "${output_file}")"
    sha256sum "$(basename -- "${output_file}")" >"$(basename -- "${output_file}").sha256"
)
printf 'Built %s\n' "${output_file}"
