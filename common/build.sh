#!/bin/bash

COMMON_DIR=$(cd `dirname $0`; pwd)
if [ -h $0 ]
then
        CMD=$(readlink $0)
        COMMON_DIR=$(dirname $CMD)
fi
cd $COMMON_DIR
cd ../../..
TOP_DIR=$(pwd)
COMMON_DIR=$TOP_DIR/device/rockchip/common
BOARD_CONFIG=$TOP_DIR/device/rockchip/.BoardConfig.mk
source $BOARD_CONFIG

if [ ! -n "$1" ];then
	echo "build all and save all as default"
	BUILD_TARGET=allsave
else
	BUILD_TARGET="$1"
fi

usage()
{
	echo "====USAGE: build.sh modules===="
	echo "uboot              -build uboot"
	echo "kernel             -build kernel"
	echo "rootfs             -build default rootfs, currently build buildroot as default"
	echo "buildroot          -build buildroot rootfs"
	echo "yocto              -build yocto rootfs, currently build ros as default"
	echo "ros                -build ros rootfs"
	echo "debian             -build debian rootfs"
	echo "pcba               -build pcba"
	echo "all                -build uboot, kernel, rootfs, recovery image"
	echo "default            -build all modules"
}

function build_uboot(){
	# build uboot
	echo "============Start build uboot============"
	echo "TARGET_UBOOT_CONFIG=$UBOOT_DEFCONFIG"
	echo "========================================="
	cd u-boot && ./make.sh $UBOOT_DEFCONFIG && cd -
	if [ $? -eq 0 ]; then
		echo "====Build uboot ok!===="
	else
		echo "====Build uboot failed!===="
		exit 1
	fi
}

function build_kernel(){
	# build kernel
	echo "============Start build kernel============"
	echo "TARGET_ARCH          =$ARCH"
	echo "TARGET_KERNEL_CONFIG =$KERNEL_DEFCONFIG"
	echo "TARGET_KERNEL_DTS    =$KERNEL_DTS"
	echo "=========================================="
	cd $TOP_DIR/kernel && make ARCH=$ARCH $KERNEL_DEFCONFIG && make ARCH=$ARCH $KERNEL_DTS.img -j$JOBS && cd -
	if [ $? -eq 0 ]; then
		echo "====Build kernel ok!===="
	else
		echo "====Build kernel failed!===="
		exit 1
	fi
}

function build_buildroot(){
	# build buildroot
	echo "==========Start build buildroot=========="
	echo "TARGET_BUILDROOT_CONFIG=$CFG_BUILDROOT"
	echo "========================================="
	$COMMON_DIR/mk-buildroot.sh $BOARD_CONFIG
	if [ $? -eq 0 ]; then
		echo "====Build buildroot ok!===="
	else
		echo "====Build buildroot failed!===="
		exit 1
	fi
}

function build_rootfs(){
	build_buildroot
}

function build_ros(){
	# build ros
	echo "======Start build yocto======"
	echo "YOCTO_MACHINE=$YOCTO_MACHINE"
	echo "============================="
	$COMMON_DIR/mk-ros.sh $BOARD_CONFIG
	if [ $? -eq 0 ]; then
		echo "====Build ros ok!===="
	else
		echo "====Build ros failed!===="
		exit 1
	fi
}

function build_yocto(){
	build_ros
}

function build_debian(){
        # build debian
        echo "====Start build debian===="
	$COMMON_DIR/mk-debian.sh
        if [ $? -eq 0 ]; then
                echo "====Build debian ok!===="
        else
                echo "====Build debian failed!===="
                exit 1
        fi
}

function build_recovery(){
	# build recovery
	echo "==========Start build recovery=========="
	echo "TARGET_RECOVERY_CONFIG=$CFG_RECOVERY"
	echo "========================================"
	$COMMON_DIR/mk-recovery.sh $BOARD_CONFIG
	if [ $? -eq 0 ]; then
		echo "====Build recovery ok!===="
	else
		echo "====Build recovery failed!===="
		exit 1
	fi
}

function build_pcba(){
	# build pcba
	echo "==========Start build pcba=========="
	echo "TARGET_PCBA_CONFIG=$CFG_PCBA"
	echo "===================================="
	$COMMON_DIR/mk-pcba.sh $BOARD_CONFIG
	if [ $? -eq 0 ]; then
		echo "====Build pcba ok!===="
	else
		echo "====Build pcba failed!===="
		exit 1
	fi
}

