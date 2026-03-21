#!/bin/bash
# Run as ROOT
KVER="6.1.115-vendor-rk35xx"
STAGE="/tmp/kernel-repack-vendor"

echo "1. Cleaning and creating staging area..."
rm -rf $STAGE
mkdir -p $STAGE/boot $STAGE/usr/lib/modules $STAGE/usr/src

echo "2. Handling Kernel Image (Decompressing to raw Image if needed)..."
SRC_KERN="/boot/vmlinuz-$KVER"
[ -f "/boot/Image" ] && SRC_KERN="/boot/Image"

if file "$SRC_KERN" | grep -q "gzip compressed"; then
    echo "Decompressing vmlinuz to raw Image..."
    zcat "$SRC_KERN" > $STAGE/boot/Image
else
    echo "Copying raw Image..."
    cp -L "$SRC_KERN" $STAGE/boot/Image
fi
cp $STAGE/boot/Image $STAGE/boot/vmlinuz-$KVER

echo "3. Copying and Flattening DTB directory..."
if[ -d "/boot/dtb-$KVER" ]; then
    cp -aL /boot/dtb-$KVER $STAGE/boot/dtb
elif [ -d "/boot/dtb" ]; then
    cp -aL /boot/dtb $STAGE/boot/dtb
fi

echo "4. Copying Config and System.map..."
cp -aL /boot/System.map-$KVER /boot/config-$KVER $STAGE/boot/ 2>/dev/null || true

echo "5. Copying Modules and Headers..."
cp -aL /usr/lib/modules/$KVER $STAGE/usr/lib/modules/
rm -rf $STAGE/usr/lib/modules/$KVER/build
rm -rf $STAGE/usr/lib/modules/$KVER/source

if [ -d "/usr/src/linux-headers-$KVER" ]; then
    cp -aL /usr/src/linux-headers-$KVER $STAGE/usr/src/
fi

echo "6. Creating Tarball..."
mkdir -p /home/$SUDO_USER/rpmbuild/SOURCES 2>/dev/null || mkdir -p ~/rpmbuild/SOURCES
cd $STAGE
tar --owner=0 --group=0 -czvf ~/rpmbuild/SOURCES/kernel-rk35xx-vendor-6.1.115.tar.gz .

echo "Done! The Vendor kernel tarball is ready."