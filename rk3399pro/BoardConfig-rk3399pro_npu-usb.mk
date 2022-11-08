#!/bin/bash

# Target arch
export RK_ARCH=arm64
# Uboot defconfig
export RK_UBOOT_DEFCONFIG=rknpu-lion
# Kernel defconfig
export RK_KERNEL_DEFCONFIG=rk3399pro_npu_defconfig
# Kernel dts
export RK_KERNEL_DTS=rk3399pro-npu-evb-v10
# boot image type
export RK_BOOT_IMG=
# kernel image path
export RK_KERNEL_IMG=kernel/arch/arm64/boot/Image
# parameter for GPT table
export RK_PARAMETER=parameter-npu.txt
# Recovery config
export RK_CFG_RECOVERY=
# ramboot config
export RK_CFG_BUILDROOT=rockchip_rk3399pro-npu
export RK_RAMBOOT=true
export RK_ROOTFS_TYPE=cpio.gz
# Pcba config
export RK_CFG_PCBA=
# target chip
export RK_TARGET_PRODUCT=rk3399pro
# Set rootfs type, including ext2 ext4 squashfs
export RK_ROOTFS_TYPE=
# Set oem partition type, including ext2 squashfs
export RK_OEM_FS_TYPE=
# Set userdata partition type, including ext2, fat
export RK_USERDATA_FS_TYPE=
#OEM config
export RK_OEM_DIR=
#userdata config
export RK_USERDATA_DIR=
#misc image
export RK_MISC=
