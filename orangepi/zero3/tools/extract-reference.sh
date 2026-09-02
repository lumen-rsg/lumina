#!/usr/bin/env bash

set -euo pipefail

readonly BOARD_VERSION="1.0.6"
readonly KVER="6.1.31-sun50iw9"
readonly EXPECTED_MODEL="OrangePi Zero3"
readonly EXPECTED_UBOOT_SHA256="e7c4224c42039d4033c78259a3f16766a82a2ba3256d1ce0c5f7c065c682b8f9"
readonly EXPECTED_KERNEL_SHA256="c709f794a37cccbb54ccc42edd3dff281f03fd5f481d584dcff1a735c03e5600"
readonly EXPECTED_DTB_SHA256="427b00ecdc9f6c28f60aeaa74b8a541377ead4dbfdc63a9428c109e11a1695a4"

readonly target="${1:-}"
readonly output_dir="${2:-}"

die()
{
    printf 'extract-reference: %s\n' "$*" >&2
    exit 1
}

[[ -n "${target}" && -n "${output_dir}" ]] ||
    die "usage: $0 USER@HOST OUTPUT_DIR"

for command in ssh tar sha256sum; do
    command -v "${command}" >/dev/null || die "missing command: ${command}"
done

ssh_command=(ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new)
if [[ -n "${SSHPASS:-}" ]]; then
    command -v sshpass >/dev/null ||
        die "SSHPASS is set but sshpass is not installed"
    ssh_command=(sshpass -e "${ssh_command[@]}")
fi

remote()
{
    "${ssh_command[@]}" "${target}" "$@"
}

readonly work_dir="$(mktemp -d)"
cleanup()
{
    rm -rf -- "${work_dir}"
}
trap cleanup EXIT

remote_model="$(remote "tr -d '\\000' </proc/device-tree/model")"
[[ "${remote_model}" == "${EXPECTED_MODEL}" ]] ||
    die "expected ${EXPECTED_MODEL}, found ${remote_model}"

remote_release="$(remote ". /etc/orangepi-release; printf '%s:%s:%s' \"\$BOARD\" \"\$VERSION\" \"\$LINUXFAMILY\"")"
[[ "${remote_release}" == "orangepizero3:${BOARD_VERSION}:sun50iw9" ]] ||
    die "unexpected Orange Pi release: ${remote_release}"

remote_kver="$(remote uname -r)"
[[ "${remote_kver}" == "${KVER}" ]] ||
    die "expected kernel ${KVER}, found ${remote_kver}"

remote_uboot="/usr/lib/linux-u-boot-next-orangepizero3_${BOARD_VERSION}_arm64/u-boot-sunxi-with-spl.bin"
remote_hash="$(remote "sha256sum '${remote_uboot}' | cut -d' ' -f1")"
[[ "${remote_hash}" == "${EXPECTED_UBOOT_SHA256}" ]] ||
    die "unexpected U-Boot hash: ${remote_hash}"

remote_hash="$(remote "sha256sum '/boot/vmlinuz-${KVER}' | cut -d' ' -f1")"
[[ "${remote_hash}" == "${EXPECTED_KERNEL_SHA256}" ]] ||
    die "unexpected kernel hash: ${remote_hash}"

remote_hash="$(remote "sha256sum '/boot/dtb-${KVER}/allwinner/sun50i-h618-orangepi-zero3.dtb' | cut -d' ' -f1")"
[[ "${remote_hash}" == "${EXPECTED_DTB_SHA256}" ]] ||
    die "unexpected Zero 3 device-tree hash: ${remote_hash}"

kernel_root="${work_dir}/kernel-sun50iw9-${BOARD_VERSION}"
mkdir -p "${kernel_root}"
remote "tar -C / --exclude='lib/modules/${KVER}/build' --exclude='lib/modules/${KVER}/source' -cf - \
    'boot/vmlinuz-${KVER}' 'boot/config-${KVER}' 'boot/System.map-${KVER}' \
    'boot/dtb-${KVER}' 'lib/modules/${KVER}'" |
    tar -C "${kernel_root}" -xf -
mkdir -p "${kernel_root}/usr/lib"
mv "${kernel_root}/lib/modules" "${kernel_root}/usr/lib/"
rmdir "${kernel_root}/lib"

uboot_root="${work_dir}/lumina-zero3-boot-assets-${BOARD_VERSION}"
mkdir -p "${uboot_root}"
remote "tar -C / -cf - \
    'usr/lib/linux-u-boot-next-orangepizero3_${BOARD_VERSION}_arm64/u-boot-sunxi-with-spl.bin' \
    'usr/lib/u-boot/LICENSE' 'usr/lib/u-boot/orangepi_zero3_defconfig'" |
    tar -C "${uboot_root}" -xf -

tools_root="${work_dir}/orangepi-zero3-tools-${BOARD_VERSION}"
mkdir -p "${tools_root}"
remote "tar -C / -cf - \
    'usr/sbin/orangepi-config' 'usr/sbin/softy' 'usr/bin/tv_grab_file' \
    'usr/lib/orangepi-config' 'usr/bin/orangepimonitor' 'usr/bin/memtester.sh' \
    'usr/sbin/orangepi-add-overlay' 'usr/bin/hciattach_opi'" |
    tar -C "${tools_root}" -xf -

firmware_root="${work_dir}/orangepi-zero3-firmware-${BOARD_VERSION}"
mkdir -p "${firmware_root}/usr/lib/firmware"
remote "tar -C / -cf - \
    'lib/firmware/wcnmodem.bin' 'lib/firmware/wifi_2355b001_1ant.ini' \
    'lib/firmware/bt_configure_pskey.ini' 'lib/firmware/bt_configure_rf.ini'" |
    tar -C "${firmware_root}/usr/lib/firmware" --strip-components=2 -xf -

mkdir -p "${output_dir}"
for package_root in \
    "${kernel_root}" \
    "${uboot_root}" \
    "${tools_root}" \
    "${firmware_root}"; do
    archive="${output_dir}/$(basename -- "${package_root}").tar.gz"
    tar -C "${work_dir}" --sort=name --mtime=@0 --owner=0 --group=0 \
        --numeric-owner -czf "${archive}" "$(basename -- "${package_root}")"
    sha256sum "${archive}"
done

(
    cd -- "${output_dir}"
    sha256sum ./*.tar.gz >SHA256SUMS
)
printf 'Extracted Orange Pi Zero 3 %s payloads to %s\n' \
    "${BOARD_VERSION}" "${output_dir}"
