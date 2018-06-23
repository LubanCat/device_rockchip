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
echo "pcba config: $CFG_PCBA"

KERNEL_IMAGE=$TOP_DIR/kernel/arch/arm64/boot/Image
KERNEL_DTB=$TOP_DIR/kernel/resource.img
MK_KERNEL=$DEVICE_DIR/mk-kernel.sh

source $TOP_DIR/buildroot/build/envsetup.sh $CFG_PCBA
BUILD_CONFIG=`get_defconfig_name`
echo "$BUILD_CONFIG"

RAMDISK_IMAGE=$TOP_DIR/buildroot/output/$BUILD_CONFIG/images/rootfs.cpio
PCBA_IMAGE=$TOP_DIR/buildroot/output/$BUILD_CONFIG/images/pcba.img
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
echo "====Start build pcba===="
make
if [ $? -eq 0 ]; then
    echo "====Build pcba ok!===="
else
    echo "====Build pcba failed!===="
    exit 1
fi

echo -n "pack pcba image..."
$TOP_DIR/kernel/scripts/mkbootimg --kernel $KERNEL_IMAGE --ramdisk $RAMDISK_IMAGE --second $KERNEL_DTB -o $PCBA_IMAGE
echo "done."
