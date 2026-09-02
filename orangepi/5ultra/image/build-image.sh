#!/usr/bin/env bash

set -euo pipefail

readonly script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly board_dir="$(cd -- "${script_dir}/.." && pwd)"
readonly repo_root="$(cd -- "${board_dir}/../.." && pwd)"
readonly rpm_dir="$(realpath "${1:-${repo_root}/orangepi/dist/5ultra/rpms}")"
readonly requested_output="${2:-${repo_root}/orangepi/dist/5ultra/Lumina-26.08-OrangePi-5-Ultra-mainline-dkms-aarch64.raw.zst}"
readonly image_size="${3:-auto}"
readonly profile="${4:-workstation}"
readonly output_dir="$(realpath -m "$(dirname -- "${requested_output}")")"
readonly output_name="$(basename -- "${requested_output}")"
readonly container_image="${FEDORA_CONTAINER_IMAGE:-registry.fedoraproject.org/fedora:44}"

die()
{
    printf 'build-image: %s\n' "$*" >&2
    exit 1
}

command -v podman >/dev/null || die 'podman is required'
[[ -d "${rpm_dir}" ]] || die "RPM directory does not exist: ${rpm_dir}"
[[ "${output_name}" == *.raw.zst ]] || die 'output name must end in .raw.zst'
[[ "${image_size}" == auto || "${image_size}" =~ ^[1-9][0-9]*[MmGg]?$ ]] ||
    die 'image size must be auto, a GiB integer, or an integer with M/G suffix'
[[ "${profile}" == workstation || "${profile}" == server ]] ||
    die 'profile must be workstation or server'
[[ ! -e "${output_dir}/${output_name}" ]] || die 'output already exists'
mkdir -p "${output_dir}"

podman run --rm --security-opt label=disable \
    --mount "type=bind,src=${rpm_dir},dst=/rpms,ro=true" \
    --mount "type=bind,src=${script_dir},dst=/image,ro=true" \
    --mount "type=bind,src=${output_dir},dst=/output" \
    --env "SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-1788292800}" \
    "${container_image}" \
    /image/build-rootfs-in-container.sh \
        /rpms "/output/${output_name}" "${image_size}" "${profile}"

printf 'Flash with: zstdcat %q | sudo dd of=/dev/SDX bs=4M oflag=direct status=progress conv=fsync\n' \
    "${output_dir}/${output_name}"
