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
	FS_TYPE=ext2
else
	FS_TYPE="$1"
fi

if [ ! -n "$2" ]
then
	OEM_DIR=$DEVICE_DIR/oem
else
	OEM_DIR="$2"
fi

if [ ! -n "$3" ]
then
	OEM_IMG=$TOP_DIR/rockdev/oem.img
else
	OEM_IMG="$3"
fi

if [ $FS_TYPE = ext2 ]
then
	$DEVICE_DIR/mke2img.sh $OEM_DIR $OEM_IMG

fi

if [ $FS_TYPE = squashfs ]
then
	mksquashfs $OEM_DIR $OEM_IMG  -noappend -comp gzip
fi
