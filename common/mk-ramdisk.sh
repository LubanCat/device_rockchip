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
RAMDISK_TYPE=$RK_RAMBOOT_TYPE
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
ROMFS_IMG=$TOP_DIR/buildroot/output/$RAMDISK_CFG/images/rootfs.romfs
TARGET_IMAGE=$TOP_DIR/buildroot/output/$RAMDISK_CFG/images/$RAMDISK_IMG

if [ -z $RAMDISK_TYPE ]
then
RAMDISK_TYPE=CPIO
fi

eval ROOTFS_IMAGE=\$${RAMDISK_TYPE}_IMG

# build ramdisk
echo "====Start build $RAMDISK_CFG===="
$TOP_DIR/buildroot/utils/brmake
if [ $? -eq 0 ]; then
    echo "log saved on $TOP_DIR/br.log"
    echo "====Build $RAMDISK_CFG ok!===="
else
    echo "log saved on $TOP_DIR/br.log"
    echo "====Build $RAMDISK_CFG failed!===="
    tail -n 100 $TOP_DIR/br.log
    exit 1
fi

if [ $RAMDISK_TYPE == ROMFS ]
then
# Do compress for tinyrootfs
cat $ROOTFS_IMAGE | gzip -n -f -9 > $ROOTFS_IMAGE.gz
cat $KERNEL_IMAGE | gzip -n -f -9 > $KERNEL_IMAGE.gz
ROOTFS_IMAGE=$ROOTFS_IMAGE.gz
KERNEL_IMAGE=$KERNEL_IMAGE.gz
fi

echo -n "pack $RAMDISK_IMG..."
if [ -f "$TOP_DIR/device/rockchip/$RK_TARGET_PRODUCT/$RK_RECOVERY_FIT_ITS" ];then
	$COMMON_DIR/mk-fitimage.sh $TARGET_IMAGE $TOP_DIR/device/rockchip/$RK_TARGET_PRODUCT/$RK_RECOVERY_FIT_ITS $ROOTFS_IMAGE
else
	$TOP_DIR/kernel/scripts/mkbootimg --kernel $KERNEL_IMAGE --ramdisk $ROOTFS_IMAGE --second $KERNEL_DTB -o $TARGET_IMAGE
fi
echo "done."
