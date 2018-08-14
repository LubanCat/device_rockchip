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

source $TOP_DIR/device/rockchip/.BoardConfig.mk
# Config
PRODUCT_PATH=$TOP_DIR/device/rockchip/${TARGET_PRODUCT}
BUILDROOT_PATH=$TOP_DIR/buildroot
IMAGE_OUT_PATH=$TOP_DIR/rockdev
KERNEL_PATH=$TOP_DIR/kernel
UBOOT_PATH=$TOP_DIR/u-boot
MISC_IMG_PATH=$TOP_DIR/device/rockchip/rockimg/wipe_all-misc.img
RECOVERY_IMG_PATH=$TOP_DIR/buildroot/output/$CFG_RECOVERY/images/recovery.img
MKOEM=$TOP_DIR/device/rockchip/common/mk-oem.sh
MKUSERDATA=$TOP_DIR/device/rockchip/common/mk-userdata.sh
USER_DATA_DIR=$TOP_DIR/device/rockchip/userdata/userdata_empty

rm -rf $IMAGE_OUT_PATH
mkdir -p $IMAGE_OUT_PATH

echo "Package rootfs.img now"
cp $(pwd)/buildroot/output/$CFG_BUILDROOT/images/rootfs.${ROOTFS_TYPE} $IMAGE_OUT_PATH/rootfs.img
echo "Package rootfs Done..."

if [ ! -f $KERNEL_PATH/kernel.img -o ! -f $KERNEL_PATH/boot.img ];then
	echo "Please Make Kernel First!!!"
	exit -1
fi

echo "Package oem.img now"
if [ "${OEM_PATH}" == "dueros"  ];then
	if [ $ARCH == arm ];then
		TARGET_ARM_TYPE=arm32
	else
		TARGET_ARM_TYPE=arm64
	fi
    OEM_CONTENT_PATH=${IMAGE_OUT_PATH}/.oem
    rm -rf ${OEM_CONTENT_PATH}
    mkdir -p ${OEM_CONTENT_PATH}
    find ${PRODUCT_PATH}/${OEM_PATH} -maxdepth 1 -not -name "arm*" \
        -not -wholename "${PRODUCT_PATH}/${OEM_PATH}" \
        -exec sh -c 'cp -rf ${0} ${1}' "{}" ${OEM_CONTENT_PATH} \;
    cp -rf ${PRODUCT_PATH}/${OEM_PATH}/${TARGET_ARM_TYPE}/baidu_spil_rk3308_${MIC_NUM}mic ${OEM_CONTENT_PATH}/baidu_spil_rk3308
	echo "copy ${TARGET_ARM_TYPE} with ${MIC_NUM}mic."
else
    OEM_CONTENT_PATH=${PRODUCT_PATH}/${OEM_PATH}
fi

$MKOEM ${OEM_CONTENT_PATH} ${IMAGE_OUT_PATH}/oem.img ${OEM_PARTITION_TYPE}

echo "Package oem.img [image type: ${OEM_PARTITION_TYPE}] Done..."

echo "Package userdata.img now"
	$MKUSERDATA $USER_DATA_DIR ${IMAGE_OUT_PATH}/userdata.img ext2
echo "Package userdata.img Done..."

if [ $ARCH == arm ];then
	if [ "${OEM_PATH}" == "dueros" ];then
		PARAMETER=$PRODUCT_PATH/rockimg/gpt-nand-32bit-dueros.txt
	else
		PARAMETER=$PRODUCT_PATH/rockimg/gpt-nand-32bit.txt
	fi
elif [ "${FLASH_TYPE}" == "nand" ];then
	if [ "${OEM_PATH}" == "aispeech" ];then
		PARAMETER=$PRODUCT_PATH/rockimg/gpt-nand-aispeech.txt
	elif [ "${OEM_PATH}" == "dueros" ];then
		PARAMETER=$PRODUCT_PATH/rockimg/gpt-nand-dueros.txt
	else
		PARAMETER=$PRODUCT_PATH/rockimg/gpt-nand.txt
	fi
else
	PARAMETER=$PRODUCT_PATH/rockimg/gpt-emmc.txt
fi

if [ -f $UBOOT_PATH/uboot.img ]
then
	echo -n "create uboot.img..."
	cp -a $UBOOT_PATH/uboot.img $IMAGE_OUT_PATH/uboot.img
	echo "done."
else
	echo "$UBOOT_PATH/uboot.img not fount! Please make it from $UBOOT_PATH first!"
fi

if [ -f $UBOOT_PATH/trust.img ]
then
        echo -n "create trust.img..."
        cp -a $UBOOT_PATH/trust.img $IMAGE_OUT_PATH/trust.img
        echo "done."
else    
        echo "$UBOOT_PATH/trust.img not fount! Please make it from $UBOOT_PATH first!"
fi

if [[ -f $UBOOT_PATH/*_loader_*.bin ]]
then
        echo -n "create loader..."
        cp -a $UBOOT_PATH/*_loader_*.bin $IMAGE_OUT_PATH/MiniLoaderAll.bin
        echo "done."
else
		echo -n "create loader..."
		cp -a $UBOOT_PATH/*_loader_*.bin $IMAGE_OUT_PATH/
        echo "done."
fi

if [ -f $KERNEL_PATH/boot.img ]
then
        echo -n "create boot.img..."
		# arm use zboot.img
		if [ $ARCH == arm ];then
			cp -a $KERNEL_PATH/zboot.img $IMAGE_OUT_PATH/boot.img
		else
			cp -a $KERNEL_PATH/boot.img $IMAGE_OUT_PATH/boot.img
		fi
        echo "done."
else
        echo "$KERNEL_PATH/boot.img not fount!"
fi

if [ -f $MISC_IMG_PATH ]
then
        echo -n "create misc.img..."
        cp -a $MISC_IMG_PATH $IMAGE_OUT_PATH/misc.img
        echo "done."
else
        echo "$MISC_IMG_PATH not fount!"
fi

if [ -f $RECOVERY_IMG_PATH ]
then
        echo -n "create boot.img..."
        cp -a $RECOVERY_IMG_PATH $IMAGE_OUT_PATH/recovery.img
        echo "done."
else
        echo "$RECOVERY_IMG_PATH not fount!"
fi

if [ -f $PARAMETER ]
then
        echo -n "create parameter..."
        cp -a $PARAMETER $IMAGE_OUT_PATH/parameter.txt
        echo "done."
else
        echo "$PARAMETER not fount!"
fi

echo "Image: image in ${IMAGE_OUT_PATH} is ready"
