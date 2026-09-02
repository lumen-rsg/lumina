# Orange Pi 5 Ultra qualification

Hardware status: **pending**. This file is an acceptance checklist, not proof
that the current image has booted on the board.

## Candidate identity

Offline candidate built on 2026-09-02:

- Image filename: `Lumina-26.08-OrangePi-5-Ultra-aarch64.raw.zst`
- Image SHA-256:
  `222f8a5cf0c5b2406299d073d9d9b3de1daeeb9bca3d5169c0df22c3a74b1f2e`
- Image sizes: 1,061,103,477 bytes compressed; 4,043,325,952 bytes raw
- RPM `SHA256SUMS` SHA-256:
  `57bc987869519dd3948d9b61841d5dd90fe0775a7ee95566060438aec590dad8`
- Fedora `kernel-core` NEVRA: `kernel-core-7.1.12-200.fc44.aarch64`
- U-Boot RPM NEVRA: `lumina-orangepi5-ultra-boot-2026.07-1.lu26.aarch64`
- Build source revision: `b3584e426ef7e2c66acb42d301c9240da6418af9`

The package build, source checksum manifest, static board contracts, RPM spec
preprocessing, GPT validation, U-Boot byte comparison, merged-DTB validation,
SELinux-label validation, compressed-image checksum, and Zstandard integrity
check passed. These are offline build results and do not change hardware status.

Record on the hardware run:

- Board RAM/eMMC configuration and PCB revision:
- SD-card model and capacity:
- Test date and operator:

## Boot acceptance

- Verify the compressed image checksum before flashing.
- Read back the U-Boot byte range at offset 32 KiB and compare it with
  `/usr/lib/lumina-orangepi5-ultra/u-boot-rockchip.bin` after boot.
- Capture the complete 1,500,000-baud serial log from power-on through the
  graphical or multi-user target.
- Confirm the reported device-tree model is `Xunlong Orange Pi 5 Ultra`.
- Confirm `uname -r` and `rpm -q kernel-core` identify the Fedora kernel and
  contain no Armbian release suffix.
- Confirm the first-boot service expands the partition and ext4 filesystem,
  writes `/var/lib/lumina/orangepi5-ultra-rootfs-grown`, and stays inactive on
  the next boot.
- Confirm SELinux is enforcing and `ausearch -m AVC -ts boot` contains no
  unexplained denial.
- Confirm a normal reboot and cold power cycle both return to a fully running
  system with no failed units.

## Device acceptance

Run `sudo lumina-orangepi5-ultra-qualify` first and retain its output. Resolve
every `FAIL`; document every intentional `SKIP`.

- GPU: `panthor` binds, a render node exists, GNOME uses hardware rendering,
  and an EGL/Vulkan smoke test completes without GPU faults.
- NPU: `rocket` binds all three RK3588 NPU cores, `/dev/accel/accel0` exists,
  and a mainline Rocket userspace inference smoke test completes.
- Wi-Fi: `brcmfmac` loads the BCM43752/AP6611 firmware and board calibration,
  scans 2.4/5/6 GHz as permitted by the regulatory domain, associates, and
  survives a sustained bidirectional transfer and reboot.
- Bluetooth: `hci0` initializes from the Synaptics firmware, scans LE and
  classic devices, pairs with a device, and coexists with sustained Wi-Fi.
- Ethernet: `r8169` binds RTL8125BG, negotiates 2.5 Gb/s with a capable peer,
  passes DHCP, sustained transfer, and reboot tests without link resets.
- HDMI: a display is detected, GNOME reaches its native mode, audio playback
  works, unplug/replug recovers, and suspend/resume restores the session.
- Analog audio: ES8388 playback, capture, jack detection, and mixer state work.
- Storage: microSD is error-free under synchronized write/read load; test eMMC
  and NVMe discovery and I/O when those devices are installed.
- USB: exercise both USB 3 host ports and both USB 2 host ports. Record the
  USB-C dual-role result separately if tested.
- Cooling: the PWM fan responds to thermal trips; sustained CPU+GPU+NPU load
  produces no thermal shutdown, lockup, RCU stall, or unexplained throttling.
- RTC, LEDs, GPIO, I2C, SPI NOR, cameras, MIPI DSI, and HDMI input: record
  enumeration and functional results separately; do not infer operation from
  a device node alone.

## Stress and evidence

Perform at least two cold boots and five warm reboots. During a 30-minute
combined workload, retain:

- `journalctl -k -b` and `systemctl --failed`
- `lspci -nnk`, `lsusb -tv`, `lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS`
- `ip -br link`, `iw dev`, `bluetoothctl show`
- `ls -l /dev/dri /dev/accel`, `glxinfo -B` or `eglinfo`, and NPU smoke output
- temperatures, fan state, CPU frequencies, `cat /proc/sys/kernel/tainted`
- network and storage throughput plus error counters

Acceptance requires zero unexpected kernel taint, oops, panic, RCU stall,
watchdog lockup, I/O error, GPU/NPU fault, firmware-load error, or failed
systemd unit. Add measured results and the final verdict below this checklist;
only then change the hardware status from pending.
