#!/bin/bash

# Target arch
export RK_ARCH=arm
# target chip
export RK_TARGET_PRODUCT=rv1108
#Target Board Version
export RK_TARGET_BOARD_VERSION=lock-evb-sl-v10
# Buildroot config
export RK_CFG_BUILDROOT=rockchip_rv1108_lock_defconfig
# Kernel defconfig
export RK_KERNEL_DEFCONFIG=rv1108-"$RK_TARGET_BOARD_VERSION"_defconfig
# Kernel dts
export RK_KERNEL_DTS=rv1108-"$RK_TARGET_BOARD_VERSION"
# kernel image path
export RK_KERNEL_IMG=kernel/arch/arm/boot/Image
# setting.ini for firmware
export RK_SETTING_INI=setting-emmc.ini
# Build jobs
export RK_JOBS=12
# Set rootfs type, including ext2 ext4 squashfs
export RK_ROOTFS_TYPE=cpio.lzo
# rootfs image path
export RK_ROOTFS_IMG=rockdev/rootfs.${RK_ROOTFS_TYPE}
# Set flash type. support <emmc, nand, nor>
export RK_STORAGE_TYPE=emmc
# Set userdata config
export RK_USERDATA_FILESYSTEM_TYPE=ext4
export RK_USERDATA_FILESYSTEM_SIZE=32M
export RK_USERDATA_DIR=common/userdata
# Set loader config
export RK_LOADER_POWER_HOLD_GPIO_GROUP=3
export RK_LOADER_POWER_HOLD_GPIO_INDEX=14
export RK_LOADER_EMMC_TURNING_DEGREE=2
export RK_LOADER_BOOTPART_SELECT=0
# Set ui_resolution
export RK_UI_RESOLUTION=360x640
# Set UVC source
export RK_UVC_USE_SL_MODULE=y
