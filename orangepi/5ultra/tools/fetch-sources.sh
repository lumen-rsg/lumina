#!/usr/bin/env bash

set -euo pipefail

readonly script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly board_dir="$(cd -- "${script_dir}/.." && pwd)"
readonly repo_root="$(cd -- "${board_dir}/../.." && pwd)"
readonly output_dir="${1:-${repo_root}/orangepi/dist/5ultra/sources}"
readonly manifest="${script_dir}/5ultra-mainline-source-set.sha256"
readonly rkbin_commit=3e288fe814e059dd06833495f845cab04ac20a5c
readonly firmware_commit=db5e86200ae592c467c4cfa50ec0c66cbc40b158

die()
{
    printf 'fetch-sources: %s\n' "$*" >&2
    exit 1
}

source_url()
{
    case "$1" in
        u-boot-2026.07.tar.bz2)
            printf '%s\n' 'https://ftp.denx.de/pub/u-boot/u-boot-2026.07.tar.bz2'
            ;;
        linux-7.1.12.tar.xz)
            printf '%s\n' 'https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.1.12.tar.xz'
            ;;
        rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.24.bin)
            printf 'https://raw.githubusercontent.com/rockchip-linux/rkbin/%s/bin/rk35/%s\n' \
                "${rkbin_commit}" "$1"
            ;;
        fw_syn43711a0_sdio.bin|clm_syn43711a0.blob|nvram_ap6611s.txt-orangepi5ultra|SYN43711A0.hcd)
            printf 'https://raw.githubusercontent.com/orangepi-xunlong/firmware/%s/%s\n' \
                "${firmware_commit}" "$1"
            ;;
        *)
            die "no URL for $1"
            ;;
    esac
}

verify_file()
{
    local path="$1"
    local expected_hash="$2"
    local expected_size="$3"
    local actual_hash

    [[ -f "${path}" ]] || return 1
    [[ "$(stat -c %s "${path}")" == "${expected_size}" ]] || return 1
    actual_hash="$(sha256sum "${path}" | awk '{ print $1 }')"
    [[ "${actual_hash}" == "${expected_hash}" ]]
}

for command in curl sha256sum stat; do
    command -v "${command}" >/dev/null || die "missing command: ${command}"
done
mkdir -p "${output_dir}"

while read -r expected_hash expected_size filename; do
    [[ -n "${filename}" ]] || continue
    destination="${output_dir}/${filename}"
    if verify_file "${destination}" "${expected_hash}" "${expected_size}"; then
        printf 'Verified %s\n' "${filename}"
        continue
    fi

    partial="$(mktemp "${output_dir}/.${filename}.XXXXXX")"
    trap 'rm -f -- "${partial}"' EXIT
    curl --fail --location --retry 3 --output "${partial}" "$(source_url "${filename}")"
    verify_file "${partial}" "${expected_hash}" "${expected_size}" ||
        die "downloaded source failed verification: ${filename}"
    mv -f -- "${partial}" "${destination}"
    trap - EXIT
    printf 'Downloaded %s\n' "${filename}"
done <"${manifest}"

printf 'Verified Orange Pi 5 Ultra source set in %s\n' "${output_dir}"
