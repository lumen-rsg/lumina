#!/usr/bin/bash
# Build reproducible CUDA 13.2 RPM source archives from NVIDIA's Jetson repo.

set -euo pipefail

readonly script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly manifest="${CUDA_MANIFEST:-${script_dir}/cuda-13.2.packages}"
readonly repository="${CUDA_REPOSITORY:-https://repo.download.nvidia.com/jetson/common}"
readonly output_dir="${OUTPUT_DIR:-$(pwd)/jetson/dist/cuda-13.2}"
readonly cache_dir="${CUDA_CACHE_DIR:-${HOME}/.cache/lumina-cuda-13.2}"
readonly archive_version="13.2.2"
readonly work_parent="${CUDA_WORK_DIR_PARENT:-${output_dir}}"

mkdir -p "${output_dir}" "${cache_dir}" "${work_parent}"
readonly work_dir="$(mktemp -d "${work_parent}/.lumina-cuda-13.2.XXXXXX")"

cleanup()
{
    rm -rf -- "${work_dir}"
}
trap cleanup EXIT

die()
{
    printf 'grab-cuda: %s\n' "$*" >&2
    exit 1
}

for command in ar curl sha256sum tar; do
    command -v "${command}" >/dev/null ||
        die "missing required command: ${command}"
done
[[ -f "${manifest}" ]] || die "manifest does not exist: ${manifest}"

extract_deb_data()
{
    local deb_file="$1"
    local destination="$2"
    local data_member

    data_member="$(ar t "${deb_file}" | awk '/^data\.tar/ { print; exit }')"
    [[ -n "${data_member}" ]] || die "${deb_file} has no data archive"
    case "${data_member}" in
        *.xz)
            ar p "${deb_file}" "${data_member}" |
                tar -Jx -C "${destination}"
            ;;
        *.zst)
            ar p "${deb_file}" "${data_member}" |
                tar --zstd -x -C "${destination}"
            ;;
        *.gz)
            ar p "${deb_file}" "${data_member}" |
                tar -zx -C "${destination}"
            ;;
        *.tar)
            ar p "${deb_file}" "${data_member}" |
                tar -x -C "${destination}"
            ;;
        *)
            die "unsupported Debian data archive: ${data_member}"
            ;;
    esac
}

for bundle in runtime toolkit; do
    bundle_root="${work_dir}/${bundle}/root"
    mkdir -p "${bundle_root}"

    while IFS='|' read -r entry_bundle package version filename checksum; do
        [[ -n "${entry_bundle}" && "${entry_bundle}" != \#* ]] || continue
        [[ "${entry_bundle}" == "${bundle}" ]] || continue

        deb_file="${cache_dir}/$(basename -- "${filename}")"
        if [[ ! -f "${deb_file}" ]]; then
            printf 'Downloading %s %s\n' "${package}" "${version}"
            curl --fail --location --retry 3 \
                "${repository}/${filename}" -o "${deb_file}"
        fi
        printf '%s  %s\n' "${checksum}" "${deb_file}" |
            sha256sum --check --status ||
            die "checksum mismatch for ${deb_file}"
        extract_deb_data "${deb_file}" "${bundle_root}"
    done <"${manifest}"

    if [[ "${bundle}" == runtime ]]; then
        [[ -d "${bundle_root}/usr/local/cuda-13.2" ]] ||
            die "CUDA runtime payload did not create /usr/local/cuda-13.2"
        ln -s cuda-13.2 "${bundle_root}/usr/local/cuda"
        ln -s cuda-13.2 "${bundle_root}/usr/local/cuda-13"
    fi

    doc_dir="${bundle_root}/usr/share/doc/lumina/nvidia-cuda-${bundle}"
    mkdir -p "${doc_dir}"
    awk -F'|' -v selected="${bundle}" \
        '$1 == selected { printf "%s %s sha256:%s\n", $2, $3, $5 }' \
        "${manifest}" >"${doc_dir}/SOURCE-PACKAGES"

    archive="${output_dir}/nvidia-cuda-${bundle}-${archive_version}.tar.gz"
    tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
        -C "${bundle_root}" -czf "${archive}" .
    sha256sum "${archive}"
done

printf 'CUDA source archives are ready in %s\n' "${output_dir}"
