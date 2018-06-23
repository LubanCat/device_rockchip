#!/bin/bash
#buildroot defconfig
LUNCH=rockchip_rk3326
#build jobs
JOBS=12
TOP_DIR=$(pwd)
source buildroot/build/envsetup.sh $LUNCH
TARGET_PRODUCT=`get_target_board_type $LUNCH`
echo "$TARGET_PRODUCT"
export PROJECT_TOP=$TOP_DIR
BUILD_CONFIG=`get_defconfig_name`
echo "$BUILD_CONFIG"
ROOTFS_IMAGE=buildroot/output/$BUILD_CONFIG/images/rootfs.img
# build rootfs
echo "====Start build rootfs===="
make
if [ $? -eq 0 ]; then
    echo "====Build rootfs ok!===="
else
    echo "====Build rootfs failed!===="
    exit 1
fi

