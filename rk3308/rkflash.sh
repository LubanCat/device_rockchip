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

UPGRADETOOL=$TOP_DIR/tools/linux/Linux_Upgrade_Tool/Linux_Upgrade_Tool/upgrade_tool
ROCKIMG_DIR=$TOP_DIR/rockdev
LOADER=$ROCKIMG_DIR/MiniLoaderAll.bin
PARAMETER=$ROCKIMG_DIR/parameter.txt
UBOOT=$ROCKIMG_DIR/uboot.img
TRUST=$ROCKIMG_DIR/trust.img
BOOT=$ROCKIMG_DIR/boot.img
RECOVERY=$ROCKIMG_DIR/recovery.img
OEM=$ROCKIMG_DIR/oem.img
MISC=$ROCKIMG_DIR/misc.img
ROOTFS=$ROCKIMG_DIR/rootfs.img
USERDATA=$ROCKIMG_DIR/userdata.img

if [ ! -n "$1" ]
then
echo "flash all images as default"
FLASH_TYPE=all
else
FLASH_TYPE="$1"
fi

if [ $FLASH_TYPE = all ]
then
        sudo $UPGRADETOOL ul $LOADER
	sudo $UPGRADETOOL di -p $PARAMETER
	sudo $UPGRADETOOL di -uboot $UBOOT
	sudo $UPGRADETOOL di -trust $TRUST
	sudo $UPGRADETOOL di -b $BOOT
	sudo $UPGRADETOOL di -r $RECOVERY
	sudo $UPGRADETOOL di -m $MISC
	sudo $UPGRADETOOL di -oem $OEM
	#sudo $UPGRADETOOL di -userdata $USERDATA
	sudo $UPGRADETOOL di -rootfs $ROOTFS
	sudo $UPGRADETOOL rd
fi

if [ $FLASH_TYPE = loader ]
then
	sudo $UPGRADETOOL ul $LOADER
fi

if [ $FLASH_TYPE = parameter ]
then
	sudo $UPGRADETOOL di -p $PARAMETER
fi

if [ $FLASH_TYPE = uboot ]
then
	sudo $UPGRADETOOL di -uboot $UBOOT
fi

if [ $FLASH_TYPE = trust ]
then
	sudo $UPGRADETOOL di -trust $TRUST
fi

if [ $FLASH_TYPE = boot ]
then
	sudo $UPGRADETOOL di -b $BOOT
fi

if [ $FLASH_TYPE = recovery ]
then
	sudo $UPGRADETOOL di -r $RECOVERY
fi

if [ $FLASH_TYPE = misc ]
then
	sudo $UPGRADETOOL di -misc $MISC
fi

if [ $FLASH_TYPE = oem ]
then
	sudo $UPGRADETOOL di -oem $OEM
fi

if [ $FLASH_TYPE = userdata ]
then
	sudo $UPGRADETOOL di -userdata $USERDATA
fi

if [ $FLASH_TYPE = rootfs ]
then
	sudo $UPGRADETOOL di -rootfs $ROOTFS
fi

