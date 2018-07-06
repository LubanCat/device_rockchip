#!/bin/bash

#=========================
# Compile Config
#=========================
# Target arch
ARCH=arm
# Uboot defconfig
UBOOT_DEFCONFIG=fennec-rk3288
# Kernel defconfig
KERNEL_DEFCONFIG=rockchip_linux_defconfig
# Kernel dts
KERNEL_DTS=rk3288-evb-rk808-linux
# Buildroot config
CFG_BUILDROOT=rockchip_rk3288
# Recovery config
CFG_RECOVERY=rockchip_rk3288_recovery
# Pcba config
CFG_PCBA=rockchip_rk3288_pcba
# Build jobs
JOBS=12
# Yocto machine
YOCTO_MACHINE=rockchip-rk3288-evb
#=========================
# Platform Target
#=========================
TARGET_PRODUCT=rk3288

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
