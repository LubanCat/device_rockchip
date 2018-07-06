#!/bin/bash

#=========================
# Compile Config
#=========================
# Target arch
ARCH=arm
# Uboot defconfig
UBOOT_DEFCONFIG=evb-px3se
# Kernel defconfig
KERNEL_DEFCONFIG=rockchip_linux_defconfig
# Kernel dts
KERNEL_DTS=px3se-evb
# Buildroot config
CFG_BUILDROOT=rockchip_px3se
# Recovery config
CFG_RECOVERY=rockchip_px3se_recovery
# Pcba config
CFG_PCBA=rockchip_px3se_pcba
# Build jobs
JOBS=12
# Yocto machine
YOCTO_MACHINE=rockchip-px3se-evb
#=========================
# Platform Target
#=========================
TARGET_PRODUCT=px3se

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
