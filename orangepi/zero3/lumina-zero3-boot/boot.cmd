# Lumina Linux boot script for Orange Pi Zero 3 (Allwinner H618)
# Edit /boot/orangepiEnv.txt, then run lumina-zero3-boot-setup.

setenv load_addr "0x45000000"
setenv overlay_error "false"

test -n "${distro_bootpart}" || setenv distro_bootpart "1"
setenv lumina_bootpart "${devnum}:${distro_bootpart}"

test -n "${rootdev}" || setenv rootdev "LABEL=lumina_root"
test -n "${verbosity}" || setenv verbosity "4"
test -n "${rootfstype}" || setenv rootfstype "ext4"
test -n "${console}" || setenv console "both"
test -n "${bootlogo}" || setenv bootlogo "false"
test -n "${fdtfile}" || setenv fdtfile "allwinner/sun50i-h618-orangepi-zero3.dtb"
test -n "${overlay_prefix}" || setenv overlay_prefix "sun50i-h616"

if test -e ${devtype} ${lumina_bootpart} ${prefix}orangepiEnv.txt; then
    echo "Loading ${prefix}orangepiEnv.txt"
    load ${devtype} ${lumina_bootpart} ${load_addr} ${prefix}orangepiEnv.txt
    env import -t ${load_addr} ${filesize}
fi

setenv consoleargs ""
if test "${console}" = "display" || test "${console}" = "both"; then
    setenv consoleargs "console=tty1"
fi
if test "${console}" = "serial" || test "${console}" = "both"; then
    setenv consoleargs "${consoleargs} console=ttyS0,115200"
fi
if test "${bootlogo}" = "true"; then
    setenv consoleargs "splash plymouth.ignore-serial-consoles ${consoleargs}"
else
    setenv consoleargs "splash=verbose ${consoleargs}"
fi

if test "${devtype}" = "mmc"; then
    part uuid mmc ${lumina_bootpart} boot_partuuid
fi
setenv bootargs "root=${rootdev} rootwait rootfstype=${rootfstype} ${consoleargs} consoleblank=0 loglevel=${verbosity} ubootpart=${boot_partuuid} ${extraargs} ${extraboardargs}"

echo "Loading Zero 3 device tree ${fdtfile}"
load ${devtype} ${lumina_bootpart} ${fdt_addr_r} ${prefix}dtb/${fdtfile} || reset
fdt addr ${fdt_addr_r}
fdt resize 65536

for overlay_file in ${overlays}; do
    if load ${devtype} ${lumina_bootpart} ${load_addr} ${prefix}dtb/allwinner/overlay/${overlay_prefix}-${overlay_file}.dtbo; then
        echo "Applying ${overlay_prefix}-${overlay_file}.dtbo"
        fdt apply ${load_addr} || setenv overlay_error "true"
    fi
done
for overlay_file in ${user_overlays}; do
    if load ${devtype} ${lumina_bootpart} ${load_addr} ${prefix}overlay-user/${overlay_file}.dtbo; then
        echo "Applying user overlay ${overlay_file}.dtbo"
        fdt apply ${load_addr} || setenv overlay_error "true"
    fi
done
if test "${overlay_error}" = "true"; then
    echo "Overlay failure; restoring the base device tree"
    load ${devtype} ${lumina_bootpart} ${fdt_addr_r} ${prefix}dtb/${fdtfile} || reset
else
    if load ${devtype} ${lumina_bootpart} ${load_addr} ${prefix}dtb/allwinner/overlay/${overlay_prefix}-fixup.scr; then
        source ${load_addr}
    fi
fi

echo "Loading uInitrd"
load ${devtype} ${lumina_bootpart} ${ramdisk_addr_r} ${prefix}uInitrd || reset
echo "Loading compressed kernel Image"
load ${devtype} ${lumina_bootpart} ${kernel_addr_r} ${prefix}Image || reset

echo "Booting Lumina Linux from ${devtype} ${lumina_bootpart}"
booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
