TOOL_PATH=$(pwd)/build
IMAGE_OUT_PATH=$(pwd)/rockdev
KERNEL_PATH=$(pwd)/kernel
UBOOT_PATH=$(pwd)/u-boot
ROOTFS_PATH=$(pwd)/rootfs
DEVICE_IMG_PATH=$(pwd)/device/rockchip/px3se/rockdev
PARAMETER_PATH=$DEVICE_IMG_PATH/parameter.txt
OEM_IMG_PATH=$DEVICE_IMG_PATH/oem.img
USER_DATA_IMG_PATH=$DEVICE_IMG_PATH/userdata.img
MISC_IMG_PATH=$DEVICE_IMG_PATH/wipe_all-misc.img
ROOTFS_IMG_PATH=$(pwd)/buildroot/output/rockchip_px3se/images/rootfs.ext4
RECOVERY_PATH=$(pwd)/buildroot/output/rockchip_px3se_recovery/images/recovery.img
TRUST_PATH=$UBOOT_PATH/trust.img
BOOT_PATH=$KERNEL_PATH/zboot.img
LOADER_PATH=$UBOOT_PATH/*_loader_*.bin

mkdir -p $IMAGE_OUT_PATH

if [ -f $ROOTFS_IMG_PATH ]
then
	echo -n "create rootfs.img..."
	ln -s -f $ROOTFS_IMG_PATH $IMAGE_OUT_PATH/rootfs.img
	echo "done"
else
	echo -e "\e[31m error: $ROOTFS_IMG_PATH not found! \e[0m"
	exit 0
fi

if [ -f $RECOVERY_PATH ]
then
	echo -n "create recovery.img..."
	ln -s -f $RECOVERY_PATH $IMAGE_OUT_PATH/
	echo "done."
else
	echo -e "\e[31m error: $RECOVERY_PATH not found! \e[0m"
	exit 0
fi

if [ -f $MISC_IMG_PATH ]
then
	echo -n "create misc.img..."
	ln -s -f $MISC_IMG_PATH $IMAGE_OUT_PATH/misc.img
	echo "done."
else
	echo -e "\e[31m error: $MISC_IMG_PATH not found! \e[0m"
	exit 0
fi

if [ -f $PARAMETER_PATH ]
then
	echo -n "create parameter.txt..."
	ln -s -f $PARAMETER_PATH $IMAGE_OUT_PATH/
	echo "done."
else
	echo -e "\e[31m error: $PARAMETER_PATH not found! \e[0m"
	exit 0
fi

if [ -f $OEM_IMG_PATH ]
then
	echo -n "create oem.img..."
	ln -s -f $OEM_IMG_PATH $IMAGE_OUT_PATH/
	echo "done."
else
	echo -e "\e[31m error: $OEM_IMG_PATH not found! \e[0m"
	exit 0
fi

if [ -f $USER_DATA_IMG_PATH ]
then
	echo -n "create userdata.img..."
	ln -s -f $USER_DATA_IMG_PATH $IMAGE_OUT_PATH/
	echo "done."
else
	echo -e "\e[31m error: $USER_DATA_IMG_PATH not found! \e[0m"
	exit 0
fi

if [ -f $UBOOT_PATH/uboot.img ]
then
        echo -n "create uboot.img..."
        ln -s -f $UBOOT_PATH/uboot.img $IMAGE_OUT_PATH/uboot.img
        echo "done."
else
        echo -e "\e[31m error: $UBOOT_PATH/uboot.img not found! Please make it from $UBOOT_PATH first! \e[0m"
	exit 0
fi

if [ -f $TRUST_PATH ]
then
        echo -n "create trust.img..."
        ln -s -f $TRUST_PATH $IMAGE_OUT_PATH/trust.img
        echo "done."
else
        echo -e "\e[31m error: $UBOOT_PATH/trust.img not found! Please make it from $UBOOT_PATH first! \e[0m"
	exit 0
fi

if [ -f $LOADER_PATH ]
then
        echo -n "create loader..."
        ln -s -f $LOADER_PATH $IMAGE_OUT_PATH/MiniLoaderAll.bin
        echo "done."
else
	echo -e "\e[31m error: $UBOOT_PATH/*loader_*.bin not found,or there are multiple loaders! Please make it from $UBOOT_PATH first! \e[0m"
	rm $LOADER_PATH
	exit 0
fi

if [ -f $BOOT_PATH ]
then
	echo -n "create boot.img..."
	ln -s -f $BOOT_PATH $IMAGE_OUT_PATH/boot.img
	echo "done."
else
	echo -e "\e[31m error: $KERNEL_PATH/boot.img not found! \e[0m"
	exit 0
fi

echo -e "\e[36m Image: image in rockdev is ready \e[0m"
