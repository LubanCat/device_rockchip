#!/bin/bash

# Target arch
export RK_ARCH=arm64
# Uboot defconfig
export RK_UBOOT_DEFCONFIG=rk3588
# Uboot image format type: fit(flattened image tree)
export RK_UBOOT_FORMAT_TYPE=fit
# Kernel defconfig
export RK_KERNEL_DEFCONFIG=lubancat_linux_defconfig
# Kernel defconfig fragment
export RK_KERNEL_DEFCONFIG_FRAGMENT=
# Kernel dts
export RK_KERNEL_DTS=rk3588s-lubancat-4
# boot image type
export RK_BOOT_IMG=boot.img
# kernel image path
export RK_KERNEL_IMG=kernel/arch/arm64/boot/Image
# kernel image format type: fit(flattened image tree)
export RK_KERNEL_FIT_ITS=boot.its
# parameter for GPT table
export RK_PARAMETER=parameter.txt
# Buildroot config
export RK_CFG_BUILDROOT=rockchip_rk3588
# Recovery config
export RK_CFG_RECOVERY=rockchip_rk3588_recovery
# Recovery image format type: fit(flattened image tree)
export RK_RECOVERY_FIT_ITS=boot4recovery.its
# ramboot config
export RK_CFG_RAMBOOT=
# Pcba config
export RK_CFG_PCBA=rockchip_rk3588_pcba
# Build jobs
export RK_JOBS=24
# target chip
export RK_TARGET_PRODUCT=rk3588
# Set rootfs type, including ext2 ext4 squashfs
export RK_ROOTFS_TYPE=ext4
# yocto machine
export RK_YOCTO_MACHINE=rockchip-rk3588-evb
# rootfs image path
export RK_ROOTFS_IMG=rockdev/rootfs.${RK_ROOTFS_TYPE}
# Set ramboot image type
export RK_RAMBOOT_TYPE=
# <dev>:<mount point>:<fs type>:<mount flags>:<source dir>:<image size(M|K|auto)>:[options]
export RK_EXTRA_PARTITIONS=" \
	oem:/oem:ext2:defaults:oem_normal:auto:resize
	userdata:/userdata:ext2:defaults:userdata_normal:auto:resize
"
# OEM build on buildroot
#export RK_OEM_BUILDIN_BUILDROOT=YES
#misc image
export RK_MISC=wipe_all-misc.img
#choose enable distro module
export RK_DISTRO_MODULE=
# Define pre-build script for this board
export RK_BOARD_PRE_BUILD_SCRIPT=app-build.sh

# SOC
export RK_SOC=rk3588
# Define package-file
export RK_PACKAGE_FILE=rk3588-package-file
# 定义默认rootfs为ubuntu
export RK_ROOTFS_SYSTEM=ubuntu
# 默认Ubuntu 版本
export RK_UBUNTU_VERSION=20.04
# 定义默认rootfs是否为桌面版  desktop :桌面版(可替换为 xfce gnome)  lite ：控制台版
export RK_ROOTFS_TARGET=gnome
# 定义默认rootfs是否添加DEBUG工具  debug :添加 	none :不添加
export RK_ROOTFS_DEBUG=none