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

cd $TOP_DIR/kernel && make ARCH=arm64 rockchip_linux_defconfig && make ARCH=arm64 rk3308-evb-dmic-pdm-v11.img -j12 && cd -

if [ $? -eq 0 ]; then
    echo "====Build kernel ok!===="
else
    echo "====Build kernel failed!===="
    exit 1
fi
