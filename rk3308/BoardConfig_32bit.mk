#!/bin/bash

# Target arch
export RK_ARCH=arm
# Uboot defconfig
export RK_UBOOT_DEFCONFIG=evb-aarch32-rk3308
# Kernel defconfig
export RK_KERNEL_DEFCONFIG=rk3308_linux_aarch32_debug_defconfig
# Kernel dts
export RK_KERNEL_DTS=rk3308-voice-module-board-v10-aarch32
# boot image type
export RK_BOOT_IMG=zboot.img
# Buildroot config
export RK_CFG_BUILDROOT=rockchip_rk3308_32_release
# Recovery config
export RK_CFG_RECOVERY=rockchip_rk3308_recovery
# Pcba config
export RK_CFG_PCBA=rockchip_rk3308_pcba
# Build jobs
export RK_JOBS=12
# target chip
export RK_TARGET_PRODUCT=rk3308
# Set rootfs type, including ext2 ext4 squashfs
export RK_ROOTFS_TYPE=squashfs
# Set oem partition type, including ext2 squashfs
export RK_OEM_FS_TYPE=ext2
# Set userdata partition type, including ext2, fat
export RK_USERDATA_FS_TYPE=ext2
# Set flash type. support <emmc, nand, spi_nand, spi_nor>
export RK_STORAGE_TYPE=emmc
#OEM config: /oem/dueros/aispeech/iflytekSDK/CaeDemo_VAD/smart_voice
export RK_OEM_DIR=oem
#userdata config
export RK_USERDATA_DIR=userdata_empty
MIC_NUM=6
