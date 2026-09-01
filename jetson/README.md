# NVIDIA Jetson support

This directory repackages the NVIDIA Jetson Linux (L4T) R39.2.1 payload for
Lumina.  The first supported target is the Jetson Orin Nano Developer Kit:

```text
nvidia,p3768-0000+p3767-0005
nvidia,p3768-0000+p3767-0005-super
nvidia,tegra234
```

The board must already have the matching NVIDIA R39.2.1 boot firmware in QSPI.
The RPMs replace the root filesystem and kernel payload; they do not flash MB1,
MB2, UEFI, recovery, or any other boot-firmware partition. The separate
installer can create NVIDIA's target GPT after QSPI/UEFI has been flashed.

## Package layout

- `kernel-tegra-l4t`: NVIDIA's 6.8.12-1021-tegra kernel, DTBs, and in-tree and
  out-of-tree modules.
- `tegra-l4t-firmware`: boot-critical Tegra, GPU, display, and peripheral
  firmware.
- `nvidia-l4t-driver`: the core GPU/OpenRM, EGL/GL/Vulkan, CUDA driver, NVML,
  and NVIDIA initialization payload.
- `nvidia-l4t-multimedia`: camera, NvSci, PVA, multimedia, video codec, and
  GStreamer integration.
- `nvidia-l4t-tools`: `tegrastats`, `nvpmodel`, fan control, Jetson-IO, and
  OP-TEE integration.
- `nvidia-l4t-power-gui`: NVIDIA's Jetson Power monitor and NVPModel desktop
  indicator.
- `nvidia-cuda-runtime`: CUDA 13.2 runtime and accelerated math libraries.
- `nvidia-cuda-toolkit`: nvcc, CUDA headers, development libraries, and
  command-line debugging and profiling tools.
- `jetson-stats`: the `jtop` Jetson monitor and privileged monitoring service.
- `lumina-jetson-graphics`: Fedora GBM search-path and active-seat device
  access integration for GDM and Wayland compositors.
- `btop`: enables aarch64 GPU monitoring and uses Tegra's nvgpu load counter
  when Jetson NVML does not expose utilization.
- `gnome-control-center`: reports the Jetson platform renderer, Cortex-A78AE
  CPU, and NVMe namespace capacity in GNOME System Details.
- `lumina-jetson-bootconf`: generates an L4T UEFI/extlinux entry without
  touching the QSPI firmware.
- `lumina-jetson-boot-assets`: packages the matching L4TLauncher for a newly
  formatted EFI System Partition.
- `lumina-jetson-installer`: creates or validates the NVIDIA-compatible Orin
  GPT and generates Anaconda storage configuration.

The proprietary files are taken, unmodified, from NVIDIA's public L4T Debian
repository.  Each source archive and resulting RPM retains the copyright and
license files shipped in the source Debian packages.  NVIDIA's driver license
permits distribution for use with an OSI-approved kernel if the binaries are
not modified and the agreement accompanies them.

## Fetch sources from the reference Jetson

The grabber asks APT on the Jetson for the exact installed versions, downloads
those packages from NVIDIA, extracts their data payloads, and creates
reproducible source tarballs locally:

```bash
jetson/tools/grab_l4t_r39.sh cv2@192.168.1.22
```

Output goes to `jetson/dist/l4t-r39.2.1/`. Override it with `OUTPUT_DIR`. The
matching T23x L4TLauncher is extracted from `nvidia-l4t-bootloader` as part of
the same operation. Neither the downloaded Debian packages nor generated
tarballs are committed.

## Build

Copy the generated tarballs to `~/rpmbuild/SOURCES`, then build:

```bash
rpmbuild -ba jetson/orin/kernel-tegra-l4t/kernel-tegra-l4t.spec
rpmbuild -ba jetson/orin/tegra-l4t-firmware/tegra-l4t-firmware.spec
rpmbuild -ba jetson/orin/nvidia-l4t-driver/nvidia-l4t-driver.spec
rpmbuild -ba jetson/orin/nvidia-l4t-multimedia/nvidia-l4t-multimedia.spec
rpmbuild -ba jetson/orin/nvidia-l4t-tools/nvidia-l4t-tools.spec
rpmbuild -ba jetson/orin/nvidia-l4t-power-gui/nvidia-l4t-power-gui.spec
rpmbuild -ba jetson/orin/nvidia-cuda-runtime/nvidia-cuda-runtime.spec
rpmbuild -ba jetson/orin/nvidia-cuda-toolkit/nvidia-cuda-toolkit.spec
rpmbuild -ba jetson/orin/jetson-stats/jetson-stats.spec
rpmbuild -ba jetson/orin/lumina-jetson-graphics/lumina-jetson-graphics.spec
rpmbuild -ba jetson/orin/btop/btop.spec
rpmbuild -ba jetson/orin/gnome-control-center/gnome-control-center.spec
rpmbuild -ba jetson/orin/lumina-jetson-bootconf/lumina-jetson-bootconf.spec
rpmbuild -ba jetson/orin/lumina-jetson-boot-assets/lumina-jetson-boot-assets.spec
rpmbuild -ba jetson/orin/lumina-jetson-installer/lumina-jetson-installer.spec
```

CUDA and the graphical NVIDIA power tools use independently pinned public
repository inputs. Generate their source archives before building:

```bash
jetson/tools/grab_cuda_13_2.sh
jetson/tools/grab_l4t_power_gui.sh
```

`jetson-stats` additionally uses the Fedora-style `python3-smbus2` and
`python3-nvidia-ml-py` packages under `common/`. The desktop image takes its
GNOME, installer, and Plymouth identity from `common/lumina-artwork`.

Alternatively, regenerate only the boot-assets source archive from NVIDIA's
matching installer ISO:

```bash
jetson/tools/extract_l4t_installer_assets.sh \
  /path/to/jetsoninstaller-r39.2.1-*.iso
```

Install the kernel, firmware, driver, tools, and boot configuration packages
into the Lumina root filesystem.  Multimedia is optional for a headless CUDA
system but required for the NVIDIA camera and accelerated GStreamer stack.

Run this once from the booted or mounted Lumina root:

```bash
sudo lumina-jetson-boot-setup
```

The command preserves an existing `extlinux.conf` as
`/boot/extlinux/extlinux.conf.pre-lumina` and writes a versioned kernel entry.
For an in-place conversion, do not erase or reformat the NVIDIA boot, recovery,
ESP, or A/B firmware partitions. A fresh install instead uses the guarded
layout creator under `installer/`; it recreates the complete NVIDIA GPT before
Anaconda formats `APP` and the ESP.

## Bring-up notes

The hardware inventory and rationale behind the package split are recorded in
[`docs/`](docs/README.md). These notes describe the exact R39 reference
Jetson used for the initial port, including its NVMe partition table, kernel,
modules, proprietary userspace, and NVIDIA's mounted L4T README material.
