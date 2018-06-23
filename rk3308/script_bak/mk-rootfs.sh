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

if [ ! -n "$1" ]
then
echo "build buildroot rootfs as default"
BUILD_TYPE=buildroot
else
BUILD_TYPE="$1"
fi

if [ $BUILD_TYPE = buildroot ]
then
$DEVICE_DIR/mk-buildroot.sh
fi

if [ $BUILD_TYPE = yocto ]
then
$DEVICE_DIR/mk-yocto.sh
fi
