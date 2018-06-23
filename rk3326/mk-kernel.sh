#!/bin/bash

cd kernel && make ARCH=arm64 rk3326_linux_defconfig && make ARCH=arm64 rk3326-evb-linux-lp3-v10.img -j12 && cd -

if [ $? -eq 0 ]; then
    echo "====Build kernel ok!===="
else
    echo "====Build kernel failed!===="
    exit 1
fi
