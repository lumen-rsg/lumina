#!/usr/bin/env bash

set -euo pipefail

readonly test_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly zero3_dir="$(cd -- "${test_dir}/../.." && pwd)"
readonly boot_cmd="${zero3_dir}/lumina-zero3-boot/boot.cmd"
readonly env_file="${zero3_dir}/lumina-zero3-boot/orangepiEnv.txt"
readonly boot_setup="${zero3_dir}/lumina-zero3-boot/lumina-zero3-boot-setup"
readonly config_tool="${zero3_dir}/orangepi-zero3-tools/orangepi-config"
readonly extract_tool="${zero3_dir}/tools/extract-reference.sh"
readonly boot_builder="${zero3_dir}/image/build-rootfs-in-container.sh"
readonly image_builder="${zero3_dir}/image/build-image.sh"
readonly ssh_policy="${zero3_dir}/image/rootfs/etc/ssh/sshd_config.d/20-lumina-login.conf"
readonly wifi_service="${zero3_dir}/orangepi-zero3-tools/orangepi-zero3-wifi.service"
readonly bluetooth_service="${zero3_dir}/orangepi-zero3-tools/orangepi-zero3-bluetooth.service"
readonly wait_wifi="${zero3_dir}/orangepi-zero3-tools/orangepi-zero3-wait-wifi"
readonly wait_bluetooth="${zero3_dir}/orangepi-zero3-tools/orangepi-zero3-wait-bluetooth"
readonly nm_policy="${zero3_dir}/orangepi-zero3-tools/orangepi-zero3-networkmanager.conf"
readonly monitor_tool="${zero3_dir}/orangepi-zero3-tools/orangepimonitor"
readonly tools_spec="${zero3_dir}/orangepi-zero3-tools/orangepi-zero3-tools.spec"
readonly grow_service="${zero3_dir}/image/rootfs/usr/lib/systemd/system/lumina-zero3-grow-rootfs.service"
readonly grow_tool="${zero3_dir}/image/rootfs/usr/libexec/lumina-zero3-grow-rootfs"
readonly autologin="${zero3_dir}/image/rootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf"
readonly banner="${zero3_dir}/image/rootfs/etc/profile.d/90-lumina-zero3-banner.sh"
readonly journal_limits="${zero3_dir}/image/rootfs/etc/systemd/journald.conf.d/20-lumina-zero3-limits.conf"

