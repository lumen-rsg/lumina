#!/usr/bin/env bash
#
# Build RPM source archives from the exact public NVIDIA Debian packages
# installed on a reference L4T R39 Jetson.

set -euo pipefail

readonly TARGET="${1:-cv2@192.168.1.22}"
readonly L4T_VERSION="${L4T_VERSION:-39.2.1}"
readonly OUTPUT_DIR="${OUTPUT_DIR:-$(pwd)/jetson/dist/l4t-r${L4T_VERSION}}"

declare -Ar BUNDLES=(
    [kernel-tegra-l4t]="
        nvidia-l4t-kernel
        nvidia-l4t-kernel-dtbs
        nvidia-l4t-kernel-module-configs
        nvidia-l4t-kernel-nvgpu
        nvidia-l4t-kernel-openrm
        nvidia-l4t-kernel-oot-modules
        nvidia-l4t-display-kernel
    "
    [tegra-l4t-firmware]="
        nvidia-l4t-firmware
        nvidia-l4t-firmware-nvgpu
        nvidia-l4t-firmware-openrm
    "
    [nvidia-l4t-driver]="
        nvidia-l4t-core
        nvidia-l4t-configs
        nvidia-l4t-init
        nvidia-l4t-init-openrm
        nvidia-l4t-3d-core
        nvidia-l4t-cuda
        nvidia-l4t-cuda-nvgpu
        nvidia-l4t-cuda-openrm
        nvidia-l4t-cuda-utils
        nvidia-l4t-gbm
        nvidia-l4t-libvulkan
        nvidia-l4t-nvml
        nvidia-l4t-wayland
        nvidia-l4t-x11
    "
    [nvidia-l4t-multimedia]="
        nvidia-l4t-adaruntime
        nvidia-l4t-camera
        nvidia-l4t-gstreamer
        nvidia-l4t-multimedia
        nvidia-l4t-multimedia-nvgpu
        nvidia-l4t-multimedia-openrm
        nvidia-l4t-multimedia-utils
        nvidia-l4t-nvsci
        nvidia-l4t-openwfd
        nvidia-l4t-pva
        nvidia-l4t-video-codec-openrm
    "
    [nvidia-l4t-tools]="
        nvidia-l4t-jetson-io
        nvidia-l4t-nvfancontrol
        nvidia-l4t-nvpmodel
        nvidia-l4t-optee
        nvidia-l4t-tools
    "
)

mkdir -p "${OUTPUT_DIR}"
local_work="$(mktemp -d /tmp/lumina-l4t-r39.XXXXXX)"
remote_work=""

cleanup() {
    rm -rf "${local_work}"
    if [[ -n "${remote_work}" ]]; then
        ssh "${TARGET}" rm -rf -- "${remote_work}" 2>/dev/null || true
    fi
}
trap cleanup EXIT

release="$(ssh "${TARGET}" "sed -n 's/^# R\\([0-9]*\\).*REVISION: \\([0-9.]*\\).*/\\1.\\2/p' /etc/nv_tegra_release")"
if [[ "${release}" != "${L4T_VERSION}" ]]; then
    echo "Expected L4T ${L4T_VERSION}, but ${TARGET} reports ${release:-unknown}." >&2
    exit 1
fi

remote_work="$(ssh "${TARGET}" mktemp -d /tmp/lumina-l4t-r39.XXXXXX)"

for bundle in kernel-tegra-l4t tegra-l4t-firmware nvidia-l4t-driver nvidia-l4t-multimedia nvidia-l4t-tools; do
    echo "Creating ${bundle}-${L4T_VERSION}.tar.gz"
    mapfile -t packages < <(
        awk '{ for (field = 1; field <= NF; field++) print $field }' \
            <<<"${BUNDLES[${bundle}]}"
    )

    ssh "${TARGET}" bash -s -- \
        "${remote_work}" "${bundle}" "${L4T_VERSION}" "${packages[@]}" <<'REMOTE'
set -euo pipefail
work="$1"
bundle="$2"
version="$3"
shift 3

bundle_dir="${work}/${bundle}"
rm -rf "${bundle_dir}"
mkdir -p "${bundle_dir}/debs" "${bundle_dir}/root"
cd "${bundle_dir}/debs"

for package in "$@"; do
    installed_version="$(dpkg-query -W -f='${Version}' "${package}")"
    apt-get download "${package}=${installed_version}" >/dev/null
done

