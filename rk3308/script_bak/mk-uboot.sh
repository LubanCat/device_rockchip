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

cd $TOP_DIR/u-boot && ./make.sh evb-rk3308 && cd -

if [ $? -eq 0 ]; then
    echo "====Build uboot ok!===="
else
    echo "====Build uboot failed!===="
    exit 1
fi
