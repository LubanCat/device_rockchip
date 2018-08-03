#!/bin/bash

#=========================
# Compile Config
#=========================
# Target arch
ARCH=arm64
# Uboot defconfig
UBOOT_DEFCONFIG=evb-px30
# Kernel defconfig
KERNEL_DEFCONFIG=px30_linux_defconfig
# Kernel dts
KERNEL_DTS=px30-evb-ddr3-v10-linux
# Buildroot config
CFG_BUILDROOT=rockchip_px30
# Recovery config
CFG_RECOVERY=rockchip_px30_recovery
# Pcba config
CFG_PCBA=rockchip_px30_pcba
# Build jobs
JOBS=12
# Yocto machine
YOCTO_MACHINE=rockchip-px30-evb
#=========================
# Platform Target
#=========================
TARGET_PRODUCT=px30

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
