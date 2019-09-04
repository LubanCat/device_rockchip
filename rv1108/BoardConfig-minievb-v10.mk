#!/bin/bash

# Target arch
export RK_ARCH=arm
# target chip
export RK_TARGET_PRODUCT=rv1108
#Target Board Version
export RK_TARGET_BOARD_VERSION=minievb-v10
# Buildroot config
export RK_CFG_BUILDROOT=rockchip_rv1108_lock_defconfig
# Kernel defconfig
export RK_KERNEL_DEFCONFIG=rv1108_defconfig
# Kernel dts
export RK_KERNEL_DTS=rv1108-${RK_TARGET_BOARD_VERSION}
# kernel image path
export RK_KERNEL_IMG=kernel/arch/arm/boot/Image
# setting.ini for firmware
export RK_SETTING_INI=setting.ini
# Build jobs
export RK_JOBS=12
# Set rootfs type, including ext2 ext4 squashfs
export RK_ROOTFS_TYPE=cpio.lz4
# rootfs image path
export RK_ROOTFS_IMG=rockdev/rootfs.${RK_ROOTFS_TYPE}
# Set flash type. support <emmc, nand, nor>
export RK_STORAGE_TYPE=nor
# Set userdata config
export RK_USERDATA_FILESYSTEM_TYPE=jffs2
export RK_USERDATA_FILESYSTEM_SIZE=6M
# Set root data config
export RK_ROOT_FILESYSTEM_TYPE=jffs2
export RK_ROOT_FILESYSTEM_SIZE=6M
# Set loader config
export RK_LOADER_POWER_HOLD_GPIO_GROUP=none
export RK_LOADER_POWER_HOLD_GPIO_INDEX=none
export RK_LOADER_EMMC_TURNING_DEGREE=0
export RK_LOADER_BOOTPART_SELECT=0
#Set ui_resolution
export RK_UI_RESOLUTION=1280x720
# Set first start application
export RK_FIRST_START_APP="lock_app system_manager face_service cvr"
