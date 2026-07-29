# NVIDIA L4T README volume

These files were copied byte-for-byte from the read-only volume mounted on the
R39.2 reference Jetson at:

```text
/media/cv2/L4T-README
```

The volume is a 16 MiB FAT filesystem labeled `L4T-README`, backed by:

```text
/opt/nvidia/l4t-usb-device-mode/filesystem.img
```

Copied material:

- `INDEX.txt`
- `README-usb-dev-mode.txt`
- `README-vnc.txt`
- `README-wifi.txt`
- `l4t-serial.inf`
- `version/nv_tegra_release`
- `version/nvidia-l4t-core.dpkg-s.txt`

`SHA256SUMS` records the hashes verified against the mounted source volume.

The mounted volume also exposed a `version/chosen/` snapshot derived from the
live device tree.  That subtree is intentionally not committed because it
contains device-specific values such as the board's Ethernet MAC address,
KASLR seed, boot arguments, and firmware memory addresses.  None of those
values are needed to document or reproduce the RPM packaging.
