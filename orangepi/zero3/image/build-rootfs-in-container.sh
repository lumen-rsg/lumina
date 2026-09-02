#!/usr/bin/env bash

set -euo pipefail

readonly rpm_dir="${1:-}"
readonly output_file="${2:-}"
readonly requested_image_size="${3:-auto}"
readonly source_epoch="${SOURCE_DATE_EPOCH:-1788292800}"
readonly kver="6.1.31-sun50iw9"
readonly partition_start=8192
readonly sector_bytes=512
readonly mebibyte=$((1024 * 1024))
readonly gibibyte=$((1024 * 1024 * 1024))
readonly auto_free_bytes=$((128 * mebibyte))
readonly image_alignment_bytes=$((16 * mebibyte))

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
    die "usage: $0 RPM_DIR OUTPUT.raw.zst [auto|SIZE_MIB_M|SIZE_GIB_G]"
[[ "${requested_image_size}" == auto || "${requested_image_size}" =~ ^[1-9][0-9]*[MmGg]?$ ]] ||
    die "image size must be auto, a GiB integer, or an integer with M/G suffix"
[[ ! -e "${output_file}" ]] || die "output already exists: ${output_file}"

dnf -y -q install dracut e2fsprogs fakeroot uboot-tools util-linux zstd >/dev/null

readonly work_dir="$(mktemp -d /output/.lumina-zero3.XXXXXX)"
cleanup()
{
    rm -rf -- "${work_dir}"
}
trap cleanup EXIT
readonly rootfs="${work_dir}/rootfs"
readonly root_image="${work_dir}/root.ext4"
readonly raw_image="${work_dir}/lumina-zero3.raw"
mkdir -p "${rootfs}"

