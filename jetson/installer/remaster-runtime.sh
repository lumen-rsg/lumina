#!/usr/bin/bash
#
# Convert Fedora's ARM64 Anaconda runtime to the matching Tegra kernel and
# 1T Lumina product identity.

set -euo pipefail

readonly script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

die()
{
    printf 'remaster-runtime: %s\n' "$*" >&2
    exit 1
}

[[ $# -eq 2 ]] || die "usage: $0 ISO_TREE KERNEL_RPM"

readonly iso_tree="$(realpath "$1")"
readonly kernel_rpm="$(realpath "$2")"
readonly work_dir="$(mktemp -d)"
readonly kernel_root="${work_dir}/kernel"
readonly initrd_root="${work_dir}/initrd"
readonly stage2_root="${work_dir}/stage2"
readonly old_initrd_modules="${work_dir}/old-initrd-modules"
readonly old_stage2_modules="${work_dir}/old-stage2-modules"
readonly new_initrd="${work_dir}/initrd.img"
readonly new_stage2="${work_dir}/install.img"

cleanup()
{
    rm -rf -- "${work_dir}"
}
trap cleanup EXIT

for command in cpio mksquashfs realpath rpm2cpio unsquashfs xz; do
    command -v "${command}" >/dev/null ||
        die "missing required command: ${command}"
done

[[ -f "${iso_tree}/images/pxeboot/initrd.img" ]] ||
    die "installer initrd is missing"
[[ -f "${iso_tree}/images/install.img" ]] ||
    die "Anaconda stage2 is missing"
[[ -f "${kernel_rpm}" ]] || die "kernel RPM is missing: ${kernel_rpm}"

mkdir -p \
    "${kernel_root}" \
    "${initrd_root}" \
    "${stage2_root}" \
    "${old_initrd_modules}" \
    "${old_stage2_modules}"
(
    cd "${kernel_root}"
    rpm2cpio "${kernel_rpm}" | cpio -idmu --quiet
)

mapfile -t kernel_images < <(
    find "${kernel_root}/boot" -maxdepth 1 -type f -name 'Image-*' -print
)
mapfile -t module_trees < <(
    find "${kernel_root}/usr/lib/modules" -mindepth 1 -maxdepth 1 -type d -print
)
[[ ${#kernel_images[@]} -eq 1 ]] ||
    die "expected exactly one Tegra kernel image"
[[ ${#module_trees[@]} -eq 1 ]] ||
    die "expected exactly one Tegra module tree"
readonly kernel_image="${kernel_images[0]}"
readonly module_tree="${module_trees[0]}"
readonly kernel_version="$(basename -- "${module_tree}")"

# The initramfs contains the dracut/Anaconda discovery logic. Keep that
# userspace, but replace its kernel modules and identity.
(
    cd "${initrd_root}"
    xz -dc "${iso_tree}/images/pxeboot/initrd.img" |
        cpio -idmu --quiet
)
find "${initrd_root}/usr/lib/modules" -mindepth 1 -maxdepth 1 -type d \
    -exec mv -t "${old_initrd_modules}" {} +
cp -a "${module_tree}" "${initrd_root}/usr/lib/modules/"
if [[ -d "${kernel_root}/etc/modprobe.d" ]]; then
    mkdir -p "${initrd_root}/etc/modprobe.d"
    cp -a "${kernel_root}/etc/modprobe.d/." \
        "${initrd_root}/etc/modprobe.d/"
fi

# Fedora's generic installer kernel provides iscsi_tcp. Its inherited dracut
# hook probes that module unconditionally, before checking whether an iSCSI
# root was requested, and calls die when it is absent. This image supports
# local Jetson installation media only, so omit the incompatible parser.
rm -f \
    "${initrd_root}/var/lib/dracut/hooks/cmdline/90-parse-iscsiroot.sh"

install -m 0644 "${script_dir}/runtime/buildstamp" \
    "${initrd_root}/.buildstamp"
install -m 0644 "${script_dir}/runtime/os-release" \
    "${initrd_root}/etc/initrd-release"
install -m 0644 "${script_dir}/runtime/os-release" \
    "${initrd_root}/usr/lib/os-release"
(
    cd "${initrd_root}"
    find . -print0 | sort -z |
        cpio --null --create --format=newc --owner=0:0 --quiet |
        xz --check=crc32 --threads=0 -9 >"${new_initrd}"
)

# Stage2 loads modules after dracut switches to the Anaconda squashfs. A
# rootless compose cannot restore security.selinux xattrs onto its temporary
# directory. The installer boot entries disable SELinux for this ephemeral
# runtime; the Kickstart still configures the installed system as enforcing.
unsquashfs -no-xattrs -d "${stage2_root}" \
    "${iso_tree}/images/install.img" >/dev/null
find "${stage2_root}/usr/lib/modules" -mindepth 1 -maxdepth 1 -type d \
    -exec mv -t "${old_stage2_modules}" {} +
cp -a "${module_tree}" "${stage2_root}/usr/lib/modules/"
if [[ -d "${kernel_root}/etc/modprobe.d" ]]; then
    mkdir -p "${stage2_root}/etc/modprobe.d"
    cp -a "${kernel_root}/etc/modprobe.d/." \
        "${stage2_root}/etc/modprobe.d/"
fi
install -m 0644 "${script_dir}/runtime/buildstamp" \
    "${stage2_root}/.buildstamp"
install -m 0644 "${script_dir}/runtime/os-release" \
    "${stage2_root}/usr/lib/os-release"
install -m 0644 "${script_dir}/runtime/lumina.conf" \
    "${stage2_root}/etc/anaconda/profile.d/lumina.conf"
install -m 0644 "${script_dir}/runtime/lumina.css" \
    "${stage2_root}/usr/share/anaconda/pixmaps/lumina.css"
printf '1T Lumina 26.08 Jetson Installer\n' \
    >"${stage2_root}/usr/lib/issue"
printf '1T Lumina 26.08 Jetson Installer\n' \
    >"${stage2_root}/usr/lib/issue.net"
printf '1T Lumina release 26.08\n' \
    >"${stage2_root}/etc/fedora-release"
printf '1T Lumina release 26.08\n' \
    >"${stage2_root}/etc/redhat-release"
printf '1T Lumina release 26.08\n' \
    >"${stage2_root}/etc/lumina-release"

mksquashfs "${stage2_root}" "${new_stage2}" \
    -noappend -all-root -no-xattrs -comp xz -b 131072 -quiet

install -m 0644 "${kernel_image}" \
    "${iso_tree}/images/pxeboot/vmlinuz"
install -m 0644 "${new_initrd}" \
    "${iso_tree}/images/pxeboot/initrd.img"
install -m 0644 "${new_stage2}" \
    "${iso_tree}/images/install.img"

printf 'Remastered installer runtime for kernel %s\n' "${kernel_version}"
