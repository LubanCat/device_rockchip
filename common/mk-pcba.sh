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
BOARD_CONFIG=$1
source $BOARD_CONFIG
echo "pcba config: $CFG_PCBA"
if [ $ARCH == arm64 ];then
KERNEL_IMAGE=$TOP_DIR/kernel/arch/arm64/boot/Image
elif [ $ARCH == arm ];then
KERNEL_IMAGE=$TOP_DIR/kernel/arch/arm/boot/zImage
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

source $TOP_DIR/buildroot/build/envsetup.sh $CFG_PCBA
BUILD_CONFIG=`get_defconfig_name`
RAMDISK_IMAGE=$TOP_DIR/buildroot/output/$BUILD_CONFIG/images/rootfs.cpio.gz
PCBA_IMAGE=$TOP_DIR/buildroot/output/$BUILD_CONFIG/images/pcba.img

# build pcba
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
