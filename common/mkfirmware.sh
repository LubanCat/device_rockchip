#!/bin/bash

set -e

SCRIPT_DIR=$(dirname $(realpath $BASH_SOURCE))
TOP_DIR=$(realpath $SCRIPT_DIR/../../..)
cd $TOP_DIR

source $TOP_DIR/device/rockchip/.BoardConfig.mk
ROCKDEV=$TOP_DIR/rockdev
PARAMETER=$TOP_DIR/device/rockchip/$RK_TARGET_PRODUCT/$RK_PARAMETER
OEM_DIR=$TOP_DIR/device/rockchip/oem/$RK_OEM_DIR
USER_DATA_DIR=$TOP_DIR/device/rockchip/userdata/$RK_USERDATA_DIR
MISC_IMG=$TOP_DIR/device/rockchip/rockimg/$RK_MISC
ROOTFS_IMG=$TOP_DIR/$RK_ROOTFS_IMG
RAMBOOT_IMG=$TOP_DIR/buildroot/output/$RK_CFG_RAMBOOT/images/ramboot.img
RECOVERY_IMG=$TOP_DIR/buildroot/output/$RK_CFG_RECOVERY/images/recovery.img
TRUST_IMG=$TOP_DIR/u-boot/trust.img
UBOOT_IMG=$TOP_DIR/u-boot/uboot.img
BOOT_IMG=$TOP_DIR/kernel/$RK_BOOT_IMG
LOADER=$TOP_DIR/u-boot/*_loader_v*.bin
#SPINOR_LOADER=$TOP_DIR/u-boot/*_loader_spinor_v*.bin
MKIMAGE=$SCRIPT_DIR/mk-image.sh
mkdir -p $ROCKDEV

# Require buildroot host tools to do image packing.
if [ ! -d "$TARGET_OUTPUT_DIR" ]; then
    echo "Source buildroot/build/envsetup.sh"
    source $TOP_DIR/buildroot/build/envsetup.sh $RK_CFG_BUILDROOT
fi

check_partition_size() {
	echo $PARAMETER

	PARTITIONS_PREFIX=`echo -n "CMDLINE: mtdparts=rk29xxnand:"`
	while read line
	do
		if [[ $line =~ $PARTITIONS_PREFIX ]]
		then
			partitions=`echo $line | sed "s/$PARTITIONS_PREFIX//g"`
			echo $partitions
			break
		fi
	done < $PARAMETER

	[ -z $"partitions" ] && return

	IFS=,
	for part in $partitions;
	do
		part_size=`echo $part | cut -d '@' -f1`
		part_name=`echo $part | cut -d '(' -f2|cut -d ')' -f1`

		[[ $part_size =~ "-" ]] && continue

		part_size=$(($part_size))
		part_size_bytes=$[$part_size*512]

		case $part_name in
			uboot)
				if [ $part_size_bytes -lt `du -b $UBOOT_IMG | awk '{print $1}'` ]
				then
					echo -e "\e[31m error: uboot image size exceed parameter! \e[0m"
					return -1
				fi
			;;
			boot)
				if [ $part_size_bytes -lt `du -b $BOOT_IMG | awk '{print $1}'` ]
				then
					echo -e "\e[31m error: boot image size exceed parameter! \e[0m"
					return -1
				fi
			;;
			recovery)
				if [ $part_size_bytes -lt `du -b $RECOVERY_IMG | awk '{print $1}'` ]
				then
					echo -e "\e[31m error: recovery image size exceed parameter! \e[0m"
					return -1
				fi
			;;
			rootfs)
				if [ $part_size_bytes -lt `du -bD $ROOTFS_IMG | awk '{print $1}'` ]
				then
					echo -e "\e[31m error: rootfs image size exceed parameter! \e[0m"
					return -1
				fi
			;;
		esac
	done
}

if [ $RK_ROOTFS_IMG ]
then
	if [ -f $ROOTFS_IMG ]
	then
		echo -n "create rootfs.img..."
		ln -rsf $ROOTFS_IMG $ROCKDEV/rootfs.img
		echo "done."
	else
		echo "warning: $ROOTFS_IMG not found!"
	fi
fi

if [ -f $PARAMETER ]
then
	echo -n "create parameter..."
	ln -rsf $PARAMETER $ROCKDEV/parameter.txt
	echo "done."
else
	echo -e "\e[31m error: $PARAMETER not found! \e[0m"
	exit -1
fi

if [ $RK_CFG_RECOVERY ]
then
	if [ -f $RECOVERY_IMG ]
	then
		echo -n "create recovery.img..."
		ln -rsf $RECOVERY_IMG $ROCKDEV/recovery.img
		echo "done."
	else
		echo "warning: $RECOVERY_IMG not found!"
	fi
fi

if [ $RK_MISC ]
then
	if [ -f $MISC_IMG ]
	then
		echo -n "create misc.img..."
		ln -rsf $MISC_IMG $ROCKDEV/misc.img
		echo "done."
	else
		echo "warning: $MISC_IMG not found!"
	fi
fi

if [ $RK_OEM_DIR ]
then
	if [ -d $OEM_DIR ]
	then
		$MKIMAGE $OEM_DIR $ROCKDEV/oem.img $RK_OEM_FS_TYPE
	else
		echo "warning: $OEM_DIR  not found!"
	fi
fi

if [ $RK_USERDATA_DIR ]
then
	if [ -d $USER_DATA_DIR ]
	then
		$MKIMAGE $USER_DATA_DIR $ROCKDEV/userdata.img $RK_USERDATA_FS_TYPE
	else
		echo "warning: $USER_DATA_DIR not found!"
	fi
fi

if [ -f $UBOOT_IMG ]
then
        echo -n "create uboot.img..."
        ln -rsf $UBOOT_IMG $ROCKDEV/uboot.img
        echo "done."
else
        echo -e "\e[31m error: $UBOOT_IMG not found! \e[0m"
fi

if [ -f $TRUST_IMG ]
then
        echo -n "create trust.img..."
        ln -rsf $TRUST_IMG $ROCKDEV/trust.img
        echo "done."
else
        echo -e "\e[31m error: $TRUST_IMG not found! \e[0m"
fi

if [ -f $LOADER ]
then
        echo -n "create loader..."
        ln -rsf $LOADER $ROCKDEV/MiniLoaderAll.bin
        echo "done."
else
	echo -e "\e[31m error: $LOADER not found,or there are multiple loaders! \e[0m"
	rm $LOADER
fi

#if [ -f $SPINOR_LOADER ]
#then
#        echo -n "create spinor loader..."
#        ln -rsf $SPINOR_LOADER $ROCKDEV/MiniLoaderAll_SpiNor.bin
#        echo "done."
#else
#	rm $SPINOR_LOADER_PATH 2>/dev/null
#fi

if [ $RK_BOOT_IMG ]
then
	if [ -f $BOOT_IMG ]
	then
		echo -n "create boot.img..."
		ln -rsf $BOOT_IMG $ROCKDEV/boot.img
		echo "done."
	else
		echo "warning: $BOOT_IMG not found!"
	fi
fi

if [ $RK_CFG_RAMBOOT ]
then
	if [ -f $RAMBOOT_IMG ]
	then
	        echo -n "create boot.img..."
	        ln -rsf $RAMBOOT_IMG $ROCKDEV/boot.img
	        echo "done."
	else
		echo "warning: $RAMBOOT_IMG not found!"
	fi
fi

check_partition_size

echo -e "\e[36m Image: image in rockdev is ready \e[0m"
