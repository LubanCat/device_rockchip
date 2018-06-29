#!/bin/bash

DEVICE_DIR=$(cd `dirname $0`; pwd)
if [ -h $0 ]
then
        CMD=$(readlink $0)
        DEVICE_DIR=$(dirname $CMD)
fi
cd $DEVICE_DIR
cd ../../..
TOP_DIR=$(pwd)

source $TOP_DIR/BoardConfig.mk
echo "recovery config: $CFG_RECOVERY"
if [ $ARCH == arm64 ];then
KERNEL_IMAGE=$TOP_DIR/kernel/arch/arm64/boot/Image
elif [ $ARCH == arm ];then
KERNEL_IMAGE=$TOP_DIR/kernel/arch/arm/boot/zImage
fi
KERNEL_DTB=$TOP_DIR/kernel/resource.img
MK_KERNEL=$DEVICE_DIR/mk-kernel.sh

source $TOP_DIR/buildroot/build/envsetup.sh $CFG_RECOVERY
BUILD_CONFIG=`get_defconfig_name`
echo "$BUILD_CONFIG"

RAMDISK_IMAGE=$TOP_DIR/buildroot/output/$BUILD_CONFIG/images/rootfs.cpio.gz
RECOVERY_IMAGE=$TOP_DIR/buildroot/output/$BUILD_CONFIG/images/recovery.img
# build kernel
if [ -f $KERNEL_IMAGE ]
then
	echo "found kernel image"
else
	echo "kernel image doesn't exist, now build kernel image"
	$MK_KERNEL
	if [ $? -eq 0 ]; then
		echo "build kernel done"
	else
		exit 1
	fi
fi

# build recovery
echo "====Start build recovery===="
make
if [ $? -eq 0 ]; then
    echo "====Build recovery ok!===="
else
    echo "====Build recovery failed!===="
    exit 1
fi

echo -n "pack recovery image..."
$TOP_DIR/kernel/scripts/mkbootimg --kernel $KERNEL_IMAGE --ramdisk $RAMDISK_IMAGE --second $KERNEL_DTB -o $RECOVERY_IMAGE
echo "done."
