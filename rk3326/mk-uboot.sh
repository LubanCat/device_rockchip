#!/bin/bash

cd u-boot && ./make.sh evb-rk3326 && cd -

if [ $? -eq 0 ]; then
    echo "====Build u-boot ok!===="
else
    echo "====Build u-boot failed!===="
    exit 1
fi
