# Lumina for Orange Pi Zero 3

This tree supports the Allwinner H618-based Orange Pi Zero 3. It is independent
of the legacy Rockchip Orange Pi 5 packages under `orangepi/5x`.

The output is a directly bootable, compressed raw SD-card image. There is no
UEFI layer and no installer: the image contains an MBR, the board's combined
SPL/U-Boot payload at the 8 KiB Allwinner ROM offset, and one ext4 root
partition beginning at sector 8192.

## Reference payloads

The package inputs were captured from Orange Pi build 1.0.6 on a live Zero 3.
See [the reference notes](docs/reference.md) for the hardware and boot evidence.
The current development-card results and remaining physical tests are tracked
in [the qualification notes](docs/qualification.md).

To repeat the extraction with SSH key or agent authentication:

```bash
orangepi/zero3/tools/extract-reference.sh \
    orangepi@ZERO3_HOST orangepi/dist/zero3/1.0.6
```

For password-based SSH, set `SSHPASS` in the calling environment. The password
is never stored by the script.

Source archives remain outside Git. Their immutable names, sizes, and hashes
are recorded in `tools/zero3-1.0.6-source-set.sha256` and in the Lumina package
manifest.

## Build packages and image

Build the Lumina identity and Zero 3 RPMs on an aarch64 Fedora 44 host:

```bash
orangepi/zero3/tools/build-packages.sh
```

Then build an automatically minimized rootless image with Podman:

```bash
orangepi/zero3/image/build-image.sh
```

The builder installs a Fedora 44 headless command-line base, Lumina identity,
the exact H618 kernel/DTB/modules, the focused onboard-radio firmware,
NetworkManager's Wi-Fi plugin, WPA supplicant, fastfetch with Lumina artwork,
btop, zram, compact hardware utilities, board tools, and the verified
SPL/U-Boot payload. Mesa and desktop environments are deliberately omitted.
It creates a generic dracut initramfs rather than reusing the Ubuntu reference
initramfs. Set `FEDORA_CONTAINER_IMAGE` to a pinned Fedora 44 container
reference when the surrounding build system pins base inputs.

The default output is:

```text
orangepi/dist/zero3/Lumina-26.08-OrangePi-Zero3-aarch64.raw.zst
```

The builder measures the installed root, starts with a small ext4 metadata
allowance, and grows in 16 MiB steps only until the filesystem can be populated
with 128 MiB of verified usable first-boot headroom. The raw image ends after
that filesystem and the Allwinner boot gap. On first boot, the
root partition grows to the SD-card size. An explicit third argument can
override automatic sizing, for example `1024M` or `1G`.

Boot does not stop for interactive setup. HDMI `tty1` automatically logs in
as the fixed administrative user `lumina`; its password is `lumina` for sudo,
serial-console login, and SSH. Root login stays disabled. The interactive
login banner is presentation-only and never launches setup. Change the default
password with `passwd`, then run `sudo nmtui` to configure Wi-Fi.

The banner artwork and layout are refined from
[lumen-rsg/init_setup at the captured source revision](https://github.com/lumen-rsg/init_setup/blob/5a43afb6cf9c9bfaad2deeda1bba4868fb22ca21/init_setup.sh).
Only the presentation layer is retained: there is no setup launcher, screen
clearing, or fabricated update state.

## Flash

Replace `/dev/SDX` with the whole SD-card device, not a partition:

```bash
zstdcat orangepi/dist/zero3/Lumina-26.08-OrangePi-Zero3-aarch64.raw.zst |
    sudo dd of=/dev/SDX bs=4M oflag=direct status=progress conv=fsync
```

Insert the card in the Zero 3 and power it on. Boot output is enabled on both
HDMI and `ttyS0` at 115200 baud. HDMI reaches an automatic `lumina` shell;
serial and SSH still require the fixed password. Use `sudo nmtui` or
`sudo orangepi-config` to configure Wi-Fi, edit the boot environment, select
H616/H618 overlays, and manage Bluetooth.

The image builder verifies the partition table, ext4 filesystem, and embedded
U-Boot bytes. A successful build is not runtime boot proof; qualify a release
on physical Zero 3 hardware before publishing it.
