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
echo "buildroot config: $CFG_BUILDROOT"

source $TOP_DIR/buildroot/build/envsetup.sh $CFG_BUILDROOT
BUILD_CONFIG=`get_defconfig_name`
echo "$BUILD_CONFIG"
ROOTFS_IMAGE=$TOP_DIR/buildroot/output/$BUILD_CONFIG/images/rootfs.img
# build rootfs
echo "====Start build rootfs===="
make
if [ $? -eq 0 ]; then
    echo "====Build rootfs ok!===="
else
    echo "====Build rootfs failed!===="
    exit 1
fi
