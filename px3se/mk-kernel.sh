#!/bin/bash

cd kernel && make ARCH=arm rockchip_linux_defconfig && make ARCH=arm px3se-evb.img -j12 && cd -

if [ $? -eq 0 ]; then
    echo "====Build kernel ok!===="
else
    echo "====Build kernel failed!===="
    exit 1
fi