fail()
{
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

for script in "${boot_setup}" "${config_tool}" "${extract_tool}" "${boot_builder}" \
    "${image_builder}" "${wait_wifi}" "${wait_bluetooth}" "${grow_tool}" \
    "${monitor_tool}" "${banner}"; do
    bash -n "${script}" || fail "shell syntax: ${script}"
done
"${monitor_tool}" --help | grep -Fq 'read-only monitor' ||
    fail "orangepimonitor is not the Lumina-native safe frontend"
grep -Fq 'Source9:        orangepimonitor' "${tools_spec}" ||
    fail "the native orangepimonitor is not packaged"
grep -Fq 'orangepi-zero3-tools/orangepimonitor' "${extract_tool%/*}/build-packages.sh" ||
    fail "the native orangepimonitor is not staged for RPM builds"
grep -Fq 'Requires:       memtester' "${tools_spec}" ||
    fail "the packaged memtester wrapper has no backend dependency"

grep -Fqx 'fdtfile=allwinner/sun50i-h618-orangepi-zero3.dtb' "${env_file}" ||
    fail "Zero 3 DTB is not selected"
grep -Fqx 'rootdev=LABEL=lumina_root' "${env_file}" ||
    fail "image root label is not selected"
grep -Fqx 'console=both' "${env_file}" ||
    fail "HDMI and serial boot output are not both enabled"
grep -Fqx 'overlays=gpu' "${env_file}" ||
    fail "the H618 Mali GPU overlay is not enabled"
grep -Fqx 'extraargs=rw lsm=lockdown,yama,integrity,selinux' "${env_file}" ||
    fail "the Fedora SELinux LSM is not enabled for the vendor kernel"
grep -Fq 'console=ttyS0,115200' "${boot_cmd}" ||
    fail "H618 serial console is missing"
grep -Fq 'dtb/allwinner/overlay/${overlay_prefix}-${overlay_file}.dtbo' "${boot_cmd}" ||
    fail "Allwinner overlay path is missing"
if grep -Eqi 'rockchip|rk35|ttyS2|uefi|grub' "${boot_cmd}" "${env_file}"; then
    fail "Rockchip or UEFI assumptions leaked into Zero 3 boot assets"
fi

expected_commands=$'info\nbootenv\nhardware\nnetwork\ntimezone\nhostname\nbluetooth'
actual_commands="$("${config_tool}" --list)"
[[ "${actual_commands}" == "${expected_commands}" ]] ||
    fail "orangepi-config command list changed"

grep -Fq 'bs=1K seek=8' "${boot_setup}" ||
    fail "boot setup does not use the Allwinner boot offset"
grep -Fq 'bs=1K seek=8' "${boot_builder}" ||
    fail "image builder does not use the Allwinner boot offset"
grep -Fq 'image_size="${3:-auto}"' "${image_builder}" ||
    fail "outer image builder does not default to automatic sizing"
grep -Fq 'requested_image_size="${3:-auto}"' "${boot_builder}" ||
    fail "inner image builder does not default to automatic sizing"
grep -Fq 'rootfs_used_bytes / 16 + auto_free_bytes' "${boot_builder}" ||
    fail "automatic sizing is not based on installed root usage"
grep -Fq 'root_bytes=$((root_bytes + image_alignment_bytes))' "${boot_builder}" ||
    fail "automatic sizing cannot grow to accommodate actual ext4 metadata"
grep -Fq 'auto_free_bytes=$((128 * mebibyte))' "${boot_builder}" ||
    fail "the automatically sized image has unexpected initial free space"
grep -Fq 'available_root_bytes >= required_free_bytes' "${boot_builder}" ||
    fail "the image does not verify usable ext4 free space"
grep -Fqx 'PasswordAuthentication yes' "${ssh_policy}" ||
    fail "the fixed user cannot log in over SSH"
grep -Fq -- '--password "${lumina_password_hash}" lumina' "${boot_builder}" ||
    fail "the fixed lumina account is not created"
grep -Fq -- '--groups wheel,audio,video,render' "${boot_builder}" ||
    fail "the fixed user cannot access standard audio and video devices"
grep -Fqx 'ExecStart=-/sbin/agetty --autologin lumina --noclear %I $TERM' "${autologin}" ||
    fail "tty1 does not automatically log in the lumina user"
grep -Fq '5a43afb6cf9c9bfaad2deeda1bba4868fb22ca21' "${banner}" ||
    fail "the login banner does not identify its source revision"
grep -Fq 'sudo orangepi-config' "${banner}" ||
    fail "the login banner does not advertise the board configuration tool"
if grep -Eq '/var/setup\.sh|UPDATE_MSG|^[[:space:]]*clear([[:space:]]|$)' "${banner}"; then
    fail "the banner still contains first-boot behavior or fabricated status"
fi
grep -Fqx 'SystemMaxUse=32M' "${journal_limits}" ||
    fail "persistent journal storage is not bounded"
grep -Fqx 'MaxRetentionSec=7day' "${journal_limits}" ||
    fail "persistent journal retention is not bounded"
for package in alsa-utils btop ethtool fastfetch i2c-tools libgpiod-utils usbutils zram-generator-defaults; do
    grep -Fq "    ${package} \\" "${boot_builder}" ||
        fail "the headless image does not explicitly install ${package}"
done
if grep -Eq '^[[:space:]]+(mesa-dri-drivers|mesa-libEGL|gnome-shell|plasma-desktop|xfce4-session|lxqt-session|weston)[[:space:]]' "${boot_builder}"; then
    fail "a Mesa runtime or desktop environment leaked into the headless image"
fi
for wifi_package in NetworkManager-wifi wpa_supplicant iw; do
    grep -Fq "${wifi_package} \\" "${boot_builder}" ||
        fail "the image does not explicitly install ${wifi_package}"
done
grep -Fq 'After=local-fs.target systemd-udevd.service' "${wifi_service}" ||
    fail "Wi-Fi is not ordered after the real root filesystem"
grep -Fq 'Before=NetworkManager.service' "${wifi_service}" ||
    fail "Wi-Fi is not initialized before NetworkManager"
grep -Fq 'ExecStart=/usr/sbin/modprobe uwe5622_bsp_sdio' "${wifi_service}" ||
    fail "the UWE5622 transport is not loaded by the post-root service"
grep -Fq 'ExecStart=/usr/sbin/modprobe sprdwl_ng' "${wifi_service}" ||
    fail "the UWE5622 Wi-Fi driver is not loaded by the post-root service"
if [[ -e "${zero3_dir}/orangepi-zero3-tools/orangepi-zero3.modules" ]]; then
    fail "the radio module list would load UWE5622 before its firmware is available"
fi
if grep -Rq --exclude=test-zero3.sh 'lumina-zero3-firstboot' "${zero3_dir}/image"; then
    fail "interactive first-boot setup still blocks normal login"
fi
grep -Fq 'ExecStartPre=/usr/sbin/rfkill unblock all' "${bluetooth_service}" ||
    fail "Bluetooth does not follow the vendor rfkill sequence"
grep -Fq 'Before=bluetooth.service' "${bluetooth_service}" ||
    fail "bluetoothd can race the vendor HCI attach"
grep -Fq 'ExecStartPost=/usr/libexec/orangepi-zero3-wait-bluetooth' "${bluetooth_service}" ||
    fail "Bluetooth attach does not wait for hci0"
if grep -Eq '^Restart=' "${bluetooth_service}"; then
    fail "Bluetooth attach must not flood the console with a restart loop"
fi
grep -Fqx 'wifi.scan-rand-mac-address=no' "${nm_policy}" ||
    fail "Wi-Fi scan MAC randomization is not disabled for the vendor driver"
grep -Fqx 'wifi.cloned-mac-address=permanent' "${nm_policy}" ||
    fail "Wi-Fi connection MAC randomization is not disabled for the vendor driver"
if grep -Fq 'ConditionFirstBoot=' "${grow_service}"; then
    fail "root expansion incorrectly depends on systemd first-boot detection"
fi
grep -Fq 'ConditionPathExists=!/var/lib/lumina/zero3-rootfs-grown' "${grow_service}" ||
    fail "root expansion has no durable completion marker"
grep -Fq '/usr/bin/install -Dpm 0644 /dev/null "${marker_file}"' "${grow_tool}" ||
    fail "root expansion does not write its completion marker"
for grow_field in PKNAME PARTN START; do
    grep -Fq "lsblk -dnro ${grow_field}" "${grow_tool}" ||
        fail "root expansion does not request raw ${grow_field} output"
done
grep -Fq 'systemd-timesyncd.service' "${boot_builder}" ||
    fail "network time synchronization is not enabled"
[[ "$(grep -Fc 'chroot "${rootfs}" /usr/sbin/setfiles -F' "${boot_builder}")" -eq 2 ]] ||
    fail "the root filesystem is not labeled before and after initramfs generation"
if grep -Fq '/usr/sbin/setfiles -F -r /' "${boot_builder}"; then
    fail "setfiles uses an invalid alternate root inside the image chroot"
fi
if grep -Fq '.autorelabel' "${boot_builder}"; then
    fail "the image still depends on a disruptive first-boot relabel"
fi
for dracut_source in "${boot_builder}" "${boot_setup}" "${zero3_dir}/kernel-sun50iw9/kernel-sun50iw9.spec"; do
    grep -Fq -- '--add selinux' "${dracut_source}" ||
        fail "SELinux is missing from a generated initramfs: ${dracut_source}"
done
for context_path in / /dev /sys /run; do
    grep -Fq "verify_image_context ${context_path} " "${boot_builder}" ||
        fail "the image does not verify the SELinux context for ${context_path}"
done

echo 'PASS: Orange Pi Zero 3 Allwinner boot and tool contracts'
