#!/bin/bash

cd kernel && make ARCH=arm64 rockchip_linux_defconfig && make ARCH=arm64 rk3399-sapphire-excavator-linux.img -j12 && cd -

if [ $? -eq 0 ]; then
    echo "====Build kernel ok!===="
else
    echo "====Build kernel failed!===="
    exit 1
fi
