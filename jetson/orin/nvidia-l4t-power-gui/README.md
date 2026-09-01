# NVIDIA Jetson Power GUI

The core `nvidia-l4t-tools` RPM already contains NVIDIA's `nvpower.service`,
`nvpmodel.service`, `nvfancontrol.service`, `tegrastats`, and `jetson_clocks`.
This package adds the two graphical companion packages NVIDIA ships
separately:

- Jetson Power GUI, backed by `pylibjetsonpower`;
- the NVPModel desktop indicator and its polkit actions.

Run `jetson/tools/grab_l4t_power_gui.sh` to download the pinned R39.2.1 Debian
packages, verify their NVIDIA repository checksums, and create the RPM source
archive. The RPM changes only the Ubuntu-specific terminal launcher to Fedora
Workstation's Ptyxis command syntax and adds an application-menu entry.
