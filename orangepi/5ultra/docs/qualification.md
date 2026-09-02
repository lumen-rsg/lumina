# Orange Pi 5 Ultra qualification

Hardware status: **pending**. Mainline kernel entry has been confirmed over
UART, but the corrected candidate below has not yet completed a hardware boot.
This file is an acceptance checklist, not proof of full board acceptance.

## Candidate identity

Offline candidate built on 2026-09-02:

- Image filename: `Lumina-26.08-OrangePi-5-Ultra-aarch64.raw.zst`
- Image SHA-256:
  `773eaa2ec1c5851cfee823abf71cb4ea83be5c71277e4b242679197ca11d339b`
- Image sizes: 1,080,688,715 bytes compressed; 4,177,543,680 bytes raw
- RPM `SHA256SUMS` SHA-256:
  `cbdff5c5cb2a87f4c8d6da22ffc74647b378c1b1771487c0539dbae34de61aa3`
- Fedora `kernel-core` NEVRA: `kernel-core-7.1.12-200.fc44.aarch64`
- U-Boot RPM NEVRA: `lumina-orangepi5-ultra-boot-2026.07-3.lu26.aarch64`
- Build source revision: `52155f17af716bd5f96d0f5c862b44ac9c2659a2`

The package build, source checksum manifest, static board contracts, RPM spec
preprocessing, GPT validation, U-Boot byte comparison, merged-DTB validation,
SELinux-label validation, initramfs module inspection, compressed-image
checksum, and Zstandard integrity check passed. An independent artifact
read-back also confirmed that the SDIO controller selects the GPIO2 mux 0
pinctrl group, SPI2 retains its separate pinctrl group, the legacy dracut
SELinux loader is absent, and SELinux remains configured as enforcing. These
are offline results and do not change hardware status.

The image with SHA-256
`1ea8777bad425868c4b3c3f172c361a8d3ddcd2136698b54d94299d51845cbae`
is superseded. On hardware it entered Linux 7.1.12, proving the corrected raw
ARM64 kernel path, but did not finish booting. Its generated DTB selected SDIO
mux 1 on GPIO3, causing `gpio3-5` to conflict with the enabled SPI2 PMIC, and
its initramfs forced dracut's legacy pre-pivot SELinux loader, which failed to
execute `/usr/bin/umount` after loading policy. The current candidate selects
the board's GPIO2 SDIO mux 0 and leaves policy loading to SELinux-capable
systemd without weakening enforcement.

The earlier image with SHA-256
`222f8a5cf0c5b2406299d073d9d9b3de1daeeb9bca3d5169c0df22c3a74b1f2e`
is also superseded. On hardware it reached the extlinux entry but failed with
`Bad Linux ARM64 Image magic!` because Fedora's EFI-zboot `vmlinuz` was passed
directly to U-Boot. The current candidate extracts and validates the raw ARM64
`Image` both during image construction and after kernel updates.

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
