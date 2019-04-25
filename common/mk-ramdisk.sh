#!/bin/bash

COMMON_DIR=$(cd `dirname $0`; pwd)
if [ -h $0 ]
then
        CMD=$(readlink $0)
        COMMON_DIR=$(dirname $CMD)
fi
cd $COMMON_DIR
cd ../../..
TOP_DIR=$(pwd)
RAMDISK_IMG=$1
RAMDISK_CFG=$2
echo "config is $RAMDISK_CFG"
if [ -z $RAMDISK_CFG ]
then
	echo "config for building $RAMDISK_IMG doesn't exist, skip!"
	exit 0
fi

BOARD_CONFIG=$TOP_DIR/device/rockchip/.BoardConfig.mk
source $BOARD_CONFIG
if [ -z $RK_KERNEL_ZIMG ]; then
	KERNEL_IMAGE=$TOP_DIR/$RK_KERNEL_IMG
else
	KERNEL_IMAGE=$TOP_DIR/$RK_KERNEL_ZIMG
fi

KERNEL_DTB=$TOP_DIR/kernel/resource.img

# build kernel
if [ -f $KERNEL_IMAGE ]
then
	echo "found kernel image"
else
	echo "kernel image doesn't exist, now build kernel image"
	$TOP_DIR/build.sh kernel
	if [ $? -eq 0 ]; then
		echo "build kernel done"
	else
		exit 1
	fi
fi

source $TOP_DIR/buildroot/build/envsetup.sh $RAMDISK_CFG
CPIO_IMG=$TOP_DIR/buildroot/output/$RAMDISK_CFG/images/rootfs.cpio.gz
TARGET_IMAGE=$TOP_DIR/buildroot/output/$RAMDISK_CFG/images/$RAMDISK_IMG

# build ramdisk
echo "====Start build $RAMDISK_CFG===="
make
if [ $? -eq 0 ]; then
    echo "====Build $RAMDISK_CFG ok!===="
else
    echo "====Build $RAMDISK_CFG failed!===="
    exit 1
fi

echo -n "pack $RAMDISK_IMG..."
$TOP_DIR/kernel/scripts/mkbootimg --kernel $KERNEL_IMAGE --ramdisk $CPIO_IMG --second $KERNEL_DTB -o $TARGET_IMAGE
echo "done."