for deb in ./*.deb; do
    package_name="$(dpkg-deb -f "${deb}" Package)"
    if [[ "${package_name}" != "nvidia-l4t-configs" ]]; then
        dpkg-deb --extract "${deb}" "${bundle_dir}/root"
        continue
    fi

    # nvidia-l4t-configs also carries Ubuntu-specific desktop, APT, PAM,
    # NetworkManager, DNS, and first-boot policy. Those must not replace
    # Lumina's distro policy. Select only hardware configuration needed by the
    # NVIDIA kernel and userspace, keeping each selected file byte-for-byte.
    configs_root="${bundle_dir}/configs-root"
    dpkg-deb --extract "${deb}" "${configs_root}"
    (
        cd "${configs_root}"
        for path in \
            etc/asound.conf \
            etc/asound.conf.tegra-ape \
            etc/asound.conf.tegra-hda-jetson-agx \
            etc/asound.conf.tegra-hda-jetson-xnx \
            etc/modprobe.d/nvgpu.conf \
            etc/modules-load.d/nvidia-oot.conf \
            etc/sysctl.d/90-tegra-settings.conf \
            etc/udev/rules.d/99-tegra-devices.rules \
            etc/udev/rules.d/99-tegra-mmc-ra.rules \
            usr/share/doc/nvidia-l4t-configs; do
            if [[ -e "${path}" ]]; then
                cp -a --parents "${path}" "${bundle_dir}/root/"
            fi
        done
    )
    rm -rf "${configs_root}"
done

# Fedora and Lumina use a merged /usr. Normalize Debian's legacy /lib payload
# without changing any file contents.
if [[ -d "${bundle_dir}/root/lib" && ! -L "${bundle_dir}/root/lib" ]]; then
    mkdir -p "${bundle_dir}/root/usr/lib"
    cp -a "${bundle_dir}/root/lib/." "${bundle_dir}/root/usr/lib/"
    rm -rf "${bundle_dir}/root/lib"
fi

{
    echo "L4T ${version} source Debian packages:"
    for deb in ./*.deb; do
        package="$(dpkg-deb -f "${deb}" Package)"
        package_version="$(dpkg-deb -f "${deb}" Version)"
        sha256="$(sha256sum "${deb}" | cut -d' ' -f1)"
        printf '%s %s sha256:%s\n' "${package}" "${package_version}" "${sha256}"
    done
} >"${bundle_dir}/SOURCE-PACKAGES"

mkdir -p "${bundle_dir}/root/usr/share/doc/lumina/${bundle}"
mv "${bundle_dir}/SOURCE-PACKAGES" \
    "${bundle_dir}/root/usr/share/doc/lumina/${bundle}/SOURCE-PACKAGES"

tar --sort=name --mtime="@0" --owner=0 --group=0 --numeric-owner \
    -C "${bundle_dir}/root" -czf "${bundle_dir}/${bundle}-${version}.tar.gz" .
REMOTE

    scp -q "${TARGET}:${remote_work}/${bundle}/${bundle}-${L4T_VERSION}.tar.gz" \
        "${OUTPUT_DIR}/"
    sha256sum "${OUTPUT_DIR}/${bundle}-${L4T_VERSION}.tar.gz"
done

echo "Creating lumina-jetson-boot-assets-${L4T_VERSION}.tar.gz"
ssh "${TARGET}" bash -s -- "${remote_work}" "${L4T_VERSION}" <<'REMOTE'
set -euo pipefail
work="$1"
version="$2"
bundle="lumina-jetson-boot-assets-${version}"
bundle_dir="${work}/${bundle}"
debs_dir="${work}/bootloader-debs"

rm -rf "${bundle_dir}" "${debs_dir}"
mkdir -p "${bundle_dir}" "${debs_dir}"
cd "${debs_dir}"

installed_version="$(dpkg-query -W -f='${Version}' nvidia-l4t-bootloader)"
apt-get download "nvidia-l4t-bootloader=${installed_version}" >/dev/null
bootloader_deb="$(find . -maxdepth 1 -type f -name 'nvidia-l4t-bootloader_*.deb' -print -quit)"
[[ -n "${bootloader_deb}" ]]
dpkg-deb --fsys-tarfile "${bootloader_deb}" |
    tar -x -C "${bundle_dir}" \
        ./opt/ota_package/t23x/BOOTAA64.efi \
        ./usr/share/doc/nvidia-l4t-bootloader/copyright
mv "${bundle_dir}/opt/ota_package/t23x/BOOTAA64.efi" \
    "${bundle_dir}/BOOTAA64.efi"
mv "${bundle_dir}/usr/share/doc/nvidia-l4t-bootloader/copyright" \
    "${bundle_dir}/copyright"
rm -rf "${bundle_dir}/opt" "${bundle_dir}/usr"

tar --sort=name --mtime="@0" --owner=0 --group=0 --numeric-owner \
    -C "${work}" -czf "${work}/${bundle}.tar.gz" "${bundle}"
REMOTE

scp -q \
    "${TARGET}:${remote_work}/lumina-jetson-boot-assets-${L4T_VERSION}.tar.gz" \
    "${OUTPUT_DIR}/"
sha256sum \
    "${OUTPUT_DIR}/lumina-jetson-boot-assets-${L4T_VERSION}.tar.gz"

echo "Source archives are ready in ${OUTPUT_DIR}"
