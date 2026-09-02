#!/usr/bin/env bash

set -euo pipefail

readonly test_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly board_dir="$(cd -- "${test_dir}/../.." && pwd)"
readonly repo_root="$(cd -- "${board_dir}/../.." && pwd)"
readonly boot_dir="${board_dir}/lumina-orangepi5-ultra-boot"
readonly firmware_spec="${board_dir}/orangepi5-ultra-firmware/orangepi5-ultra-firmware.spec"
readonly support_dir="${board_dir}/orangepi5-ultra-support"
readonly image_builder="${board_dir}/image/build-rootfs-in-container.sh"
readonly outer_builder="${board_dir}/image/build-image.sh"
readonly package_builder="${board_dir}/tools/build-packages.sh"
readonly package_builder_inner="${board_dir}/tools/build-packages-in-container.sh"
readonly source_fetcher="${board_dir}/tools/fetch-sources.sh"
readonly source_manifest="${board_dir}/tools/5ultra-mainline-source-set.sha256"

fail()
{
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

for script in \
    "${boot_dir}/95-lumina-orangepi5-ultra.install" \
    "${boot_dir}/lumina-orangepi5-ultra-boot-setup" \
    "${boot_dir}/lumina-orangepi5-ultra-dtb-setup" \
    "${support_dir}/lumina-orangepi5-ultra-grow-rootfs" \
    "${support_dir}/lumina-orangepi5-ultra-qualify" \
    "${image_builder}" \
    "${outer_builder}" \
    "${package_builder}" \
    "${package_builder_inner}" \
    "${source_fetcher}"; do
    bash -n "${script}" || fail "shell syntax: ${script}"
done

grep -Fq 'https://ftp.denx.de/pub/u-boot/' \
    "${boot_dir}/lumina-orangepi5-ultra-boot.spec" ||
    fail 'boot RPM is not built from upstream U-Boot source'
grep -Fq 'arm-trusted-firmware-armv8' \
    "${boot_dir}/lumina-orangepi5-ultra-boot.spec" ||
    fail 'boot RPM does not use Fedora Trusted Firmware-A'
grep -Fq 'orangepi-5-ultra-rk3588_defconfig' \
    "${boot_dir}/lumina-orangepi5-ultra-boot.spec" ||
    fail 'upstream Orange Pi 5 Ultra U-Boot defconfig is missing'
if rg -i '^(Source|BuildRequires|Requires|Recommends):.*armbian' \
    "${boot_dir}/lumina-orangepi5-ultra-boot.spec" >/dev/null ||
   rg -i '(curl|dnf|install|mount).*[[:space:]/]armbian' \
       "${image_builder}" "${package_builder}" >/dev/null; then
    fail 'an Armbian dependency leaked into the mainline boot or image build'
fi

grep -Fqx '    FDT /boot/lumina/rk3588-orangepi-5-ultra-@KERNEL@.dtb' \
    "${boot_dir}/extlinux.conf.in" || fail 'mainline Orange Pi 5 Ultra DTB is not selected'
grep -Fq 'lsm=lockdown,yama,integrity,selinux' "${boot_dir}/extlinux.conf.in" ||
    fail 'SELinux LSM boot arguments are missing'
grep -Fq '/mmc@fe2d0000/wifi@1 compatible' \
    "${boot_dir}/lumina-orangepi5-ultra-dtb-setup" ||
    fail 'mainline brcmfmac DTB generation is missing'
grep -Fq 'reset-gpios' "${boot_dir}/lumina-orangepi5-ultra-dtb-setup" ||
    fail 'AP6611 reset wiring is missing'

for firmware in \
    brcmfmac43752-sdio.bin \
    brcmfmac43752-sdio.clm_blob \
    'brcmfmac43752-sdio.xunlong,orangepi-5-ultra.txt' \
    SYN43711A0.hcd; do
    grep -Fq "${firmware}" "${firmware_spec}" || fail "firmware mapping is missing: ${firmware}"
done

for package in kernel kernel-modules kernel-modules-extra; do
    grep -Eq "^[[:space:]]+${package}$" "${image_builder}" ||
        fail "Fedora mainline kernel package is missing: ${package}"
done
for config in CONFIG_BRCMFMAC=m CONFIG_DRM_ACCEL_ROCKET=m CONFIG_DRM_PANTHOR=m CONFIG_R8169=m; do
    grep -Fq "${config}" "${image_builder}" || fail "image gate is missing: ${config}"
done
grep -Fq 'partition_start=32768' "${image_builder}" ||
    fail 'root partition does not preserve the RK3588 boot area'
grep -Fq 'bs=512 seek=64' "${image_builder}" ||
    fail 'U-Boot is not written at the mainline RK3588 32 KiB offset'
grep -Fq "printf 'label: gpt" "${image_builder}" || fail 'Orange Pi image is not GPT'
grep -Fq 'lumina-orangepi5-ultra-dtb-setup' "${image_builder}" ||
    fail 'image build does not generate the AP6611-enabled DTB'
grep -Fq -- '--add selinux' "${image_builder}" || fail 'SELinux is missing from initramfs'
grep -Fq 'SELINUX=enforcing' "${image_builder}" || fail 'mainline image is not enforcing'
grep -Fq '@gnome-desktop' "${image_builder}" || fail 'workstation profile does not install GNOME'
grep -Fq 'default_target=graphical.target' "${image_builder}" ||
    fail 'workstation profile does not boot graphically'

grep -Fq '/dev/mmcblk*|/dev/nvme*' "${support_dir}/lumina-orangepi5-ultra-grow-rootfs" ||
    fail 'root growth does not cover SD/eMMC and NVMe installs'
for runtime_gate in panthor rocket r8169 brcmfmac; do
    grep -Fq "${runtime_gate}" "${support_dir}/lumina-orangepi5-ultra-qualify" ||
        fail "runtime qualification misses ${runtime_gate}"
done

while read -r expected_hash expected_size filename; do
    [[ "${expected_hash}" =~ ^[0-9a-f]{64}$ ]] || fail "invalid source hash: ${filename}"
    [[ "${expected_size}" =~ ^[1-9][0-9]*$ ]] || fail "invalid source size: ${filename}"
done <"${source_manifest}"

grep -Fq 'lumina-orangepi5-ultra-boot:' "${repo_root}/.lumina/packages.yaml" ||
    fail 'boot RPM is absent from the package pipeline'
grep -Fq 'orangepi5-ultra-firmware:' "${repo_root}/.lumina/packages.yaml" ||
    fail 'firmware RPM is absent from the package pipeline'
grep -Fq 'orangepi5-ultra-support:' "${repo_root}/.lumina/packages.yaml" ||
    fail 'support RPM is absent from the package pipeline'

echo 'PASS: Orange Pi 5 Ultra mainline image and package contracts'
