#!/bin/bash
# Lumina Interactive Boot Configurator

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

echo -e "\n\e[1;36m========================================="
echo " Lumina Boot & Devicetree Configurator"
echo -e "=========================================\e[0m\n"

# 1. Select Device Tree
echo -e "\e[1;37mScanning for Rockchip Device Trees...\e[0m"
mapfile -t DTB_LIST < <(find /boot -name "*.dtb" | grep -v "overlay")

if [ ${#DTB_LIST[@]} -eq 0 ]; then
    echo "No DTBs found! Please install a kernel first."
    exit 1
fi

echo "Select your Board Device Tree:"
select DTB_PATH in "${DTB_LIST[@]}"; do
    if[ -n "$DTB_PATH" ]; then
        # Strip the /boot/ prefix for U-Boot
        FDT_FILE="${DTB_PATH#/boot/}"
        echo -e "\e[1;32mSelected: $FDT_FILE\e[0m\n"
        break
    else
        echo "Invalid selection."
    fi
done

# 2. Select RootFS
echo -e "\e[1;37mScanning for Root Filesystems (NVMe/SD/eMMC)...\e[0m"
mapfile -t BLK_LIST < <(blkid -o device | grep -E "nvme|mmcblk")

echo "Select your Root Filesystem Device:"
select BLK_DEV in "${BLK_LIST[@]}"; do
    if[ -n "$BLK_DEV" ]; then
        ROOT_UUID=$(blkid -s UUID -o value "$BLK_DEV")
        if [ -n "$ROOT_UUID" ]; then
            ROOT_STR="UUID=$ROOT_UUID"
            echo -e "\e[1;32mSelected: $BLK_DEV ($ROOT_STR)\e[0m\n"
        else
            echo "Failed to find UUID, using raw device path."
            ROOT_STR="$BLK_DEV"
        fi
        break
    else
        echo "Invalid selection."
    fi
done

# 3. Write luminaEnv.txt
ENV_FILE="/boot/luminaEnv.txt"
echo "Writing $ENV_FILE..."
cat <<EOF > $ENV_FILE
verbosity=1
bootlogo=true
console=serial
overlay_prefix=rockchip
fdtfile=$FDT_FILE
rootdev=$ROOT_STR
rootfstype=ext4
usbstoragequirks=0x2537:0x1066:u,0x2537:0x1068:u
extraargs=rw rootwait earlycon console=ttyS2,1500000
EOF

# 4. Compile boot.scr
echo "Compiling U-Boot Script (boot.scr)..."
if [ -f /boot/boot.cmd ]; then
    mkimage -C none -A arm -T script -d /boot/boot.cmd /boot/boot.scr
    echo -e "\n\e[1;32mSuccess! Your Lumina system is configured and ready to boot.\e[0m"
else
    echo "\e[1;31mError: /boot/boot.cmd not found!\e[0m"
fi