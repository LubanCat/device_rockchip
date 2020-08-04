#!/bin/bash

# Target chip
export RK_CHIP=RV1126
# Target arch
export RK_ARCH=arm
# Uboot defconfig
export RK_UBOOT_DEFCONFIG=rv1126
# Uboot image format type: fit(flattened image tree)
export RK_UBOOT_FORMAT_TYPE=fit
# Kernel defconfig
export RK_KERNEL_DEFCONFIG=rv1126_defconfig
# Kernel defconfig fragment
export RK_KERNEL_DEFCONFIG_FRAGMENT=
# Kernel dts
export RK_KERNEL_DTS=rv1109-38-v10-spi-nand
# boot image type
export RK_BOOT_IMG=zboot.img
# kernel image path
export RK_KERNEL_IMG=kernel/arch/arm/boot/zImage
# parameter for GPT table
export RK_PARAMETER=parameter-fit-256M-nand.txt
# Buildroot config
export RK_CFG_BUILDROOT=rockchip_rv1126_rv1109_spi_nand
# Recovery config
export RK_CFG_RECOVERY=
# ramboot config
export RK_CFG_RAMBOOT=
# Pcba config
export RK_CFG_PCBA=
# Build jobs
export RK_JOBS=12
# target chip
export RK_TARGET_PRODUCT=rv1126_rv1109
# Set rootfs type, including ext2 ext4 squashfs ubi
export RK_ROOTFS_TYPE=ubi
# rootfs image path
export RK_ROOTFS_IMG=rockdev/rootfs.${RK_ROOTFS_TYPE}
# Set ramboot image type
export RK_RAMBOOT_TYPE=
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
#choose enable distro module
export RK_DISTRO_MODULE=
# Define pre-build script for this board
export RK_BOARD_PRE_BUILD_SCRIPT=app-build.sh
# Define package-file for update.img
export RK_PACKAGE_FILE=rv1109-package-file-spi-nand
