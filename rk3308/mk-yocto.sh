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
CONF_PATH=$TOP_DIR/device/rockchip/rk3308/yocto/build/conf

cd $TOP_DIR/kernel
git branch master 1>/dev/null 2>/dev/null
cd $TOP_DIR/yocto
. oe-init-build-env
cp $CONF_PATH/bblayers.conf $TOP_DIR/yocto/build/conf/
cp $CONF_PATH/local.conf $TOP_DIR/yocto/build/conf/
bitbake core-image-ros-roscore -c do_image_ext4
rm -f $TOP_DIR/yocto/rootfs.img
ln -s $TOP_DIR/yocto/build/tmp/work/rockchip_rk3308_evb-poky-linux/core-image-ros-roscore/1.0-r0/deploy-core-image-ros-roscore-image-complete/core-image-ros-roscore-rockchip-rk3308-evb.ext4 $TOP_DIR/yocto/rootfs.img

