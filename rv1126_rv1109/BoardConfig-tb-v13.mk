#!/bin/bash

# Target arch
export RK_ARCH=arm
# Uboot defconfig
export RK_UBOOT_DEFCONFIG=rv1126-emmc-tb
# Uboot image format type: fit(flattened image tree)
export RK_UBOOT_FORMAT_TYPE=
# Kernel defconfig
export RK_KERNEL_DEFCONFIG=rv1126_defconfig
# kernel defconfig fragment
export RK_KERNEL_DEFCONFIG_FRAGMENT=rv1126-tb.config
# Kernel dts
export RK_KERNEL_DTS=rv1126-evb-ddr3-v13-tb-emmc
# boot image type
export RK_BOOT_IMG=zboot.img
# kernel image path
export RK_KERNEL_IMG=kernel/arch/arm/boot/Image
# parameter for GPT table
export RK_PARAMETER=parameter-tb.txt
# Buildroot config
# export RK_CFG_BUILDROOT=rockchip_rv1126_rv1109_tb
# Recovery config
export RK_CFG_RECOVERY=
# ramboot config
export RK_CFG_RAMBOOT=rockchip_rv1126_rv1109_tinyrootfs
# Pcba config
export RK_CFG_PCBA=
# Build jobs
export RK_JOBS=12
# target chip
export RK_TARGET_PRODUCT=rv1126_rv1109
# Set rootfs type, including ext2 ext4 squashfs
export RK_ROOTFS_TYPE=ext4
# rootfs image path
export RK_ROOTFS_IMG=rockdev/rootfs.${RK_ROOTFS_TYPE}
# Set ramboot image type
export RK_RAMBOOT_TYPE=ROMFS
# Set oem partition type, including ext2 squashfs
export RK_OEM_FS_TYPE=
# Set userdata partition type, including ext2, fat
export RK_USERDATA_FS_TYPE=ext2
#OEM config
export RK_OEM_DIR=
#userdata config
export RK_USERDATA_DIR=userdata_normal
#misc image
export RK_MISC=
#choose enable distro module
export RK_DISTRO_MODULE=
# Define package-file for update.img
export RK_PACKAGE_FILE=rv1126-package-file-emmc-tb
