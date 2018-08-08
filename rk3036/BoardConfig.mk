#!/bin/bash

#=========================
# Compile Config
#=========================
# Target arch
ARCH=arm
# Uboot defconfig
UBOOT_DEFCONFIG=kylin-rk3036
# Kernel defconfig
KERNEL_DEFCONFIG=rockchip_linux_defconfig
# Kernel dts
KERNEL_DTS=rk3036-kylin
# Buildroot config
CFG_BUILDROOT=rockchip_rk3036
# Recovery config
CFG_RECOVERY=rockchip_rk3036_recovery
# Pcba config
CFG_PCBA=rockchip_rk3036_pcba
# Build jobs
JOBS=12
#=========================
# Platform Target
#=========================
TARGET_PRODUCT=rk3036

# Set rootfs type, see buildroot.
# ext4 squashfs
ROOTFS_TYPE=ext4

# Set data partition type.
# ext2 squashfs
OEM_PARTITION_TYPE=ext2

# Set flash type.
# support <emmc, nand, spi_nand, spi_nor>
FLASH_TYPE=emmc

#OEM config: /oem/dueros/aispeech/iflytekSDK/CaeDemo_VAD/smart_voice
OEM_PATH=oem
