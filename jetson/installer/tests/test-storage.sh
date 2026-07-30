#!/usr/bin/env bash

set -euo pipefail

readonly TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly INSTALLER_DIR="$(cd -- "${TEST_DIR}/.." && pwd)"

# shellcheck source=../lumina-jetson-storage
source "${INSTALLER_DIR}/lumina-jetson-storage"
# shellcheck source=../lumina-jetson-finalize
source "${INSTALLER_DIR}/lumina-jetson-finalize"

fail()
{
    echo "FAIL: $*" >&2
    exit 1
}

assert_equal()
{
    local expected="$1"
    local actual="$2"
    local message="$3"

    [[ "${actual}" == "${expected}" ]] ||
        fail "${message}: expected '${expected}', got '${actual}'"
}

assert_equal /dev/nvme0n1p10 "$(partition_path /dev/nvme0n1 10)" \
    "NVMe partition naming"
assert_equal /dev/mmcblk0p1 "$(partition_path /dev/mmcblk0 1)" \
    "MMC partition naming"
assert_equal /dev/sda15 "$(partition_path /dev/sda 15)" \
    "USB partition naming"
validate_target_name /dev/nvme12n3
validate_target_name /dev/mmcblk1
validate_target_name /dev/sdz
if (validate_target_name /dev/vda) 2>/dev/null; then
    fail "unsupported virtual disk name accepted"
fi

label_is_compatible 4 reserved_for_chain_A_user ||
    fail "canonical chain A label rejected"
label_is_compatible 4 A_reserved_on_user ||
    fail "NVIDIA MMC chain A label rejected"
label_is_compatible 4 A_sd_reserved_on_user ||
    fail "NVIDIA SD chain A label rejected"
if label_is_compatible 4 definitely_wrong; then
    fail "invalid chain A label accepted"
fi

work_dir="$(mktemp -d)"
trap 'rm -rf -- "${work_dir}"' EXIT
disk="${work_dir}/orin-disk"
layout="${work_dir}/layout.sfdisk"
truncate -s 16G "${disk}"
render_layout "${disk}" "${INSTALLER_DIR}/layouts/orin.sfdisk.in" "${layout}"
sfdisk --quiet "${disk}" <"${layout}"
dump="$(sfdisk -d "${disk}")"

grep -Fq 'start=     3131968' <<<"${dump}" ||
    fail "APP does not begin at sector 3131968"
grep -Fq 'name="APP"' <<<"${dump}" || fail "APP partition is missing"
grep -Fq 'name="A_kernel"' <<<"${dump}" || fail "A kernel partition is missing"
grep -Fq 'name="esp"' <<<"${dump}" || fail "ESP is missing"
grep -Fq 'name="reserved"' <<<"${dump}" || fail "reserved partition is missing"
assert_equal 15 "$(grep -c '^/.* : start=' <<<"${dump}")" \
    "partition count"

ks_nvme="${work_dir}/nvme.ks"
ks_usb="${work_dir}/usb.ks"
write_kickstart_storage /dev/nvme0n1 fresh "${ks_nvme}"
write_kickstart_storage /dev/sda reuse "${ks_usb}"
grep -Fq -- '--onpart=nvme0n1p1' "${ks_nvme}" ||
    fail "NVMe APP Kickstart path is wrong"
grep -Fq -- '--onpart=nvme0n1p10' "${ks_nvme}" ||
    fail "NVMe ESP Kickstart path is wrong"
assert_equal nvme0n1p1 "$(onpart_for_mount / "${ks_nvme}")" \
    "finalizer APP lookup"
assert_equal nvme0n1p10 "$(onpart_for_mount /boot/efi "${ks_nvme}")" \
    "finalizer ESP lookup"
assert_equal "/dev/nvme0n1 10" "$(efi_disk_and_partition nvme0n1p10)" \
    "NVMe EFI registration target"
assert_equal "/dev/mmcblk0 10" "$(efi_disk_and_partition mmcblk0p10)" \
    "MMC EFI registration target"
assert_equal "/dev/sda 10" "$(efi_disk_and_partition sda10)" \
    "USB EFI registration target"
grep -Fq -- '--onpart=sda1' "${ks_usb}" ||
    fail "USB APP Kickstart path is wrong"
grep -Fq -- '--onpart=sda10 --noformat' "${ks_usb}" ||
    fail "reuse mode must preserve the USB ESP"

echo "PASS: Jetson storage layout and Kickstart generation"
