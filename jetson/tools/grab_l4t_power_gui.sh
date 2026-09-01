#!/usr/bin/bash
# Build the L4T R39.2.1 power GUI RPM source archive from NVIDIA packages.

set -euo pipefail

readonly l4t_version="39.2.1"
readonly repository="https://repo.download.nvidia.com/jetson/som"
readonly output_dir="${OUTPUT_DIR:-$(pwd)/jetson/dist/l4t-r${l4t_version}}"
readonly cache_dir="${L4T_CACHE_DIR:-${HOME}/.cache/lumina-l4t-r${l4t_version}}"
readonly work_dir="$(mktemp -d /tmp/lumina-l4t-power-gui.XXXXXX)"
readonly root_dir="${work_dir}/root"

cleanup()
{
    rm -rf -- "${work_dir}"
}
trap cleanup EXIT

die()
{
    printf 'grab-l4t-power-gui: %s\n' "$*" >&2
    exit 1
}

for command in ar curl sha256sum tar; do
    command -v "${command}" >/dev/null ||
        die "missing required command: ${command}"
done
mkdir -p "${output_dir}" "${cache_dir}" "${root_dir}"

declare -ar packages=(
    'nvidia-l4t-jetsonpower-gui-tools|39.2.1-20260806224157|pool/main/n/nvidia-l4t-jetsonpower-gui-tools/nvidia-l4t-jetsonpower-gui-tools_39.2.1-20260806224157_arm64.deb|89a376e49aa4d17e037e765f87d28acf623b15298444e18ae4f5d409f3574ada'
    'nvidia-l4t-nvpmodel-gui-tools|39.2.1-20260806224157|pool/main/n/nvidia-l4t-nvpmodel-gui-tools/nvidia-l4t-nvpmodel-gui-tools_39.2.1-20260806224157_arm64.deb|64c7442545cd99464030a0502b27e6d84fd9e212d6b60ea9d88b8a5a00fbe67d'
)

source_manifest="${work_dir}/SOURCE-PACKAGES"
for entry in "${packages[@]}"; do
    IFS='|' read -r package version filename checksum <<<"${entry}"
    deb_file="${cache_dir}/$(basename -- "${filename}")"
    if [[ ! -f "${deb_file}" ]]; then
        curl --fail --location --retry 3 \
            "${repository}/${filename}" -o "${deb_file}"
    fi
    printf '%s  %s\n' "${checksum}" "${deb_file}" |
        sha256sum --check --status ||
        die "checksum mismatch for ${deb_file}"

    data_member="$(ar t "${deb_file}" | awk '/^data\.tar/ { print; exit }')"
    case "${data_member}" in
        *.xz) ar p "${deb_file}" "${data_member}" | tar -Jx -C "${root_dir}" ;;
        *.zst) ar p "${deb_file}" "${data_member}" | tar --zstd -x -C "${root_dir}" ;;
        *.gz) ar p "${deb_file}" "${data_member}" | tar -zx -C "${root_dir}" ;;
        *.tar) ar p "${deb_file}" "${data_member}" | tar -x -C "${root_dir}" ;;
        *) die "unsupported Debian data archive in ${deb_file}" ;;
    esac
    printf '%s %s sha256:%s\n' "${package}" "${version}" "${checksum}" \
        >>"${source_manifest}"
done

doc_dir="${root_dir}/usr/share/doc/lumina/nvidia-l4t-power-gui"
mkdir -p "${doc_dir}"
mv "${source_manifest}" "${doc_dir}/SOURCE-PACKAGES"

archive="${output_dir}/nvidia-l4t-power-gui-${l4t_version}.tar.gz"
tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
    -C "${root_dir}" -czf "${archive}" .
sha256sum "${archive}"
