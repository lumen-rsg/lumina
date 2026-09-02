#!/usr/bin/env bash

set -euo pipefail

readonly script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly board_dir="$(cd -- "${script_dir}/.." && pwd)"
readonly repo_root="$(cd -- "${board_dir}/../.." && pwd)"
readonly source_dir="$(realpath "${1:-${repo_root}/orangepi/dist/5ultra/sources}")"
readonly output_dir="$(realpath -m "${2:-${repo_root}/orangepi/dist/5ultra/rpms}")"
readonly container_image="${FEDORA_CONTAINER_IMAGE:-registry.fedoraproject.org/fedora:44}"

die()
{
    printf 'build-packages: %s\n' "$*" >&2
    exit 1
}

command -v podman >/dev/null || die 'podman is required'
[[ -d "${source_dir}" ]] || die "source directory does not exist: ${source_dir}"
mkdir -p "${output_dir}"

"${script_dir}/fetch-sources.sh" "${source_dir}"

podman run --rm --security-opt label=disable \
    --mount "type=bind,src=${repo_root},dst=/repo,ro=true" \
    --mount "type=bind,src=${source_dir},dst=/sources,ro=true" \
    --mount "type=bind,src=${output_dir},dst=/output" \
    --env "SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-1788292800}" \
    "${container_image}" \
    /repo/orangepi/5ultra/tools/build-packages-in-container.sh /sources /output

printf 'Built Orange Pi 5 Ultra RPMs in %s\n' "${output_dir}"
