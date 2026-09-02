#!/usr/bin/env bash

set -euo pipefail

readonly source_dir="${1:-}"
readonly output_dir="${2:-}"
readonly repo_root=/repo
readonly board_dir=/repo/orangepi/5ultra
readonly manifest="${board_dir}/tools/5ultra-mainline-source-set.sha256"

die()
{
    printf 'build-packages-in-container: %s\n' "$*" >&2
    exit 1
}

[[ -d "${source_dir}" && -d "${output_dir}" ]] ||
    die 'usage: build-packages-in-container.sh SOURCE_DIR OUTPUT_DIR'

while read -r expected_hash expected_size filename; do
    [[ -n "${filename}" ]] || continue
    source_file="${source_dir}/${filename}"
    [[ -f "${source_file}" ]] || die "missing source: ${source_file}"
    [[ "$(stat -c %s "${source_file}")" == "${expected_size}" ]] ||
        die "wrong size for ${filename}"
    [[ "$(sha256sum "${source_file}" | awk '{ print $1 }')" == "${expected_hash}" ]] ||
        die "wrong hash for ${filename}"
done <"${manifest}"

dnf -y -q install \
    arm-trusted-firmware-armv8 \
    bc \
    bison \
    dtc \
    flex \
    gcc \
    gnutls-devel \
    librsvg2-tools \
    make \
    openssl-devel \
    openssl-devel-engine \
    perl \
    python3-devel \
    python3-pyelftools \
    python3-setuptools \
    rpm-build \
    swig >/dev/null

readonly topdir="$(mktemp -d)"
cleanup()
{
    rm -rf -- "${topdir}"
}
trap cleanup EXIT
mkdir -p "${topdir}"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

cp -a "${source_dir}"/* "${topdir}/SOURCES/"
cp -a "${repo_root}/common/lumina-release/files/"* "${topdir}/SOURCES/"
cp -a "${repo_root}/common/lumina-artwork/files/"* "${topdir}/SOURCES/"
cp -a "${board_dir}/lumina-orangepi5-ultra-boot/"{extlinux.conf.in,lumina-orangepi5-ultra-boot-setup,lumina-orangepi5-ultra-dtb-setup,lumina-orangepi5-ultra-kernel-setup,95-lumina-orangepi5-ultra.install} \
    "${topdir}/SOURCES/"
cp -a "${board_dir}/orangepi5-ultra-support/"{lumina-orangepi5-ultra-grow-rootfs,lumina-orangepi5-ultra-grow-rootfs.service,80-orangepi5-ultra.preset,lumina-orangepi5-ultra-qualify} \
    "${topdir}/SOURCES/"
cp -a "${board_dir}/orangepi5-ultra-support/orangepi5-ultra-btsdio.conf" \
    "${topdir}/SOURCES/"
cp -a "${board_dir}/orangepi5-ultra-brcmfmac-dkms/"{brcmfmac-ap6611.patch,Makefile,dkms.conf} \
    "${topdir}/SOURCES/"

for spec in \
    "${repo_root}/common/lumina-release/lumina-release.spec" \
    "${repo_root}/common/lumina-artwork/lumina-artwork.spec" \
    "${board_dir}/orangepi5-ultra-firmware/orangepi5-ultra-firmware.spec" \
    "${board_dir}/orangepi5-ultra-brcmfmac-dkms/orangepi5-ultra-brcmfmac-dkms.spec" \
    "${board_dir}/orangepi5-ultra-support/orangepi5-ultra-support.spec" \
    "${board_dir}/lumina-orangepi5-ultra-boot/lumina-orangepi5-ultra-boot.spec"; do
    rpmbuild --define "_topdir ${topdir}" -bb "${spec}"
done

find "${output_dir}" -maxdepth 1 -type f \( -name '*.rpm' -o -name SHA256SUMS \) -delete
find "${topdir}/RPMS" -type f -name '*.rpm' -exec cp -a -t "${output_dir}" {} +
(
    cd -- "${output_dir}"
    sha256sum ./*.rpm >SHA256SUMS
)
