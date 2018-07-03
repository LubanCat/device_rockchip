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
source $TOP_DIR/buildroot/build/envsetup.sh $CFG_BUILDROOT
BUILD_CONFIG=`get_defconfig_name`
echo "$BUILD_CONFIG"
ROOTFS_IMAGE=$TOP_DIR/buildroot/output/$BUILD_CONFIG/images/rootfs.img
# build rootfs
make
if [ $? -ne 0 ]; then
    exit 1
fi
