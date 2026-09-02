#!/usr/bin/env bash

set -euo pipefail

readonly script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly zero3_dir="$(cd -- "${script_dir}/.." && pwd)"
readonly repo_root="$(cd -- "${zero3_dir}/../.." && pwd)"
readonly payload_dir="${1:-${repo_root}/orangepi/dist/zero3/1.0.6}"
readonly output_dir="${2:-${repo_root}/orangepi/dist/zero3/rpms}"
readonly source_manifest="${script_dir}/zero3-1.0.6-source-set.sha256"
export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-1788292800}"

die()
{
    printf 'build-packages: %s\n' "$*" >&2
    exit 1
}

for command in cp rpmbuild sha256sum; do
    command -v "${command}" >/dev/null || die "missing command: ${command}"
done

while read -r expected size filename; do
    [[ -n "${filename}" ]] || continue
    source_file="${payload_dir}/${filename}"
    [[ -f "${source_file}" ]] || die "missing payload: ${source_file}"
    actual_size="$(stat -c %s "${source_file}")"
    [[ "${actual_size}" == "${size}" ]] || die "wrong size for ${filename}"
    actual_hash="$(sha256sum "${source_file}" | awk '{ print $1 }')"
    [[ "${actual_hash}" == "${expected}" ]] || die "wrong hash for ${filename}"
done <"${source_manifest}"

readonly topdir="$(mktemp -d)"
cleanup()
{
    rm -rf -- "${topdir}"
}
trap cleanup EXIT
mkdir -p "${topdir}"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

cp -a "${payload_dir}"/*.tar.gz "${topdir}/SOURCES/"
cp -a "${zero3_dir}/lumina-zero3-boot/boot.cmd" \
    "${zero3_dir}/lumina-zero3-boot/orangepiEnv.txt" \
    "${zero3_dir}/lumina-zero3-boot/lumina-zero3-boot-setup" \
    "${topdir}/SOURCES/"
cp -a "${zero3_dir}/orangepi-zero3-tools/orangepi-config" \
    "${zero3_dir}/orangepi-zero3-tools/orangepimonitor" \
    "${zero3_dir}/orangepi-zero3-tools/orangepi-release" \
    "${zero3_dir}/orangepi-zero3-tools/orangepi-zero3-bluetooth.service" \
    "${zero3_dir}/orangepi-zero3-tools/orangepi-zero3-wifi.service" \
    "${zero3_dir}/orangepi-zero3-tools/86-orangepi-zero3.preset" \
    "${zero3_dir}/orangepi-zero3-tools/orangepi-zero3-wait-wifi" \
    "${zero3_dir}/orangepi-zero3-tools/orangepi-zero3-wait-bluetooth" \
    "${zero3_dir}/orangepi-zero3-tools/orangepi-zero3-networkmanager.conf" \
    "${topdir}/SOURCES/"
cp -a "${repo_root}/common/lumina-release/files/"* "${topdir}/SOURCES/"

for spec in \
    "${repo_root}/common/lumina-release/lumina-release.spec" \
    "${zero3_dir}/orangepi-zero3-firmware/orangepi-zero3-firmware.spec" \
    "${zero3_dir}/lumina-zero3-boot/lumina-zero3-boot.spec" \
    "${zero3_dir}/orangepi-zero3-tools/orangepi-zero3-tools.spec" \
    "${zero3_dir}/kernel-sun50iw9/kernel-sun50iw9.spec"; do
    rpmbuild --define "_topdir ${topdir}" -bb "${spec}"
done

mkdir -p "${output_dir}"
find "${output_dir}" -maxdepth 1 -type f \( \
    -name 'kernel-sun50iw9-*.rpm' -o \
    -name 'lumina-release-*.rpm' -o \
    -name 'lumina-zero3-boot-*.rpm' -o \
    -name 'orangepi-zero3-firmware-*.rpm' -o \
    -name 'orangepi-zero3-tools-*.rpm' -o \
    -name 'SHA256SUMS' \
    \) -delete
find "${topdir}/RPMS" -type f -name '*.rpm' -exec cp -a -t "${output_dir}" {} +
(
    cd -- "${output_dir}"
    sha256sum ./*.rpm >SHA256SUMS
)
printf 'Built Zero 3 RPMs in %s\n' "${output_dir}"
