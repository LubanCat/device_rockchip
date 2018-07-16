#!/bin/bash

#=========================
# Compile Config
#=========================
# Target arch
ARCH=arm64
# Uboot defconfig
UBOOT_DEFCONFIG=evb-rk3326
# Kernel defconfig
KERNEL_DEFCONFIG=rk3326_linux_defconfig
# Kernel dts
KERNEL_DTS=rk3326-evb-lp3-v10-linux
# Buildroot config
CFG_BUILDROOT=rockchip_rk3326
# Recovery config
CFG_RECOVERY=rockchip_rk3326_recovery
# Pcba config
CFG_PCBA=rockchip_rk3326_pcba
# Build jobs
JOBS=12
# Yocto machine
YOCTO_MACHINE=rockchip-rk3326-evb
#=========================
# Platform Target
#=========================
TARGET_PRODUCT=rk3326

# Set rootfs type, see buildroot.
# ext4 squashfs
ROOTFS_TYPE=squashfs

# Set data partition type.
# ext2 squashfs
OEM_PARTITION_TYPE=ext2

# Set flash type.
# support <emmc, nand, spi_nand, spi_nor>
FLASH_TYPE=emmc

#OEM config: /oem/dueros/aispeech/iflytekSDK/CaeDemo_VAD/smart_voice
OEM_PATH=oem
