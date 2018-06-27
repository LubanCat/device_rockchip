#!/bin/bash

#
# Do a parallel build with multiple jobs, based on the number of CPUs online
# in this system: 'make -j8' on a 8-CPU system, etc.
#
JOBS=$(grep -c ^processor /proc/cpuinfo)

cd kernel && make ARCH=arm64 rockchip_linux_defconfig && make ARCH=arm64 rk3399-sapphire-excavator-linux.img -j$JOBS && cd -

if [ $? -eq 0 ]; then
    echo "====Build kernel ok!===="
else
    echo "====Build kernel failed!===="
    exit 1
fi
