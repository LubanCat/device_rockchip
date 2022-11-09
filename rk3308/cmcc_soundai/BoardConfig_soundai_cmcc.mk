#!/bin/bash

# Target arch
export RK_KERNEL_ARCH=arm64
# Uboot defconfig
export RK_UBOOT_DEFCONFIG=evb-rk3308
# Kernel defconfig
export RK_KERNEL_DEFCONFIG=rk3308_linux_defconfig
# Kernel dts
export RK_KERNEL_DTS=rk3308-cmcc-rns

export RK_KERNEL_IMG=kernel/arch/arm64/boot/Image.lz4
# boot image type
export RK_BOOT_IMG=zboot.img
# parameter for GPT table
export RK_PARAMETER=soundai/parameter-64bit-soundai_oem.txt
# Buildroot config
export RK_CFG_BUILDROOT=rockchip_rk3308_soundai_release
# Recovery config
export RK_CFG_RECOVERY=rockchip_rk3308_recovery
# Pcba config
export RK_CFG_PCBA=rockchip_rk3308_pcba
# target chip
export RK_TARGET_PRODUCT=rk3308
# Set rootfs type, including ext2 ext4 squashfs
export RK_ROOTFS_TYPE=squashfs
MIC_NUM=6

# <dev>:<mount point>:<fs type>:<mount flags>:<source dir>:<image size(M|K|auto)>:[options]
export RK_EXTRA_PARTITIONS="oem:/oem:ext2:defaults:soundai:auto:resize@userdata:/userdata:ext2:defaults:userdata_empty:auto:resize"
