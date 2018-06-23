#!/bin/bash
#buildroot defconfig
LUNCH=rockchip_rk3288_recovery
PROJECT_DIR=$(pwd)
KERNEL_IMAGE=$PROJECT_DIR/kernel/arch/arm/boot/zImage
KERNEL_DTB=$PROJECT_DIR/kernel/resource.img
MAKE_KERNEL_SCRIPT=$PROJECT_DIR/device/rockchip/rk3288/mk-kernel.sh
usage()
{
    echo "USAGE: build [-ovj]"
    echo "-o                    -Generate ota package"
    echo "-v                    -Set build version name for output image folder"
    echo "-j                    -Build jobs"
    exit 1
}

# check pass argument
while getopts "ovj:" arg
do
    case $arg in
        o)
            echo "will build ota package"
            BUILD_OTA=true
            ;;
        v)
            BUILD_VERSION=$OPTARG
            ;;
        j)
            JOBS=$OPTARG
            ;;
        ?)
            usage ;;
    esac
done

TOP_DIR=$(pwd)
source buildroot/build/envsetup.sh $LUNCH

BUILD_CONFIG=`get_defconfig_name`
echo "$BUILD_CONFIG"

RAMDISK_IMAGE=buildroot/output/$BUILD_CONFIG/images/rootfs.cpio.gz
RECOVERY_IMAGE=buildroot/output/$BUILD_CONFIG/images/recovery.img
# build kernel
if [ -f $KERNEL_IMAGE ]
then
	echo "found kernel image"
else
	echo "kernel image doesn't exist, now build kernel image"
	$MAKE_KERNEL_SCRIPT
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
$PROJECT_DIR/kernel/scripts/mkbootimg --kernel $KERNEL_IMAGE --ramdisk $RAMDISK_IMAGE --second $KERNEL_DTB -o $RECOVERY_IMAGE
echo "done."
