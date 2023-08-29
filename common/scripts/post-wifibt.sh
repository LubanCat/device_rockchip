#!/bin/bash -e

POST_ROOTFS_ONLY=1

source "${POST_HELPER:-$(dirname "$(realpath "$0")")/../post-hooks/post-helper}"

build_wifibt()
{
	check_config RK_KERNEL_CFG RK_WIFIBT_CHIP || return 0
	source "$SCRIPTS_DIR/kernel-helper"

	# Detect BT's tty device in runtime
	BT_TTY_DEV="\$(bt-tty)"

	echo "=========================================="
	echo "          Start building wifi/BT ($RK_WIFIBT_CHIP)"
	echo "=========================================="

	if ls "$TARGET_DIR/lib/" 2>/dev/null | grep -wq ld-linux-armhf.so; then
		ROOTFS_ARCH=arm
	else
		ROOTFS_ARCH=arm64
	fi

	RKWIFIBT_DIR="$SDK_DIR/external/rkwifibt"

	OWNER=$(stat --format %U "$RKWIFIBT_DIR")
	if [ "$OWNER" != "root" ]; then
		if [ "${USER:-$(id -un)}" = "root" ]; then
			# Fixing up rkwifibt permissions
			find "$RKWIFIBT_DIR" -user root \
				-exec chown -h -R $OWNER:$OWNER {} \;

			# Sudo to source code owner (for Debian)
			export KMAKE="sudo -u $OWNER $KMAKE"
		else
			# Check for dirty files owned by root
			echo -e "\e[36m"
			if find "$RKWIFIBT_DIR" -user 0 | grep ""; then
				echo -e "\e[31m"
				echo "$RKWIFIBT_DIR is dirty for non-root building!"
				echo "Please clear it:"
				echo "cd $RKWIFIBT_DIR"
				echo "git add -f ."
				echo "sudo git reset --hard"
				echo -e "\e[0m"
				exit 1
			fi
			echo -e "\e[0m"
		fi
	fi

	# Make sure that the kernel is ready
	if [ ! -r kernel/include/generated/asm-offsets.h ]; then
		echo "Kernel is not ready, building it for wifi/BT..."
		"$SCRIPTS_DIR/mk-kernel.sh"
	fi

	# Check kernel config
	WIFI_USB=`grep "CONFIG_USB=y" kernel/.config` || true
	WIFI_SDIO=`grep "CONFIG_MMC=y" kernel/.config` || true
	WIFI_PCIE=`grep "CONFIG_PCIE_DW_ROCKCHIP=y" kernel/.config` || true
	WIFI_RFKILL=`grep "CONFIG_RFKILL=y" kernel/.config` || true
	if [ -z "WIFI_SDIO" ]; then
		echo "=== WARNNING CONFIG_MMC not set !!! ==="
	fi
	if [ -z "WIFI_RFKILL" ]; then
		echo "=== WARNNING CONFIG_USB not set !!! ==="
	fi
	if [[ "$RK_WIFIBT_CHIP" =~ "U" ]];then
		if [ -z "$WIFI_USB" ]; then
			echo "=== WARNNING CONFIG_USB not set so ABORT!!! ==="
			exit 0
		fi
	fi
	echo "kernel config: $WIFI_USB $WIFI_SDIO $WIFI_RFKILL"

	if [[ "$RK_WIFIBT_CHIP" =~ "ALL_AP" ]];then
		echo "building bcmdhd sdio"
		$KMAKE M=$RKWIFIBT_DIR/drivers/bcmdhd CONFIG_BCMDHD=m \
			CONFIG_BCMDHD_SDIO=y CONFIG_BCMDHD_PCIE=
		if [ -n "$WIFI_PCIE" ]; then
			echo "building bcmdhd pcie"
			$KMAKE M=$RKWIFIBT_DIR/drivers/bcmdhd CONFIG_BCMDHD=m \
				CONFIG_BCMDHD_PCIE=y CONFIG_BCMDHD_SDIO=
		fi
		if [ -n "$WIFI_USB" ]; then
			echo "building rtl8188fu usb"
			$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8188fu modules
		fi
		echo "building rtl8189fs sdio"
		$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8189fs modules
		echo "building rtl8723ds sdio"
		$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8723ds modules
		echo "building rtl8821cs sdio"
		$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8821cs modules
		echo "building rtl8822cs sdio"
		$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8822cs modules
		echo "building rtl8852bs sdio"
		$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8852bs modules \
			DRV_PATH=$RKWIFIBT_DIR/drivers/rtl8852bs
		if [ -n "$WIFI_PCIE" ]; then
			echo "building rtl8852be pcie"
			$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8852be modules \
				DRV_PATH=$RKWIFIBT_DIR/drivers/rtl8852be
		fi
	fi

	if [[ "$RK_WIFIBT_CHIP" =~ "ALL_CY" ]];then
		echo "building CYW4354"
		ln -sf chips/CYW4354_Makefile \
			$RKWIFIBT_DIR/drivers/infineon/Makefile
		$KMAKE M=$RKWIFIBT_DIR/drivers/infineon
		echo "building CYW4373"
		ln -sf chips/CYW4373_Makefile \
			$RKWIFIBT_DIR/drivers/infineon/Makefile
		$KMAKE M=$RKWIFIBT_DIR/drivers/infineon
		echo "building CYW43438"
		ln -sf chips/CYW43438_Makefile \
			$RKWIFIBT_DIR/drivers/infineon/Makefile
		$KMAKE M=$RKWIFIBT_DIR/drivers/infineon
		echo "building CYW43455"
		ln -sf chips/CYW43455_Makefile \
			$RKWIFIBT_DIR/drivers/infineon/Makefile
		$KMAKE M=$RKWIFIBT_DIR/drivers/infineon
		echo "building CYW5557X"
		ln -sf chips/CYW5557X_Makefile \
			$RKWIFIBT_DIR/drivers/infineon/Makefile
		$KMAKE M=$RKWIFIBT_DIR/drivers/infineon
		if [ -n "$WIFI_PCIE" ]; then
			echo "building CYW5557X_PCIE"
			ln -sf chips/CYW5557X_PCIE_Makefile \
				$RKWIFIBT_DIR/drivers/infineon/Makefile
			$KMAKE M=$RKWIFIBT_DIR/drivers/infineon
			echo "building CYW54591_PCIE"
			ln -sf chips/CYW54591_PCIE_Makefile \
				$RKWIFIBT_DIR/drivers/infineon/Makefile
			$KMAKE M=$RKWIFIBT_DIR/drivers/infineon
		fi
		echo "building CYW54591"
		ln -sf chips/CYW54591_Makefile \
			$RKWIFIBT_DIR/drivers/infineon/Makefile
		$KMAKE M=$RKWIFIBT_DIR/drivers/infineon

		if [ -n "$WIFI_USB" ]; then
			echo "building rtl8188fu usb"
			$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8188fu modules
		fi
		echo "building rtl8189fs sdio"
		$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8189fs modules
		echo "building rtl8723ds sdio"
		$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8723ds modules
		echo "building rtl8821cs sdio"
		$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8821cs modules
		echo "building rtl8822cs sdio"
		$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8822cs modules
		echo "building rtl8852bs sdio"
		$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8852bs modules \
			DRV_PATH=$RKWIFIBT_DIR/drivers/rtl8852bs
		if [ -n "$WIFI_PCIE" ]; then
			echo "building rtl8852be pcie"
			$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8852be modules \
				DRV_PATH=$RKWIFIBT_DIR/drivers/rtl8852be
		fi
	fi

	if [[ "$RK_WIFIBT_CHIP" =~ "AP6" ]];then
		if [[ "$RK_WIFIBT_CHIP" = "AP6275_PCIE" ]];then
			echo "building bcmdhd pcie driver"
			$KMAKE M=$RKWIFIBT_DIR/drivers/bcmdhd CONFIG_BCMDHD=m \
				CONFIG_BCMDHD_PCIE=y CONFIG_BCMDHD_SDIO=
		else
			echo "building bcmdhd sdio driver"
			$KMAKE M=$RKWIFIBT_DIR/drivers/bcmdhd CONFIG_BCMDHD=m \
				CONFIG_BCMDHD_SDIO=y CONFIG_BCMDHD_PCIE=
		fi
	fi

	if [[ "$RK_WIFIBT_CHIP" = "CYW4354" ]];then
		echo "building CYW4354"
		ln -sf chips/CYW4354_Makefile \
			$RKWIFIBT_DIR/drivers/infineon/Makefile
		$KMAKE M=$RKWIFIBT_DIR/drivers/infineon
	fi

	if [[ "$RK_WIFIBT_CHIP" = "CYW4373" ]];then
		echo "building CYW4373"
		ln -sf chips/CYW4373_Makefile \
			$RKWIFIBT_DIR/drivers/infineon/Makefile
		$KMAKE M=$RKWIFIBT_DIR/drivers/infineon
	fi

	if [[ "$RK_WIFIBT_CHIP" = "CYW43438" ]];then
		echo "building CYW43438"
		ln -sf chips/CYW43438_Makefile \
			$RKWIFIBT_DIR/drivers/infineon/Makefile
		$KMAKE M=$RKWIFIBT_DIR/drivers/infineon
	fi

	if [[ "$RK_WIFIBT_CHIP" = "CYW43455" ]];then
		echo "building CYW43455"
		ln -sf chips/CYW43455_Makefile \
			$RKWIFIBT_DIR/drivers/infineon/Makefile
		$KMAKE M=$RKWIFIBT_DIR/drivers/infineon
	fi

	if [[ "$RK_WIFIBT_CHIP" = "CYW5557X" ]];then
		echo "building CYW5557X"
		ln -sf chips/CYW5557X_Makefile \
			$RKWIFIBT_DIR/drivers/infineon/Makefile
		$KMAKE M=$RKWIFIBT_DIR/drivers/infineon
	fi

	if [[ "$RK_WIFIBT_CHIP" = "CYW5557X_PCIE" ]];then
		echo "building CYW5557X_PCIE"
		ln -sf chips/CYW5557X_PCIE_Makefile \
			$RKWIFIBT_DIR/drivers/infineon/Makefile
		$KMAKE M=$RKWIFIBT_DIR/drivers/infineon
	fi

	if [[ "$RK_WIFIBT_CHIP" = "CYW54591" ]];then
		echo "building CYW54591"
		ln -sf chips/CYW54591_Makefile \
			$RKWIFIBT_DIR/drivers/infineon/Makefile
		$KMAKE M=$RKWIFIBT_DIR/drivers/infineon
	fi

	if [[ "$RK_WIFIBT_CHIP" = "CYW54591_PCIE" ]];then
		echo "building CYW54591_PCIE"
		ln -sf chips/CYW54591_PCIE_Makefile \
			$RKWIFIBT_DIR/drivers/infineon/Makefile
		$KMAKE M=$RKWIFIBT_DIR/drivers/infineon
	fi

	if [[ "$RK_WIFIBT_CHIP" = "RTL8188FU" ]];then
		echo "building rtl8188fu driver"
		$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8188fu modules
	fi

	if [[ "$RK_WIFIBT_CHIP" = "RTL8189FS" ]];then
		echo "building rtl8189fs driver"
		$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8189fs modules
	fi

	if [[ "$RK_WIFIBT_CHIP" = "RTL8723DS" ]];then
		$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8723ds modules
	fi

	if [[ "$RK_WIFIBT_CHIP" = "RTL8821CS" ]];then
		$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8821cs modules
	fi

	if [[ "$RK_WIFIBT_CHIP" = "RTL8822CS" ]];then
		$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8822cs modules
	fi

	if [[ "$RK_WIFIBT_CHIP" = "RTL8852BS" ]];then
		$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8852bs modules
	fi

	if [[ "$RK_WIFIBT_CHIP" = "RTL8852BE" ]];then
		$KMAKE M=$RKWIFIBT_DIR/drivers/rtl8852be modules
	fi

	echo "building realtek bt drivers"
	$KMAKE M=$RKWIFIBT_DIR/drivers/bluetooth_uart_driver
	if [ -n "$WIFI_USB" ]; then
		$KMAKE M=$RKWIFIBT_DIR/drivers/bluetooth_usb_driver
	fi

	mkdir -p $TARGET_DIR/etc/init.d
	mkdir -p $TARGET_DIR/usr/bin/
	mkdir -p $TARGET_DIR/lib/modules/
	mkdir -p $TARGET_DIR/lib/firmware/rtlbt/

	echo "create dir symlinks"
	if [ "$(readlink "$TARGET_DIR/lib")" != "usr/lib" ]; then
		mkdir -p "$TARGET_DIR/usr/lib/"
		rm -rf "$TARGET_DIR/usr/lib/modules"
		ln -rsf "$TARGET_DIR/lib/modules" "$TARGET_DIR/usr/lib/modules"
	fi

	rm -rf "$TARGET_DIR/system"
	mkdir -p "$TARGET_DIR/system/etc" "$TARGET_DIR/system/lib"
	ln -rsf "$TARGET_DIR/lib/firmware" "$TARGET_DIR/system/lib/firmware"
	ln -rsf "$TARGET_DIR/lib/modules" "$TARGET_DIR/system/lib/modules"
	ln -rsf "$TARGET_DIR/lib/firmware" "$TARGET_DIR/system/etc/firmware"

	rm -rf "$TARGET_DIR/vendor"
	ln -rsf "$TARGET_DIR/system" "$TARGET_DIR/vendor"

	echo "copy prebuilt tools/sh to rootfs"
	cp $RKWIFIBT_DIR/bin/$ROOTFS_ARCH/* $TARGET_DIR/usr/bin/
	cp $RKWIFIBT_DIR/sh/wifi_start.sh $TARGET_DIR/usr/bin/
	cp $RKWIFIBT_DIR/sh/wifi_ap6xxx_rftest.sh $TARGET_DIR/usr/bin/
	cp $RKWIFIBT_DIR/conf/wpa_supplicant.conf $TARGET_DIR/etc/
	cp $RKWIFIBT_DIR/conf/dnsmasq.conf $TARGET_DIR/etc/

	cp $RK_DATA_DIR/bt-tty $TARGET_DIR/usr/bin/

	if [[ "$RK_WIFIBT_CHIP" = "ALL_CY" ]];then
		echo "copy infineon/realtek firmware/nvram to rootfs"
		cp $RKWIFIBT_DIR/drivers/infineon/*.ko \
			$TARGET_DIR/lib/modules/ || true
		cp $RKWIFIBT_DIR/firmware/infineon/*/* \
			$TARGET_DIR/lib/firmware/ || true

		cp $RKWIFIBT_DIR/sh/bt_load_broadcom_firmware $TARGET_DIR/usr/bin/
		cp $TARGET_DIR/usr/bin/bt_load_broadcom_firmware \
			$TARGET_DIR/usr/bin/bt_init.sh
		cp $TARGET_DIR/usr/bin/bt_load_broadcom_firmware \
			$TARGET_DIR/usr/bin/bt_pcba_test

		#reatek
		cp $RKWIFIBT_DIR/firmware/realtek/*/* $TARGET_DIR/lib/firmware/
		cp $RKWIFIBT_DIR/firmware/realtek/*/* \
			$TARGET_DIR/lib/firmware/rtlbt/
		cp $RKWIFIBT_DIR/drivers/bluetooth_uart_driver/hci_uart.ko \
			$TARGET_DIR/lib/modules/
		if [ -n "$WIFI_USB" ]; then
			cp $RKWIFIBT_DIR/drivers/bluetooth_usb_driver/rtk_btusb.ko \
				$TARGET_DIR/lib/modules/
		fi

		rm -rf $TARGET_DIR/etc/init.d/S36load_wifi_modules
		cp $RKWIFIBT_DIR/S36load_all_wifi_modules $TARGET_DIR/etc/init.d/
		sed -i "s/BT_TTY_DEV/\/dev\/${BT_TTY_DEV}/g" \
			$TARGET_DIR/etc/init.d/S36load_all_wifi_modules
	fi

	if [[ "$RK_WIFIBT_CHIP" = "ALL_AP" ]];then
		echo "copy ap6xxx firmware/nvram to rootfs"
		cp $RKWIFIBT_DIR/drivers/bcmdhd/*.ko $TARGET_DIR/lib/modules/
		cp $RKWIFIBT_DIR/firmware/broadcom/*/wifi/* \
			$TARGET_DIR/lib/firmware/ || true
		cp $RKWIFIBT_DIR/firmware/broadcom/*/bt/* \
			$TARGET_DIR/lib/firmware/ || true

		cp $RKWIFIBT_DIR/sh/bt_load_broadcom_firmware $TARGET_DIR/usr/bin/
		cp $TARGET_DIR/usr/bin/bt_load_broadcom_firmware \
			$TARGET_DIR/usr/bin/bt_init.sh
		cp $TARGET_DIR/usr/bin/bt_load_broadcom_firmware \
			$TARGET_DIR/usr/bin/bt_pcba_test

		#reatek
		echo "copy realtek firmware/nvram to rootfs"
		cp $RKWIFIBT_DIR/drivers/rtl*/*.ko $TARGET_DIR/lib/modules/
		cp -rf $RKWIFIBT_DIR/firmware/realtek/*/* $TARGET_DIR/lib/firmware/
		cp -rf $RKWIFIBT_DIR/firmware/realtek/*/* \
			$TARGET_DIR/lib/firmware/rtlbt/
		cp $RKWIFIBT_DIR/drivers/bluetooth_uart_driver/hci_uart.ko \
			$TARGET_DIR/lib/modules/
		if [ -n "$WIFI_USB" ]; then
			cp $RKWIFIBT_DIR/drivers/bluetooth_usb_driver/rtk_btusb.ko \
				$TARGET_DIR/lib/modules/
		fi

		echo "copy S36load_wifi_modules to rootfs"
		rm -rf $TARGET_DIR/etc/init.d/S36load_wifi_modules
		cp $RKWIFIBT_DIR/S36load_all_wifi_modules $TARGET_DIR/etc/init.d/
		sed -i "s/BT_TTY_DEV/\/dev\/${BT_TTY_DEV}/g" \
			$TARGET_DIR/etc/init.d/S36load_all_wifi_modules
	fi

	if [[ "$RK_WIFIBT_CHIP" =~ "RTL" ]];then
		echo "Copy RTL file to rootfs"
		if [ -d "$RKWIFIBT_DIR/firmware/realtek/$RK_WIFIBT_CHIP" ]; then
			cp $RKWIFIBT_DIR/firmware/realtek/$RK_WIFIBT_CHIP/* \
				$TARGET_DIR/lib/firmware/rtlbt/
			cp $RKWIFIBT_DIR/firmware/realtek/$RK_WIFIBT_CHIP/* \
				$TARGET_DIR/lib/firmware/
		else
			echo "INFO: $RK_WIFIBT_CHIP isn't bluetooth?"
		fi

		WIFI_KO_DIR=$(echo $RK_WIFIBT_CHIP | tr '[A-Z]' '[a-z]')

		cp $RKWIFIBT_DIR/drivers/$WIFI_KO_DIR/*.ko \
			$TARGET_DIR/lib/modules/

		cp $RKWIFIBT_DIR/sh/bt_load_rtk_firmware $TARGET_DIR/usr/bin/
		sed -i "s/BT_TTY_DEV/\/dev\/${BT_TTY_DEV}/g" \
			$TARGET_DIR/usr/bin/bt_load_rtk_firmware
		if [ -n "$WIFI_USB" ]; then
			cp $RKWIFIBT_DIR/drivers/bluetooth_usb_driver/rtk_btusb.ko \
				$TARGET_DIR/lib/modules/
			sed -i "s/BT_DRV/rtk_btusb/g" \
				$TARGET_DIR/usr/bin/bt_load_rtk_firmware
		else
			cp $RKWIFIBT_DIR/drivers/bluetooth_uart_driver/hci_uart.ko \
				$TARGET_DIR/lib/modules/
			sed -i "s/BT_DRV/hci_uart/g" \
				$TARGET_DIR/usr/bin/bt_load_rtk_firmware
		fi
		cp $TARGET_DIR/usr/bin/bt_load_rtk_firmware \
			$TARGET_DIR/usr/bin/bt_init.sh
		cp $TARGET_DIR/usr/bin/bt_load_rtk_firmware \
			$TARGET_DIR/usr/bin/bt_pcba_test
		rm -rf $TARGET_DIR/etc/init.d/S36load_all_wifi_modules
		cp $RKWIFIBT_DIR/S36load_wifi_modules $TARGET_DIR/etc/init.d/
		sed -i "s/WIFI_KO/\/lib\/modules\/$RK_WIFIBT_CHIP.ko/g" \
			$TARGET_DIR/etc/init.d/S36load_wifi_modules
	fi

	if [[ "$RK_WIFIBT_CHIP" =~ "CYW" ]];then
		echo "Copy CYW file to rootfs"
		#firmware
		cp $RKWIFIBT_DIR/firmware/infineon/$RK_WIFIBT_CHIP/* \
			$TARGET_DIR/lib/firmware/
		cp $RKWIFIBT_DIR/drivers/infineon/*.ko \
			$TARGET_DIR/lib/modules/
		#bt
		cp $RKWIFIBT_DIR/sh/bt_load_broadcom_firmware $TARGET_DIR/usr/bin/
		sed -i "s/BT_TTY_DEV/\/dev\/${BT_TTY_DEV}/g" \
			$TARGET_DIR/usr/bin/bt_load_broadcom_firmware
		sed -i "s/BTFIRMWARE_PATH/\/lib\/firmware\//g" \
			$TARGET_DIR/usr/bin/bt_load_broadcom_firmware
		cp $TARGET_DIR/usr/bin/bt_load_broadcom_firmware \
			$TARGET_DIR/usr/bin/bt_init.sh
		cp $TARGET_DIR/usr/bin/bt_load_broadcom_firmware \
			$TARGET_DIR/usr/bin/bt_pcba_test
		#wifi
		rm -rf $TARGET_DIR/etc/init.d/S36load_all_wifi_modules
		cp $RKWIFIBT_DIR/S36load_wifi_modules $TARGET_DIR/etc/init.d/
		sed -i "s/WIFI_KO/\/lib\/modules\/$RK_WIFIBT_CHIP.ko/g" \
			$TARGET_DIR/etc/init.d/S36load_wifi_modules
	fi

	if [[ "$RK_WIFIBT_CHIP" =~ "AP6" ]];then
		echo "Copy AP file to rootfs"
		#firmware
		cp $RKWIFIBT_DIR/firmware/broadcom/$RK_WIFIBT_CHIP/wifi/* \
			$TARGET_DIR/lib/firmware/
		cp $RKWIFIBT_DIR/firmware/broadcom/$RK_WIFIBT_CHIP/bt/* \
			$TARGET_DIR/lib/firmware/
		cp $RKWIFIBT_DIR/drivers/bcmdhd/*.ko $TARGET_DIR/lib/modules/
		#bt
		cp $RKWIFIBT_DIR/sh/bt_load_broadcom_firmware $TARGET_DIR/usr/bin/
		sed -i "s/BT_TTY_DEV/\/dev\/${BT_TTY_DEV}/g" \
			$TARGET_DIR/usr/bin/bt_load_broadcom_firmware
		sed -i "s/BTFIRMWARE_PATH/\/lib\/firmware\//g" \
			$TARGET_DIR/usr/bin/bt_load_broadcom_firmware
		cp $TARGET_DIR/usr/bin/bt_load_broadcom_firmware \
			$TARGET_DIR/usr/bin/bt_init.sh
		cp $TARGET_DIR/usr/bin/bt_load_broadcom_firmware \
			$TARGET_DIR/usr/bin/bt_pcba_test
		#wifi
		rm -rf $TARGET_DIR/etc/init.d/S36load_all_wifi_modules
		cp $RKWIFIBT_DIR/S36load_wifi_modules $TARGET_DIR/etc/init.d/
		if [[ "$RK_WIFIBT_CHIP" =~ "PCIE" ]];then
			sed -i "s/WIFI_KO/\/lib\/modules\/bcmdhd_pcie.ko/g" \
				$TARGET_DIR/etc/init.d/S36load_wifi_modules
		else
			sed -i "s/WIFI_KO/\/lib\/modules\/bcmdhd.ko/g" \
				$TARGET_DIR/etc/init.d/S36load_wifi_modules
		fi
	fi
}

echo "Building Wifi/BT module and firmwares..."
cd "$SDK_DIR"
build_wifibt
