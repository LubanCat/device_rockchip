#!/bin/bash

#=========================
# Compile Config
#=========================
# Target arch
ARCH=arm64
# Uboot defconfig
UBOOT_DEFCONFIG=evb-rk3328
# Kernel defconfig
KERNEL_DEFCONFIG=rockchip_linux_defconfig
# Kernel dts
KERNEL_DTS=rk3328-evb-linux
# Buildroot config
CFG_BUILDROOT=rockchip_rk3328
# Recovery config
CFG_RECOVERY=rockchip_rk3328_recovery
# Pcba config
CFG_PCBA=rockchip_rk3328_pcba
# Build jobs
JOBS=12
#=========================
# Platform Target
#=========================
TARGET_PRODUCT=rk3328

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