function build_all(){
	echo "============================================"
	echo "TARGET_ARCH=$ARCH"
	echo "TARGET_PLATFORM=$TARGET_PRODUCT"
	echo "TARGET_UBOOT_CONFIG=$UBOOT_DEFCONFIG"
	echo "TARGET_KERNEL_CONFIG=$KERNEL_DEFCONFIG"
	echo "TARGET_BUILDROOT_CONFIG=$CFG_BUILDROOT"
	echo "TARGET_RECOVERY_CONFIG=$CFG_RECOVERY"
	echo "TARGET_PCBA_CONFIG=$CFG_PCBA"
	echo "============================================"
	# clean uboot and kernel before build all
	#cd $TOP_DIR/u-boot/ && make distclean && cd -
	#cd $TOP_DIR/kernel && make distclean && cd -
	build_uboot
	build_kernel
	build_rootfs
	build_recovery
}

function build_firmware(){
	# mkfirmware.sh to genarate image
	./mkfirmware.sh $BOARD_CONFIG
	if [ $? -eq 0 ]; then
	    echo "Make image ok!"
	else
	    echo "Make image failed!"
	    exit 1
	fi
}

function build_updateimg(){
	IMAGE_PATH=$TOP_DIR/rockdev/Image-$TARGET_PRODUCT
	PACK_TOOL_DIR=$TOP_DIR/tools/linux/Linux_Pack_Firmware
	cp -f $IMAGE_PATH/* $PACK_TOOL_DIR/rockdev/Image/

	echo "Make update.img"
	cd $PACK_TOOL_DIR/rockdev && ./mkupdate.sh && cd -
	if [ $? -eq 0 ]; then
	   echo "Make update image ok!"
	else
	   echo "Make update image failed!"
	   exit 1
	fi
	mv $PACK_TOOL_DIR/rockdev/update.img $IMAGE_PATH/
}

function build_save(){
	IMAGE_PATH=$TOP_DIR/rockdev/Image-$TARGET_PRODUCT
	DATE=$(date  +%Y%m%d.%H%M)
	STUB_PATH=Image/"$KERNEL_DTS"_"$DATE"_RELEASE_TEST
	STUB_PATH="$(echo $STUB_PATH | tr '[:lower:]' '[:upper:]')"
	export STUB_PATH=$TOP_DIR/$STUB_PATH
	export STUB_PATCH_PATH=$STUB_PATH/PATCHES
	mkdir -p $STUB_PATH

	#Generate patches
	$TOP_DIR/.repo/repo/repo forall -c "$TOP_DIR/device/rockchip/common/gen_patches_body.sh"

	#Copy stubs
	$TOP_DIR/.repo/repo/repo manifest -r -o $STUB_PATH/manifest_${DATE}.xml
	mkdir -p $STUB_PATCH_PATH/kernel
	cp $TOP_DIR/kernel/.config $STUB_PATCH_PATH/kernel
	cp $TOP_DIR/kernel/vmlinux $STUB_PATCH_PATH/kernel
	mkdir -p $STUB_PATH/IMAGES/
	cp $IMAGE_PATH/* $STUB_PATH/IMAGES/

	#Save build command info
	echo "UBOOT:  defconfig: $UBOOT_DEFCONFIG" >> $STUB_PATH/build_cmd_info
	echo "KERNEL: defconfig: $KERNEL_DEFCONFIG, dts: $KERNEL_DTS" >> $STUB_PATH/build_cmd_info
	echo "BUILDROOT: $CFG_BUILDROOT" >> $STUB_PATH/build_cmd_info

}
#=========================
# build target
#=========================
if [ $BUILD_TARGET == uboot ];then
    build_uboot
    exit 0
elif [ $BUILD_TARGET == kernel ];then
    build_kernel
    exit 0
elif [ $BUILD_TARGET == rootfs ];then
    build_rootfs
    exit 0
elif [ $BUILD_TARGET == buildroot ];then
    build_buildroot
    exit 0
elif [ $BUILD_TARGET == recovery ];then
    build_recovery
    exit 0
elif [ $BUILD_TARGET == pcba ];then
    build_pcba
    exit 0
elif [ $BUILD_TARGET == yocto ];then
    build_yocto
    exit 0
elif [ $BUILD_TARGET == ros ];then
    build_ros
    exit 0
elif [ $BUILD_TARGET == debian ];then
    build_debian
    exit 0
elif [ $BUILD_TARGET == updateimg ];then
    build_updateimg
    exit 0
elif [ $BUILD_TARGET == all ];then
    build_all
    exit 0
elif [ $BUILD_TARGET == firmware ];then
    build_firmware
    exit 0
elif [ $BUILD_TARGET == save ];then
    build_save
    exit 0
elif [ $BUILD_TARGET != allsave ];then
	echo "Can't found build config, please check again"
	usage
	exit 1
fi


#============================================================
# default build all modules, make all image and save stuff
#============================================================
build_all
build_firmware
build_updateimg
build_save
