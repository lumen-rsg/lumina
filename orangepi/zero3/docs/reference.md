# Orange Pi Zero 3 reference capture

The Orange Pi Zero 3 support is derived from a live Allwinner H618 reference
board, independently of the legacy Rockchip packages under `orangepi/5x`.

Reference system captured on 2026-09-02:

```text
Model:               OrangePi Zero3
Compatible:          xunlong,orangepi-zero3; allwinner,sun50i-h616
CPU:                 Allwinner H618, four Cortex-A53 cores
Memory:              1 GiB
Orange Pi build:     1.0.6, orangepi-build commit c8894b6
Kernel:              6.1.31-sun50iw9
U-Boot:              2024.01-orangepi
Root storage:        MBR, one ext4 partition at sector 8192
Onboard networking:  YT8531C Gigabit Ethernet; Unisoc UWE5622 Wi-Fi/Bluetooth
Serial console:      ttyS0 at 115200 baud
```

## Boot chain

The installed package provides a single
`u-boot-sunxi-with-spl.bin` containing the Allwinner SPL, TF-A payload, U-Boot,
and U-Boot device tree. The 847,581-byte file has SHA-256
`e7c4224c42039d4033c78259a3f16766a82a2ba3256d1ce0c5f7c065c682b8f9`.
Bytes read from the reference SD card at the 8 KiB Allwinner boot offset match
that file exactly.

The card uses a DOS partition table. Its only partition begins at sector 8192,
leaving a 4 MiB unpartitioned boot gap. The root filesystem and `/boot` share
that ext4 partition. U-Boot reads `boot.scr`, which loads `orangepiEnv.txt`, the
compressed kernel `Image`, the `uInitrd` legacy image, and
`dtb/allwinner/sun50i-h618-orangepi-zero3.dtb`.

The board also exposes 16 MiB of SPI NOR, but the final Lumina image does not
depend on its contents: it carries the verified SPL/U-Boot payload in the SD
image at the ROM boot offset.

## Extracted payloads

`tools/extract-reference.sh` validates the live model, release, kernel, U-Boot,
and Zero 3 DTB before producing deterministic source archives. It extracts:

- the vendor kernel, all `sun50iw9` device trees, and matching modules;
- the exact Zero 3 SPL/U-Boot image, defconfig, and U-Boot license;
- the vendor `orangepi-config`, monitoring, overlay, and Bluetooth helpers;
- the four firmware/config files used by the onboard UWE5622 radio.

The Ubuntu initramfs is deliberately not copied. Lumina generates a new generic
dracut image from the Fedora userspace and the extracted vendor modules.

## Hardware-specific runtime requirements

The onboard radio requires these modules at boot:

```text
uwe5622_bsp_sdio
sprdwl_ng
sprdbt_tty
```

Wi-Fi requests `/usr/lib/firmware/wcnmodem.bin` and
`/usr/lib/firmware/wifi_2355b001_1ant.ini`. Bluetooth additionally uses the
vendor `hciattach_opi` helper on `/dev/ttyBT0` and the two
`bt_configure_*.ini` files.

The reference Orange Pi startup unblocks rfkill before invoking
`hciattach_opi` and does not repeatedly restart a failed attach. Lumina loads
the radio modules only after the real root filesystem makes the vendor
firmware available, and before NetworkManager starts. It then waits for
`wlan0`, follows the reference rfkill sequence, and leaves Bluetooth disabled
after one failed attempt so a shared-radio failure cannot flood the console.

The captured kernel and device tree are vendor 2024 artifacts. Updating them is
a coherent kernel/DTB/module/U-Boot qualification task; changing only the
version string is not safe.
