# Orange Pi 5 Ultra qualification

Hardware status: **partial; exact-image and full acceptance pending**. Live
development on the target board completed a normal mainline boot and passed 17
of the 18 automated checks after loading the AP6611 driver patch. Onboard Wi-Fi
enumerated as `wlan0` and scanned a real 5 GHz access point. The remaining
failure was the sticky kernel taint from the unsigned development module and a
warning produced by an earlier revision. The packaged candidate below has
passed offline artifact validation but has not yet been cold-booted on the
board. This file is an acceptance checklist, not proof of full acceptance.

## Candidate identity

Offline candidate built on 2026-09-03:

- Image filename:
  `Lumina-26.08-OrangePi-5-Ultra-mainline-dkms-aarch64.raw.zst`
- Image SHA-256:
  `dd3128bb9933dece8bb2d552e4c1a787159cd5e8ce15905b636e29ba5c06b0cd`
- Image sizes: 1,200,558,206 bytes compressed; 4,647,305,728 bytes raw
- RPM `SHA256SUMS` SHA-256:
  `4d46bb1def40c68a1be38d7bb62a6b617a9dd35fb302b59113ad7f9170d7470b`
- Fedora `kernel-core` NEVRA: `kernel-core-7.1.12-200.fc44.aarch64`
- U-Boot RPM NEVRA: `lumina-orangepi5-ultra-boot-2026.07-4.lu26.aarch64`
- Wi-Fi driver RPM NEVRA:
  `orangepi5-ultra-brcmfmac-dkms-7.1.12-1.lu26.noarch`
- Firmware RPM NEVRA: `orangepi5-ultra-firmware-20250319-2.lu26.noarch`
- Support RPM NEVRA: `orangepi5-ultra-support-1.0-3.lu26.noarch`
- Build source revision: `32a474616361676a7fa14dd79dbe6512a66ab2dc`

The package build, pinned source checksum, static board contracts, RPM build,
GPT validation, U-Boot byte comparison, merged-DTB validation, SELinux-label
validation, initramfs inspection, compressed-image checksum, and Zstandard
integrity check passed. Image construction also built the DKMS module against
the sole installed Fedora kernel, confirmed that `modinfo` prefers it over the
in-tree module, and matched the exact `sdio:c*v06CBdAABF*` alias. The generated
DTB selects GPIO2 mux 0 with clock GPIO2_B3, command GPIO2_B2, data
GPIO2_A6/A7/B0/B1, active-low reset GPIO2_C5, and child-owned host wake. It
disables the conflicting legacy `rfkill` node. These are offline results and
do not change hardware status.

The 2026-09-03 UART development run used Linux
`7.1.12-200.fc44.aarch64` and the same BCM43711 driver changes now carried by
the DKMS RPM. It confirmed Panthor and `/dev/dri/renderD128`, Rocket and
`/dev/accel/accel0`, `r8169` Ethernet, three ALSA cards, connected HDMI,
Bluetooth `hci0`, NVMe, `brcmfmac`, and `wlan0`, with no failed systemd units
or fatal kernel-log signatures. A scan found a 5 GHz network on channel 40.
The firmware advertises 6 GHz using a D11AX chanspec encoding that mainline
`brcmfmac` does not yet decode, so the package intentionally filters those
entries and makes no 6 GHz support claim. A clean boot of the packaged module
must confirm that the only taint bits are the expected out-of-tree and unsigned
module flags (`0x3000`).

The image with SHA-256
`0f4e6544d04b28aaa36c7951685efeb2dfae433434444357f5ff116d58da21b1`
is superseded. It supplied the base for AP6611 development but did not contain
the final DKMS, BCM43711 firmware naming, Bluetooth alias/blacklist, or corrected
host-wake ownership shipped by the current candidate.

The image with SHA-256
`773eaa2ec1c5851cfee823abf71cb4ea83be5c71277e4b242679197ca11d339b`
is superseded. Its 2026-09-02 hardware run completed a normal boot on Linux
7.1.12 and reported no failed systemd units, kernel taint, or fatal kernel-log
signatures. The automated checks found the expected board, Panthor GPU and
render node, Rocket NPU and accelerator node, `r8169` Ethernet, three ALSA
cards, a connected HDMI output, Bluetooth `hci0`, and NVMe. These results prove
basic discovery only; the functional and stress checks below remain open.

That run did not enumerate onboard Wi-Fi or load `brcmfmac`. The DTB generator
passed decimal-looking `11` and `10` to `fdtput -tx`; that option parses cells
as hexadecimal, so it encoded GPIO2_C1/C0 instead of the board's GPIO2_B3/B2
SDIO clock/command pins. The current candidate uses hexadecimal `b` and `a`
and validates every relevant cell after generation. The same run reported the
old generic `kernel-rpm` check as failed, although artifact read-back resolves
`/usr/lib/modules/7.1.12-200.fc44.aarch64/vmlinuz` to
`kernel-core-7.1.12-200.fc44.aarch64`. The replacement check queries that exact
file owner and preserves the RPM diagnostic if the board still disagrees.

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
- Confirm `uname -r` and `rpm -qf /usr/lib/modules/$(uname -r)/vmlinuz`
  identify the Fedora kernel and contain no Armbian release suffix.
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
- Wi-Fi: the DKMS `brcmfmac` loads the BCM43711/AP6611 firmware and board
  calibration, scans 2.4/5 GHz as permitted by the regulatory domain,
  associates, and survives a sustained bidirectional transfer and reboot.
  Record 6 GHz as unsupported rather than treating its absence as a failure.
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

Acceptance requires no kernel taint other than the DKMS module's expected
out-of-tree and unsigned flags (`0x3000`), and no oops, panic, RCU stall,
watchdog lockup, I/O error, GPU/NPU fault, firmware-load error, or failed
systemd unit. Add measured results and the final verdict below this checklist;
only then change the hardware status from pending.
