#!/usr/bin/env bash

set -euo pipefail

readonly L4T_VERSION="${L4T_VERSION:-39.2.1}"
readonly EXPECTED_LAUNCHER_SHA256="${EXPECTED_LAUNCHER_SHA256:-a848c03d3990b9d79c17e0d125e2f5eb149e85c1045388b37161baf05a603c7e}"
readonly ISO="${1:-}"
readonly REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly OUTPUT="${OUTPUT:-${REPO_ROOT}/jetson/dist/l4t-r${L4T_VERSION}/lumina-jetson-boot-assets-${L4T_VERSION}.tar.gz}"

if [[ -z "${ISO}" || ! -f "${ISO}" ]]; then
    echo "Usage: ${0##*/} /path/to/jetsoninstaller-r${L4T_VERSION}-*.iso" >&2
    exit 2
fi

for command in 7z tar sha256sum; do
    command -v "${command}" >/dev/null ||
        { echo "Missing required command: ${command}" >&2; exit 1; }
done

work_dir="$(mktemp -d)"
trap 'rm -rf -- "${work_dir}"' EXIT

deb_path="$(
    7z l -ba "${ISO}" |
        awk -v needle="nvidia-l4t-bootloader_${L4T_VERSION}-" '
            index($NF, needle) && $NF ~ /_arm64\.deb$/ { path=$NF }
            END { print path }
        '
)"
[[ -n "${deb_path}" ]] ||
    { echo "The ISO does not contain the L4T R${L4T_VERSION} bootloader package." >&2; exit 1; }

7z x -y -o"${work_dir}/iso" "${ISO}" "${deb_path}" >/dev/null
deb="${work_dir}/iso/${deb_path}"
mkdir -p "${work_dir}/deb"
7z x -y -o"${work_dir}/deb" "${deb}" >/dev/null

data_archive="$(find "${work_dir}/deb" -maxdepth 1 -name 'data.tar*' -print -quit)"
[[ -n "${data_archive}" ]] || { echo "No data archive in ${deb}." >&2; exit 1; }

package_root="${work_dir}/lumina-jetson-boot-assets-${L4T_VERSION}"
mkdir -p "${package_root}"
tar -xf "${data_archive}" -C "${work_dir}" \
    ./opt/ota_package/t23x/BOOTAA64.efi \
    ./usr/share/doc/nvidia-l4t-bootloader/copyright
install -m 0644 "${work_dir}/opt/ota_package/t23x/BOOTAA64.efi" \
    "${package_root}/BOOTAA64.efi"
install -m 0644 "${work_dir}/usr/share/doc/nvidia-l4t-bootloader/copyright" \
    "${package_root}/copyright"

actual_sha256="$(sha256sum "${package_root}/BOOTAA64.efi" | awk '{print $1}')"
[[ "${actual_sha256}" == "${EXPECTED_LAUNCHER_SHA256}" ]] || {
    echo "Unexpected BOOTAA64.efi hash: ${actual_sha256}" >&2
    exit 1
}

mkdir -p "$(dirname -- "${OUTPUT}")"
tar -C "${work_dir}" --sort=name --mtime=@0 --owner=0 --group=0 \
    --numeric-owner -czf "${OUTPUT}" "lumina-jetson-boot-assets-${L4T_VERSION}"
echo "Wrote ${OUTPUT}"
