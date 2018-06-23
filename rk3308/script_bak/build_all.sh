#! /bin/bash

DEVICE_DIR=$(cd `dirname $0`; pwd)
if [ -h $0 ]
then
        CMD=$(readlink $0)
        DEVICE_DIR=$(dirname $CMD)
fi
cd $DEVICE_DIR
cd ../../..
TOP_DIR=$(pwd)

$DEVICE_DIR/mk-uboot.sh
$DEVICE_DIR/mk-kernel.sh
$DEVICE_DIR/mk-rootfs.sh
$DEVICE_DIR/mk-recovery.sh
$DEVICE_DIR/mk-pcba.sh

