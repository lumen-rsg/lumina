# Orange Pi 5 Ultra

Lumina supports the Orange Pi 5 Ultra with Fedora's maintained arm64 kernel,
upstream U-Boot, and board-specific RPMs. No kernel or module is copied from an
Armbian installation.

The current deliverable is a flashable hardware-qualification candidate.
Hardware testing of its immediate packaged predecessor confirms a normal
mainline Fedora boot, Fedora kernel RPM ownership, GPU, NPU, Ethernet, audio,
HDMI, Bluetooth, NVMe, and onboard Wi-Fi association. All automated hardware
checks passed. That run also exposed two missing workstation runtime packages;
installing `dbus-daemon` and `systemd-pam` restored a stable GDM Wayland session
and GNOME Shell. The rebuilt candidate includes those packages and a desktop
qualification gate, but still needs its own cold boot. Functional and stress
acceptance also remain pending. Keep those boundaries intact when updating
`docs/qualification.md`.

## Mainline support model

Linux 6.18 and newer contains the Orange Pi 5 Ultra device tree and the RK3588
Rocket NPU driver. Fedora 44's current arm64 kernel enables Panthor GPU, Rocket
NPU, `r8169` Ethernet, and `brcmfmac` as modules. The image uses those Fedora
modules unchanged except for `brcmfmac`: the AP6611's Synaptics BCM43711 SDIO
identity and initialization are not supported by mainline yet, so a narrowly
scoped DKMS override is built from the matching upstream Linux source.

The board's AP6611 radio needs three board-specific pieces:

- `orangepi5-ultra-brcmfmac-dkms`, which adds the observed `06cb:aabf` SDIO
  identity, BCM43711 chip parameters, firmware mapping, and initialization.
  Its build is restricted to the audited Linux 7.1 kernel series.
- Synaptics firmware and the Orange Pi 5 Ultra calibration data, packaged as
  `orangepi5-ultra-firmware` under the filenames expected by `brcmfmac`.
- A deterministic, versioned DTB generator that enables the RK3588 SDIO
  controller and describes its power/reset and host-wake wiring. It does not
  depend on distribution DTBs retaining overlay symbols.

The radio has been verified scanning 2.4 and 5 GHz networks. The firmware also
reports 6 GHz chanspecs using a newer D11AX encoding that mainline `brcmfmac`
does not implement; the override ignores those entries instead of exposing an
incorrect band. Six-gigahertz support therefore remains explicitly out of
scope until it has a proper upstream implementation.

The upstream Rocket NPU interface is not ABI-compatible with Rockchip's RKNN
runtime. A future `rknpu` DKMS package may be useful for applications that must
run RKNN models, but it is not part of the bootable base until the out-of-tree
port has been audited and tested on this exact kernel. The mainline image tests
Rocket and `/dev/accel` instead.

## Build the RPMs and image

The build needs Podman and network access to Fedora 44 repositories. Source
downloads are pinned by commit or release and checked against
`tools/5ultra-mainline-source-set.sha256`.

```sh
orangepi/5ultra/tools/fetch-sources.sh
orangepi/5ultra/tools/build-packages.sh
orangepi/5ultra/image/tests/test-5ultra.sh
orangepi/5ultra/image/build-image.sh
```

The default image is the GNOME workstation profile. Pass `server` as the
fourth argument for a smaller serial/SSH qualification image:

```sh
orangepi/5ultra/image/build-image.sh \
  orangepi/dist/5ultra/rpms \
  orangepi/dist/5ultra/Lumina-26.08-OrangePi-5-Ultra-server-aarch64.raw.zst \
  auto server
```

The image build fails unless it finds exactly one Fedora kernel, its matching
development package, the upstream Ultra DTB, all four required kernel options,
a successfully installed and preferred AP6611 DKMS module with the exact SDIO
alias, an AP6611-enabled merged DTB, correct SELinux labels, and byte-identical
U-Boot data at the raw-image offset. Fedora's arm64 `vmlinuz` is an EFI-zboot
executable; the boot RPM extracts its compressed payload into the raw ARM64
`Image` required by U-Boot's extlinux path and repeats that conversion after
kernel updates.
It creates a GPT image with the root partition at 16 MiB and upstream U-Boot at
32 KiB. The first boot grows the root filesystem to fill SD, eMMC, or NVMe.

## Flash and first boot

Verify the output checksum, replace `/dev/SDX` with the whole SD-card device,
and double-check it before writing:

```sh
(cd orangepi/dist/5ultra && \
  sha256sum -c Lumina-26.08-OrangePi-5-Ultra-mainline-dkms-aarch64.raw.zst.sha256)
zstdcat orangepi/dist/5ultra/Lumina-26.08-OrangePi-5-Ultra-mainline-dkms-aarch64.raw.zst | \
  sudo dd of=/dev/SDX bs=4M oflag=direct status=progress conv=fsync
```

Connect both HDMI and a 3.3 V UART adapter for the first boot. The debug UART
is 1,500,000 baud, 8 data bits, no parity, one stop bit. Never connect a 5 V
serial adapter.

The qualification image logs in automatically as `lumina`; its temporary
password is also `lumina` for `sudo` and SSH. Do not expose the image to an
untrusted network before changing that password.

After boot, run:

```sh
passwd
sudo lumina-orangepi5-ultra-qualify | tee ~/orangepi5-ultra-qualification.txt
```

Then follow the functional and stress procedure in
`docs/qualification.md` and record the exact image checksum and evidence.

## Redistribution boundary

U-Boot and the DTB generator are open source. Fedora supplies the open-source
Trusted Firmware-A BL31. RK3588 still needs Rockchip's binary DDR training
payload, and the AP6611 payload is marked proprietary by Synaptics. Their
upstream repositories do not provide a clear redistribution grant. The image
is suitable for local board qualification, but do not publish the boot or
firmware RPMs, or an image containing them, until redistribution terms are
documented.
