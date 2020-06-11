#!/bin/bash

set -e

SCRIPT_DIR=$(dirname $(realpath $BASH_SOURCE))
TOP_DIR=$(realpath $SCRIPT_DIR/../../..)
cd $TOP_DIR

source $TOP_DIR/device/rockchip/.BoardConfig.mk
ROCKDEV=$TOP_DIR/rockdev

if [ -z $RK_KERNEL_ZIMG ]; then
	KERNEL_IMAGE=$TOP_DIR/$RK_KERNEL_IMG
else
	KERNEL_IMAGE=$TOP_DIR/$RK_KERNEL_ZIMG
fi

fdt=0
kernel=0
ramdisk=0
resource=0
OUTPUT_TARGET_IMAGE="$1"
src_its_file="$2"
ramdisk_file_path="$3"
target_its_file="$ROCKDEV/.tmp_its"

if [ ! -f $src_its_file ]; then
	echo "Not Fount $src_its_file ..."
	exit -1
fi

rm -f $target_its_file
mkdir -p "`dirname $target_its_file`"

while read line
do
	############################# generate fdt path
	if [ $fdt -eq 1 ];then
		echo "data = /incbin/(\"$TOP_DIR/kernel/arch/$RK_ARCH/boot/dts/$RK_KERNEL_DTS.dtb\");" >> $target_its_file
		fdt=0
		continue
	fi
	if echo $line | grep -w "^fdt" |grep -v ";"; then
		fdt=1
		echo "$line" >> $target_its_file
		continue
	fi

	############################# generate kernel image path
	if [ $kernel -eq 1 ];then
		echo "data = /incbin/(\"$KERNEL_IMAGE\");" >> $target_its_file
		kernel=0
		continue
	fi
	if echo $line | grep -w "^kernel" |grep -v ";"; then
		kernel=1
		echo "$line" >> $target_its_file
		continue
	fi

	############################# generate ramdisk path
	if [ -f $ramdisk_file_path ]; then
		if [ $ramdisk -eq 1 ];then
			echo "data = /incbin/(\"$ramdisk_file_path\");" >> $target_its_file
			ramdisk=0
			continue
		fi
		if echo $line | grep -w "^ramdisk" |grep -v ";"; then
			ramdisk=1
			echo "$line" >> $target_its_file
			continue
		fi
	fi

	############################# generate resource path
	if [ $resource -eq 1 ];then
		echo "data = /incbin/(\"$TOP_DIR/kernel/resource.img\");" >> $target_its_file
		resource=0
		continue
	fi
	if echo $line | grep -w "^resource" |grep -v ";"; then
		resource=1
		echo "$line" >> $target_its_file
		continue
	fi

	echo "$line" >> $target_its_file
done < $src_its_file

$TOP_DIR/rkbin/tools/mkimage -f $target_its_file  -E -p 0x800 $OUTPUT_TARGET_IMAGE
rm -f $target_its_file
