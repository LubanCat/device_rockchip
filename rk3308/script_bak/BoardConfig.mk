# Set SDK root dir
SDK_ROOT := $(PWD)/../../..

# Set rootfs type, see buildroot.
# ext4 squashfs 
ROOTFS_TYPE := squashfs 

# Set data partition type.
# ext2 squashfs
OEM_PARTITION_TYPE := ext2

# Set flash type.
# support <emmc, nand, spi_nand, spi_nor>
FLASH_TYPE := nand

# Select Target Product Name
TARGET_PRODUCT := rk3308

DEVICE_DIR := $(PWD)

#OEM config: /oem/dueros/aispeech/iflytekSDK/CaeDemo_VAD
OEM_PATH := oem

# Buildroot config
CFG_BUILDROOT := rockchip_rk3308_release

# Recovery config
CFG_RECOVERY := rockchip_rk3308_recovery

# Pcba config
CFG_PCBA := rockchip_rk3308_pcba


BUILDROOT_PATH := ${SDK_ROOT}/buildroot

RECOVERY_BUILD_OUTPUT := ${BUILDROOT_PATH}/output/recovery
RECOVERY_BUILD_OUTPUT_IMAGE := ${BUILDROOT_PATH}/output/recovery/images
RECOVERY_BUILD_OUTPUT_TARGET := ${BUILDROOT_PATH}/output/recovery/target

PCBA_BUILD_OUTPUT := ${BUILDROOT_PATH}/output/pcba
PCBA_BUILD_OUTPUT_IMAGE := ${BUILDROOT_PATH}/output/pcba/images
PCBA_BUILD_OUTPUT_TARGET := ${BUILDROOT_PATH}/output/pcba/target
