# NVIDIA driver and userspace findings

## Installed stack

The stock R39.2 image contained 64 installed `nvidia-l4t-*` packages totaling
approximately 1.8 GiB.  The main NVIDIA library directory occupied about
527 MiB:

```text
/usr/lib/aarch64-linux-gnu/nvidia
```

Additional platform payloads under `/opt/nvidia` occupied about 377 MiB.
NVIDIA's loader configuration added the multiarch library directory to
`ld.so.conf` and selected between nvgpu- and OpenRM-specific payloads at boot.

The installed system carried both variants:

- nvgpu kernel, firmware, CUDA, and multimedia packages;
- OpenRM kernel, firmware, CUDA, multimedia, and video-codec packages.

The corresponding initialization services choose and load the appropriate
module and library configuration.  Both `nvgpu` and the `nvidia` display
module family were active on the reference system.

## RPM grouping

The Debian packages were consolidated into functional RPM boundaries:

### `tegra-l4t-firmware`

- `nvidia-l4t-firmware`
- `nvidia-l4t-firmware-nvgpu`
- `nvidia-l4t-firmware-openrm`

### `nvidia-l4t-driver`

- L4T core and initialization
- nvgpu and OpenRM CUDA driver libraries
- CUDA utility interfaces
- EGL, OpenGL, GBM, Vulkan, Wayland, and X11 integration
- NVML
- selected hardware configuration from `nvidia-l4t-configs`

The generic NVIDIA configuration package also carried Ubuntu desktop, APT,
PAM, DNS, NetworkManager, and first-boot policy.  Those distro-specific files
are not installed in Lumina.  Only unmodified hardware configuration files are
selected:

```text
/etc/modprobe.d/nvgpu.conf
/etc/modules-load.d/nvidia-oot.conf
/etc/sysctl.d/90-tegra-settings.conf
/etc/udev/rules.d/99-tegra-devices.rules
/etc/udev/rules.d/99-tegra-mmc-ra.rules
```

### `nvidia-l4t-multimedia`

- Argus and camera libraries
- NvSci
- PVA
- multimedia and video codec libraries
- accelerated GStreamer integration

This package is optional for a minimal headless CUDA system but required for
the Jetson camera and NVIDIA multimedia paths.

### `nvidia-l4t-tools`

- `tegrastats`
- `nvpmodel`
- fan control
- Jetson-IO
- OP-TEE integration

### `lumina-jetson-graphics`

NVIDIA installs its GBM backend in Debian's multiarch directory, while Fedora's
Mesa `libgbm` searches `%{_libdir}/gbm`.  The integration package adds
compatibility symlinks in Fedora's backend directory.

L4T userspace also opens `/dev/nvmap`, several `/dev/nvhost-*-gpu` nodes, and
the R39 `/dev/nvgpu/igpu0/*` interface directly.  NVIDIA's stock rules grant
the runtime nodes to the static `video` group, but Fedora GDM creates transient
greeter accounts that are not members of that group.  Waiting for logind's
active-seat ACL is insufficient because the greeter must initialize EGL before
its graphical session can become active.

Lumina therefore tags the runtime interfaces with systemd-logind's `uaccess`
policy and gives the non-debug GPU nodes bootstrap access.  The nested
`nvidia-gpu-v2` nodes are essential: allowing only the legacy `nvhost` aliases
lets Mutter create a GBM renderer but EGL later rejects the selected primary
GPU.  The `dbg` and `prof*` nodes remain root-only.

The standalone probe used during bring-up can distinguish the NVIDIA and Mesa
paths without starting a compositor:

```bash
GBM_BACKEND=nvidia-drm python3 jetson/tools/probe_egl_gbm.py /dev/dri/card2
```

On the validated Orin Nano this reports GBM backend `nvidia`, EGL 1.5, and EGL
vendor `NVIDIA`, including when run as the transient greeter after applying the
integration package.

## Runtime validation

The Fedora 44 bring-up was validated after a cold reboot with kernel
`6.8.12-1021-tegra`.  GDM remained active, loaded NVIDIA's EGL core, opened
`card2` and `renderD129`, and selected `/dev/dri/card2` as its integrated
primary GPU.

The short table form of `nvidia-smi` may print `No devices were found` on this
integrated platform even while the driver is healthy.  Use the detailed query:

```bash
nvidia-smi -q
```

The validated stack reports one attached `Orin (nvgpu)` Ampere GPU and a GPU
UUID.  Kernel health should also be checked for `nvgpu` initialization and
NVRM Xid errors; no Xid errors were present during the validated boot.

## Services observed

The stock system installed or enabled services including:

```text
nv-load-gpu-libs.service
nv-load-display-modules.service
nv-graphics.service
nvargus-daemon.service
nvpmodel.service
nvfancontrol.service
nv_hugetlbfs_init.service
nv_nvsciipc_init.service
nv-tee-supplicant.service
```

The RPMs retain NVIDIA's unit files, udev rules, module configuration, and
service enablement symlinks.  RPM post-install scripts refresh the dynamic
linker, systemd, and udev state.

## ABI considerations

R39.2 userspace was compiled for Ubuntu 24.04 aarch64, including its `t64`
library transition.  Lumina is Fedora-derived, so successful RPM construction
does not by itself prove runtime compatibility.

Before the first hardware test, the combined driver, multimedia, and tools
payload was audited for ELF dependencies:

```text
Unique DT_NEEDED sonames: 126
Missing from combined L4T payload + Fedora 44 runtime: 0
```

This is a useful static compatibility check, not a substitute for hardware
testing.  GPU compute, display, Vulkan, Argus, camera capture, codec, suspend,
power mode, and fan control must still be exercised on the Fedora/Lumina
rootfs.

## Redistribution

The proprietary payload is taken from NVIDIA's public R39.2 Debian repository.
The grabber records the source Debian package versions and SHA-256 hashes.
RPM build post-processing is disabled for these packages so proprietary
binaries are not stripped, rewritten, or otherwise modified.

The NVIDIA driver license shipped with the packages permits distribution for
use with an OSI-approved kernel when the binary files remain unmodified and
the agreement accompanies the software.  Copyright and license files from
each selected Debian package are retained in the source archives and RPMs.