shopt -s nullglob
rpms=("${rpm_dir}"/*.rpm)
[[ ${#rpms[@]} -ge 4 ]] || die "Zero 3 RPM set is incomplete"

dnf -y -q --installroot="${rootfs}" --releasever=44 --use-host-config \
    --setopt=install_weak_deps=False \
    --setopt=keepcache=False \
    install \
    alsa-utils \
    basesystem \
    bash \
    bluez \
    btop \
    cloud-utils-growpart \
    coreutils \
    dnf5 \
    dracut \
    dracut-network \
    dtc \
    e2fsprogs \
    ethtool \
    fastfetch \
    fedora-gpg-keys \
    fedora-repos \
    filesystem \
    glibc-langpack-en \
    hostname \
    i2c-tools \
    iproute \
    iputils \
    iw \
    kbd \
    kmod \
    less \
    libgpiod-utils \
    NetworkManager \
    NetworkManager-tui \
    NetworkManager-wifi \
    openssh-server \
    passwd \
    policycoreutils \
    procps-ng \
    rootfiles \
    rpm \
    selinux-policy-targeted \
    shadow-utils \
    sudo \
    systemd \
    systemd-udev \
    uboot-tools \
    usbutils \
    util-linux \
    vim-minimal \
    wpa_supplicant \
    wireless-regdb \
    zram-generator-defaults \
    "${rpms[@]}"

cp -a /image/rootfs/. "${rootfs}/"
chmod 0755 \
    "${rootfs}/usr/libexec/lumina-zero3-grow-rootfs"
chmod 0440 "${rootfs}/etc/sudoers.d/10-lumina-wheel"

printf 'LABEL=lumina_root / ext4 defaults,noatime 0 1\n' >"${rootfs}/etc/fstab"
printf 'lumina-zero3\n' >"${rootfs}/etc/hostname"
printf 'LANG=en_US.UTF-8\n' >"${rootfs}/etc/locale.conf"
: >"${rootfs}/etc/machine-id"
rm -f -- "${rootfs}/var/lib/dbus/machine-id"
rm -f -- "${rootfs}"/etc/ssh/ssh_host_*_key "${rootfs}"/etc/ssh/ssh_host_*_key.pub
passwd --root "${rootfs}" --lock root >/dev/null
readonly lumina_password_hash='$6$lumina-zero3$E99Z1qQiq2oEFCog1j3JOG7spyk8g2Tpw5DWFtLxm5wUTG3GPJzrFq0NxXAo3K12WhAiP2KXRfj0/4lFySqt/.'
useradd --root "${rootfs}" --no-create-home --uid 1000 \
    --groups wheel,audio,video,render \
    --shell /bin/bash --password "${lumina_password_hash}" lumina
install -d -m 0700 -o 1000 -g 1000 "${rootfs}/home/lumina"
cp -a "${rootfs}/etc/skel/." "${rootfs}/home/lumina/"
chown -R 1000:1000 "${rootfs}/home/lumina"

sed -i 's/^SELINUX=.*/SELINUX=permissive/' "${rootfs}/etc/selinux/config"

SYSTEMD_OFFLINE=1 chroot "${rootfs}" /usr/bin/systemctl enable \
    NetworkManager.service \
    systemd-timesyncd.service \
    sshd.service \
    lumina-zero3-grow-rootfs.service \
    orangepi-zero3-wifi.service \
    orangepi-zero3-bluetooth.service >/dev/null
SYSTEMD_OFFLINE=1 chroot "${rootfs}" /usr/bin/systemctl set-default multi-user.target >/dev/null

chroot "${rootfs}" /usr/sbin/setfiles -F \
    /etc/selinux/targeted/contexts/files/file_contexts / >/dev/null

rm -f "${rootfs}/boot/initramfs-${kver}.img"
fakeroot -- dracut --force --no-hostonly --add selinux --sysroot "${rootfs}" \
    "${rootfs}/boot/initramfs-${kver}.img" "${kver}"
ln -sfn "vmlinuz-${kver}" "${rootfs}/boot/Image"
ln -sfn "dtb-${kver}" "${rootfs}/boot/dtb"
mkimage -A arm64 -O linux -T ramdisk -C none -n uInitrd \
    -d "${rootfs}/boot/initramfs-${kver}.img" \
    "${rootfs}/boot/uInitrd-${kver}" >/dev/null
ln -sfn "uInitrd-${kver}" "${rootfs}/boot/uInitrd"
mkimage -C none -A arm -T script \
    -d "${rootfs}/boot/boot.cmd" "${rootfs}/boot/boot.scr" >/dev/null

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
    readonly required_free_bytes=$((32 * mebibyte))
    (( root_bytes >= rootfs_used_bytes + rootfs_used_bytes / 16 + required_free_bytes )) ||
        die "requested image is too small for the installed root and free-space requirement"
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
        -U 4c554d49-4e41-4033-8000-000000000001 \
        -m 1 -E root_owner=0:0 -d "${rootfs}" "${root_image}" \
        >"${mkfs_log}" 2>&1; then
        tune2fs -c 0 -i 0 "${root_image}" >/dev/null

        filesystem_block_size="$(filesystem_value 'Block size')"
        filesystem_free_blocks="$(filesystem_value 'Free blocks')"
        filesystem_reserved_blocks="$(filesystem_value 'Reserved block count')"
        [[ "${filesystem_block_size}" =~ ^[0-9]+$ &&
           "${filesystem_free_blocks}" =~ ^[0-9]+$ &&
           "${filesystem_reserved_blocks}" =~ ^[0-9]+$ ]] ||
            die "could not determine ext4 free space"
        available_root_bytes=$((
            (filesystem_free_blocks - filesystem_reserved_blocks) * filesystem_block_size
        ))
        if (( available_root_bytes >= required_free_bytes )); then
            break
        fi
        sizing_probe_result="only $((available_root_bytes / mebibyte)) MiB usable free"
    elif [[ "${requested_image_size}" != auto ]]; then
        cat "${mkfs_log}" >&2
        die "could not populate ext4 filesystem"
    fi

    [[ "${requested_image_size}" == auto ]] ||
        die "ext4 has less usable free space than requested"
    (( ++auto_growth_steps <= 64 )) ||
        die "automatic ext4 sizing did not converge"
    root_bytes=$((root_bytes + image_alignment_bytes))
    printf 'Ext4 sizing probe %s (%s): growing root filesystem to %s MiB\n' \
        "${auto_growth_steps}" "${sizing_probe_result}" \
        "$((root_bytes / mebibyte))"
done
rm -f -- "${mkfs_log}"
e2fsck -fn "${root_image}" >/dev/null

readonly root_bytes
readonly total_bytes=$((partition_start * sector_bytes + root_bytes))
readonly total_sectors=$((total_bytes / sector_bytes))
readonly root_sectors=$((root_bytes / sector_bytes))
readonly available_root_bytes

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
printf 'label: dos\nlabel-id: 0x4c554d33\nunit: sectors\n\nstart=%s, size=%s, type=83, bootable\n' \
    "${partition_start}" "${root_sectors}" | sfdisk --no-reread "${raw_image}" >/dev/null
dd if="${root_image}" of="${raw_image}" bs=512 seek="${partition_start}" \
    conv=notrunc status=none
dd if="${rootfs}/usr/lib/lumina-zero3/u-boot-sunxi-with-spl.bin" \
    of="${raw_image}" bs=1K seek=8 conv=notrunc status=none

uboot_size="$(stat -c %s "${rootfs}/usr/lib/lumina-zero3/u-boot-sunxi-with-spl.bin")"
expected_uboot_hash="$(sha256sum "${rootfs}/usr/lib/lumina-zero3/u-boot-sunxi-with-spl.bin" | awk '{ print $1 }')"
actual_uboot_hash="$(dd if="${raw_image}" bs=1 skip=8192 count="${uboot_size}" status=none | sha256sum | awk '{ print $1 }')"
[[ "${actual_uboot_hash}" == "${expected_uboot_hash}" ]] || die "raw U-Boot verification failed"
sfdisk --verify "${raw_image}" >/dev/null

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
