#!/bin/bash

source BoardConfig.mk
echo "============================================"
echo "TARGET_ARCH=$ARCH"
echo "TARGET_PLATFORM=$TARGET_PRODUCT"
echo "TARGET_UBOOT_CONFIG=$UBOOT_DEFCONFIG"
echo "TARGET_KERNEL_CONFIG=$KERNEL_DEFCONFIG"
echo "TARGET_BUILDROOT_CONFIG=$CFG_BUILDROOT"
echo "TARGET_RECOVERY_CONFIG=$CFG_RECOVERY"
echo "TARGET_PCBA_CONFIG=$CFG_PCBA"
echo "============================================"

if [ ! -n "$1" ];then
	echo "build all as default"
	BUILD_TARGET=all
else
	echo "build $1 only"
	BUILD_TARGET="$1"
fi

usage()
{
	echo "====USAGE: build.sh modules===="
	echo "uboot              -build uboot"
	echo "kernel             -build kernel"
	echo "rootfs             -build buildroot rootfs"
	echo "yocto              -build yocto rootfs"
	echo "debian             -build debian rootfs"
	echo "pcba               -build pcba"
	echo "default            -build all modules"
}

function build_uboot(){
	# build uboot
	echo "====Start build uboot===="
	cd u-boot && make distclean && ./make.sh $UBOOT_DEFCONFIG && cd -
	if [ $? -eq 0 ]; then
		echo "====Build uboot ok!===="
	else
		echo "====Build uboot failed!===="
		exit 1
	fi
}

function build_kernel(){
	# build kernel
	echo "====Start build kernel===="
	cd kernel && make ARCH=$ARCH distclean && make ARCH=$ARCH $KERNEL_DEFCONFIG && make ARCH=$ARCH $KERNEL_DTS.img -j$JOBS && cd -
	if [ $? -eq 0 ]; then
		echo "====Build kernel ok!===="
	else
		echo "====Build kernel failed!===="
		exit 1
	fi
}

function build_rootfs(){
	# build buildroot
	echo "====Start build buildroot===="
	./device/rockchip/$TARGET_PRODUCT/mk-buildroot.sh
	if [ $? -eq 0 ]; then
		echo "====Build buildroot ok!===="
	else
		echo "====Build buildroot failed!===="
		exit 1
	fi
}

function build_yocto(){
	# build yocto
	echo "====Start build yocto===="
	./device/rockchip/$TARGET_PRODUCT/mk-yocto.sh
	if [ $? -eq 0 ]; then
		echo "====Build yocto ok!===="
	else
		echo "====Build yocto failed!===="
		exit 1
	fi
}

function build_recovery(){
	# build recovery
	echo "====Start build recovery===="
	./device/rockchip/$TARGET_PRODUCT/mk-recovery.sh
	if [ $? -eq 0 ]; then
		echo "====Build recovery ok!===="
	else
		echo "====Build recovery failed!===="
		exit 1
	fi
}

function build_pcba(){
	# build pcba
	echo "====Start build recovery===="
	./device/rockchip/$TARGET_PRODUCT/mk-pcba.sh
	if [ $? -eq 0 ]; then
		echo "====Build pcba ok!===="
	else
		echo "====Build pcba failed!===="
		exit 1
	fi
}

function build_all(){
	build_uboot
	build_kernel
	build_rootfs
	build_recovery
}

TOP_DIR=$(pwd)
source buildroot/build/envsetup.sh $CFG_BUILDROOT
TARGET_PRODUCT=`get_target_board_type $CFG_BUILDROOT`
PACK_TOOL_DIR=tools/linux/Linux_Pack_Firmware
IMAGE_PATH=rockdev/Image-$TARGET_PRODUCT
DATE=$(date  +%Y%m%d.%H%M)
STUB_PATH=Image/"$KERNEL_DTS"_"$DATE"_RELEASE_TEST
STUB_PATH="$(echo $STUB_PATH | tr '[:lower:]' '[:upper:]')"
export STUB_PATH=$TOP_DIR/$STUB_PATH
export STUB_PATCH_PATH=$STUB_PATH/PATCHES

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
elif [ $BUILD_TARGET == recovery ];then
    build_recovery
    exit 0
elif [ $BUILD_TARGET == pcba ];then
    build_pcba
    exit 0
elif [ $BUILD_TARGET == yocto ];then
    build_yocto
    exit 0
elif [ $BUILD_TARGET != all ];then
	echo "Can't found build config, please check again"
	usage
	exit 1
fi

#==========================
# default build all modules
#==========================
build_all

# mkfirmware.sh to genarate image
echo "make and copy images"
./mkfirmware.sh $CFG_BUILDROOT
if [ $? -eq 0 ]; then
    echo "Make image ok!"
else
    echo "Make image failed!"
    exit 1
fi

mkdir -p $PACK_TOOL_DIR/rockdev/Image/
cp -f $IMAGE_PATH/* $PACK_TOOL_DIR/rockdev/Image/

echo "Make update.img"
cd $PACK_TOOL_DIR/rockdev && ./mkupdate.sh
if [ $? -eq 0 ]; then
   echo "Make update image ok!"
else
   echo "Make update image failed!"
   exit 1
fi
cd -

mv $PACK_TOOL_DIR/rockdev/update.img $IMAGE_PATH/
rm $PACK_TOOL_DIR/rockdev/Image -rf

mkdir -p $STUB_PATH

#Generate patches
.repo/repo/repo forall -c "$TOP_DIR/device/rockchip/common/gen_patches_body.sh"

#Copy stubs
.repo/repo/repo manifest -r -o $STUB_PATH/manifest_${DATE}.xml

mkdir -p $STUB_PATCH_PATH/kernel
cp kernel/.config $STUB_PATCH_PATH/kernel
cp kernel/vmlinux $STUB_PATCH_PATH/kernel
mkdir -p $STUB_PATH/IMAGES/
cp $IMAGE_PATH/* $STUB_PATH/IMAGES/

#Save build command info
echo "UBOOT:  defconfig: $UBOOT_DEFCONFIG" >> $STUB_PATH/build_cmd_info
echo "KERNEL: defconfig: $KERNEL_DEFCONFIG, dts: $KERNEL_DTS" >> $STUB_PATH/build_cmd_info
echo "BUILDROOT: $LUNCH" >> $STUB_PATH/build_cmd_info