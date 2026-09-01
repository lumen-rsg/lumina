#!/usr/bin/bash
#
# Build an offline 1T Lumina installer ISO for NVIDIA Jetson Orin.
#
# Usage:
#   build-iso.sh BASE_ISO FEDORA_RPM_ROOT COMPS_XML OUTPUT_ISO
#
# FEDORA_RPM_ROOT is searched recursively. COMPS_XML may be plain XML or zstd
# compressed. Binary Lumina RPMs are taken from jetson/dist/l4t-r39.2.1/RPMS.

set -euo pipefail

readonly volume_id="Lumina-26-08-aarch64"
readonly script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly jetson_dir="$(cd -- "${script_dir}/.." && pwd)"

die()
{
    printf 'build-iso: %s\n' "$*" >&2
    exit 1
}

[[ $# -eq 4 ]] ||
    die "usage: $0 BASE_ISO FEDORA_RPM_ROOT COMPS_XML OUTPUT_ISO"

readonly base_iso="$(realpath "$1")"
readonly fedora_rpm_root="$(realpath "$2")"
readonly comps_xml="$(realpath "$3")"
readonly output_iso="$(realpath -m "$4")"
readonly build_epoch="${SOURCE_DATE_EPOCH:-$(date -u +%s)}"
readonly work_dir="$(mktemp -d)"
readonly iso_tree="${work_dir}/iso-tree"
readonly package_dir="${iso_tree}/LuminaPackages/Packages"
readonly tegra_kernel_rpm="$(
    find "${jetson_dir}/dist/l4t-r39.2.1/RPMS" -type f \
        -name 'kernel-tegra-l4t-*.rpm' -print -quit
)"

cleanup()
{
    rm -rf -- "${work_dir}"
}
trap cleanup EXIT

for command in cmp createrepo_c date mcopy realpath rpm sha256sum xorriso; do
    command -v "${command}" >/dev/null ||
        die "missing required command: ${command}"
done

[[ "${build_epoch}" =~ ^[0-9]+$ ]] ||
    die "SOURCE_DATE_EPOCH must be an integer Unix timestamp"

[[ -f "${base_iso}" ]] || die "base ISO does not exist: ${base_iso}"
[[ -d "${fedora_rpm_root}" ]] ||
    die "Fedora RPM root does not exist: ${fedora_rpm_root}"
[[ -f "${comps_xml}" ]] || die "comps file does not exist: ${comps_xml}"
[[ -n "${tegra_kernel_rpm}" ]] ||
    die "kernel-tegra-l4t RPM was not built"

mkdir -p "${iso_tree}" "${package_dir}" "$(dirname -- "${output_iso}")"
xorriso -osirrox on -indev "${base_iso}" -extract / "${iso_tree}"

copy_rpm()
{
    local source="$1"
    local destination="${package_dir}/$(basename -- "${source}")"

    if [[ -e "${destination}" ]]; then
        cmp --silent "${source}" "${destination}" ||
            die "different RPMs have the same filename: $(basename -- "${source}")"
        return
    fi
    cp -a "${source}" "${destination}"
}

while IFS= read -r -d '' rpm_file; do
    copy_rpm "${rpm_file}"
done < <(find "${fedora_rpm_root}" -type f -name '*.rpm' -print0)
while IFS= read -r -d '' rpm_file; do
    copy_rpm "${rpm_file}"
done < <(find "${jetson_dir}/dist/l4t-r39.2.1/RPMS" -type f -name '*.rpm' \
    ! -name 'lumina-jetson-bootconf-1.0-1.lu26.noarch.rpm' -print0)

mkdir -p "${iso_tree}/jetson/layouts" "${iso_tree}/LuminaPackages"
install -m 0644 "${script_dir}/lumina-jetson.ks" \
    "${iso_tree}/jetson/lumina-jetson.ks"
printf 'LUMINA_INSTALLER_MIN_EPOCH=%s\n' "${build_epoch}" \
    >"${iso_tree}/jetson/build.env"
install -m 0755 "${script_dir}/lumina-jetson-storage" \
    "${iso_tree}/jetson/lumina-jetson-storage"
install -m 0755 "${script_dir}/lumina-jetson-bootstrap" \
    "${iso_tree}/jetson/lumina-jetson-bootstrap"
install -m 0755 "${script_dir}/lumina-jetson-finalize" \
    "${iso_tree}/jetson/lumina-jetson-finalize"
install -m 0644 "${script_dir}/layouts/orin.sfdisk.in" \
    "${iso_tree}/jetson/layouts/orin.sfdisk.in"
install -m 0644 "${script_dir}/grub.cfg.fragment" \
    "${iso_tree}/EFI/BOOT/grub.cfg"
if [[ -n "${LUMINA_INSTALLER_SSH_KEY_FILE:-}" ]]; then
    install -m 0600 "${LUMINA_INSTALLER_SSH_KEY_FILE}" \
        "${iso_tree}/jetson/installer_authorized_key"
fi

case "${comps_xml}" in
    *.zst)
        command -v zstd >/dev/null || die "missing required command: zstd"
        zstd -dc "${comps_xml}" >"${iso_tree}/LuminaPackages/comps.xml"
        ;;
    *)
        cp -a "${comps_xml}" "${iso_tree}/LuminaPackages/comps.xml"
        ;;
esac

createrepo_c -g "${iso_tree}/LuminaPackages/comps.xml" \
    "${iso_tree}/LuminaPackages"

for required_rpm in \
    nvme-cli \
    efibootmgr \
    NetworkManager-wifi \
    pciutils \
    usbutils \
    iw \
    btop \
    gdm \
    gnome-initial-setup \
    gnome-control-center \
    gnome-shell-extension-appindicator \
    gnome-shell \
    lumina-artwork \
    lumina-release \
    kernel-tegra-l4t \
    tegra-l4t-firmware \
    nvidia-l4t-driver \
    nvidia-l4t-tools \
    nvidia-l4t-power-gui \
    nvidia-cuda-runtime \
    nvidia-cuda-toolkit \
    jetson-stats \
    python3-smbus2 \
    python3-nvidia-ml-py; do
    compgen -G "${package_dir}/${required_rpm}-*.rpm" >/dev/null ||
        die "offline repository is missing ${required_rpm}"
done
for driver_rpm in "${package_dir}"/nvidia-l4t-driver-*.rpm; do
    if rpm -qpl "${driver_rpm}" | grep -qx /etc/asound.conf; then
        die "$(basename -- "${driver_rpm}") conflicts with Fedora alsa-lib"
    fi
    if rpm -qpl "${driver_rpm}" |
        grep -Eq '^/usr/share/alsa/init(/|$)'; then
        die "$(basename -- "${driver_rpm}") conflicts with Fedora alsa-utils"
    fi
done

"${script_dir}/remaster-runtime.sh" "${iso_tree}" "${tegra_kernel_rpm}"

# The El Torito FAT image has its own copy of grub.cfg.
mcopy -o -i "${iso_tree}/images/efiboot.img" \
    "${script_dir}/grub.cfg.fragment" ::/EFI/BOOT/grub.cfg

xorriso -as mkisofs \
    -V "${volume_id}" \
    -iso-level 3 \
    -J -joliet-long \
    -R \
    -e images/efiboot.img \
    -no-emul-boot \
    -o "${output_iso}" \
    "${iso_tree}"

(
    cd -- "$(dirname -- "${output_iso}")"
    sha256sum "$(basename -- "${output_iso}")" \
        >"$(basename -- "${output_iso}").sha256"
)
printf 'Built %s\n' "${output_iso}"
printf 'Checksum: %s.sha256\n' "${output_iso}"
