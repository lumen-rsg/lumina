# Orange Pi Zero 3 qualification

This record covers the 1 GiB Allwinner H618 development board tested on
2026-09-02. The board was booted directly from an SD card while the matching
image sources were corrected, then the resulting minimized release candidate
was flashed and accepted on the same hardware.

## Passed on hardware

- The Allwinner ROM loaded the SPL/U-Boot payload from the 8 KiB SD offset.
  Bytes read from the card matched the packaged payload exactly.
- SPL, U-Boot, kernel, and systemd boot output appeared over HDMI. The fixed
  `lumina` account worked on the local console and over SSH, with no first-boot
  prompt blocking startup.
- The accepted candidate's first-boot service expanded its 800 MiB root
  partition and ext4 filesystem to the 14.8 GiB card. Its marker makes
  subsequent boots idempotent.
- The UWE5622 Wi-Fi path initialized without the earlier missing-firmware,
  SDIO, or synchronous-command errors. A 5 GHz connection survived reboots,
  bidirectional SSH transfers, CPU load, Bluetooth discovery, and repeated
  gateway pings without packet loss.
- The vendor Bluetooth attach completed and `btmgmt` discovered both LE and
  classic devices. Scanning did not disrupt Wi-Fi or add SELinux denials.
- Enabling the H616 GPU overlay changed the disabled base-DTB node to `okay`.
  Panfrost bound the Mali-G31, exposed a render node, and completed a
  surfaceless OpenGL ES operation with Mesa 26.1.8 and no GL or kernel GPU
  errors. The test source is `image/tests/egl-smoke.c`.
- Four-core CPU load held 1.512 GHz at approximately 71-73 C without thermal
  throttling, lockups, RCU stalls, or fatal kernel messages.
- A complete 32 MiB `memtester` pass returned success. Larger time-bounded
  passes found no errors before their deadlines.
- A synchronized 256 MiB write measured approximately 4.2 MB/s and a direct
  read approximately 21.7 MB/s, with no MMC, ext4, buffer-I/O, or timeout
  errors. The write rate is an accepted limitation of the available SD card,
  not an image defect.
- HDMI reported a connected display and exposed modes. The USB host enumerated
  the attached keyboard. The three vendor audio cards, GPIO controllers, I2C
  nodes, and serial console device were present. All 16 MiB of SPI NOR could be
  read without an error; the SD image does not depend on SPI contents.
- Multiple normal reboots returned to a fully running system with no failed
  systemd units. The final measured boot in this pass took 28.926 seconds.

The kernel taint value was 1024 throughout testing, attributable to the
vendor Cedrus staging driver. No warning or out-of-tree-module taint appeared.

## Known limitations

- SELinux is enabled as an LSM and persistent filesystem labels are correct,
  but the vendor 6.1 kernel produces early-boot denials for normal initramfs
  and systemd transitions under the Fedora 44 policy. The image must remain
  permissive until a kernel/policy-compatible enforcing boot is qualified.
- The vendor kernel trusts the previous wireless-regdb signing certificate and
  rejects the current Fedora regulatory database signature. Wi-Fi operates,
  but removing the warning correctly requires a kernel update or rebuild with
  the current certificate, rather than freezing an obsolete database.
- The Ethernet driver is present, but link negotiation and DHCP were not tested
  because no Ethernet cable was available.
- Audio devices enumerate, but physical playback and capture were not tested.
- The serial getty is enabled, but no external UART adapter was available.
- GPIO and I2C device nodes exist, but electrical operation was not tested with
  external peripherals. No SPI peripheral test was performed beyond reading
  the onboard NOR.

## Selected headless software profile

The original qualification root used approximately 631 MiB after cleanup. Its
2 GiB raw image was an artificial fixed allocation and compressed to
approximately 220 MiB. The new builder sizes ext4 from the installed root,
grows it in 16 MiB steps only as needed for real ext4 metadata, verifies at
least 128 MiB of usable initial free space, and ends the raw image immediately
after the root partition. First boot still expands it to the card.

The accepted release candidate produced an 804 MiB raw image
(800 MiB root partition), compressed to 250,567,700 bytes (approximately
239 MiB), with 167 MiB of non-reserved initial free space. Offline inspection
found a clean ext4 filesystem, 217 installed packages, matching U-Boot bytes at
the 8 KiB offset, the expected SELinux labels, and no Mesa or desktop packages.
The exact compressed candidate was then flashed to SD and reported working
perfectly on the target board, completing physical-image acceptance.

Mesa was installed only on the qualification card to prove the GPU path. The
minimal Mesa/EGL runtime added 22 packages (approximately 198 MiB installed),
mostly because Panfrost pulls in LLVM. It is deliberately omitted from the
image and can be installed later. No desktop environment is included.

The selected image adds fastfetch, btop, zram, `usbutils`, `ethtool`,
`i2c-tools`, `libgpiod-utils`, and `alsa-utils`. `memtester` is a required
dependency of the shipped vendor memory-test wrapper. Persistent journal data
is compressed, limited to 32 MiB, and retained for no more than seven days.
