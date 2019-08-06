#!/bin/bash

# Target arch
export RK_ARCH=arm
# Uboot defconfig
#export RK_UBOOT_DEFCONFIG=rv1108
# Kernel defconfig
export RK_KERNEL_DEFCONFIG=rv1108-lock-evb-v10_defconfig
# Kernel dts
export RK_KERNEL_DTS=rv1108-lock-evb-v10
# boot image type
#export RK_BOOT_IMG=zboot.img
# kernel image path
export RK_KERNEL_IMG=kernel/arch/arm/boot/Image
# parameter for GPT table
#export RK_PARAMETER=parameter-64bit.txt
# setting.ini for firmware
export RK_SETTING_INI=setting-emmc.ini
# Buildroot config
export RK_CFG_BUILDROOT=rockchip_rv1108_lock-evb-v10_defconfig
# Recovery config
#export RK_CFG_RECOVERY=rockchip_rk3308_recovery
# ramboot config
#export RK_CFG_RAMBOOT=
# Pcba config
#export RK_CFG_PCBA=rockchip_rk3308_pcba
# Build jobs
export RK_JOBS=12
# target chip
export RK_TARGET_PRODUCT=rv1108
# Set rootfs type, including ext2 ext4 squashfs
export RK_ROOTFS_TYPE=cpio.lzo
# rootfs image path
export RK_ROOTFS_IMG=rockdev/rootfs.${RK_ROOTFS_TYPE}
# Set oem partition type, including ext2 squashfs
#export RK_OEM_FS_TYPE=ext2
# Set userdata partition type, including ext2, fat
#export RK_USERDATA_FS_TYPE=ext2
# Set flash type. support <emmc, nand, spi_nand, spi_nor>
export RK_STORAGE_TYPE=emmc
#OEM config: /oem/dueros/aispeech-6mic-64bit/aispeech-2mic-64bit/aispeech-4mic-32bit/aispeech-2mic-32bit/aispeech-2mic-kongtiao-32bit/iflytekSDK/CaeDemo_VAD/smart_voice
#export RK_OEM_DIR=oem
#userdata config
export RK_USERDATA_FILESYSTEM_TYPE=ext4
export RK_USERDATA_FILESYSTEM_SIZE=32M
export RK_USERDATA_DIR=common/userdata
#MIC_NUM=6
#misc image
#export RK_MISC=wipe_all-misc.img
#choose enable distro module
#export RK_DISTRO_MODULE=
#choose enable Linux A/B
#export RK_LINUX_AB_ENABLE=
export RK_LOADER_POWER_HOLD_GPIO_GROUP=3
export RK_LOADER_POWER_HOLD_GPIO_INDEX=12
export RK_LOADER_EMMC_TURNING_DEGREE=0
export RK_LOADER_BOOTPART_SELECT=0

