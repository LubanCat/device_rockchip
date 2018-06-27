#!/bin/bash

#=========================
# Compile Config
#=========================
# Target arch
ARCH=arm64
# Uboot defconfig
UBOOT_DEFCONFIG=evb-rk3308
# Kernel defconfig
KERNEL_DEFCONFIG=rk3308_linux_defconfig
# Kernel dts
KERNEL_DTS=rk3308-voice-module-board-v10
# Buildroot config
CFG_BUILDROOT=rockchip_rk3308_release
# Recovery config
CFG_RECOVERY=rockchip_rk3308_recovery
# Pcba config
CFG_PCBA=rockchip_rk3308_pcba
# Build jobs
JOBS=12

#=========================
# Platform Target
#=========================
TARGET_PRODUCT=rk3308

# Set rootfs type, see buildroot.
# ext4 squashfs
ROOTFS_TYPE=squashfs

# Set data partition type.
# ext2 squashfs
OEM_PARTITION_TYPE=ext2

# Set flash type.
# support <emmc, nand, spi_nand, spi_nor>
FLASH_TYPE=nand

#OEM config: /oem/dueros/aispeech/iflytekSDK/CaeDemo_VAD
OEM_PATH=oem
