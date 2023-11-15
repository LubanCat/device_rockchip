#!/bin/bash -e

POST_ROOTFS_ONLY=1

source "${RK_POST_HELPER:-$(dirname "$(realpath "$0")")/../post-hooks/post-helper}"

remove_usb()
{
	find "$TARGET_DIR/etc" "$TARGET_DIR/lib" "$TARGET_DIR/usr" \
		-name "*usbdevice*" -print0 -o -name ".usb_config" -print0 \
		2>/dev/null | xargs -0 rm -rf
}

install_adbd()
{
	[ -n "$RK_USB_ADBD" ] || return 0

	message "Installing adbd..."

	find "$TARGET_DIR" -name "*adbd*" -print0 | xargs -0 rm -rf

	install -m 0755 "$RK_TOOL_DIR/armhf/adbd" "$TARGET_DIR/usr/bin/adbd"

	if [ "$RK_USB_ADBD_TCP_PORT" -ne 0 ]; then
		echo "export ADB_TCP_PORT=$RK_USB_ADBD_TCP_PORT" >> \
			"$TARGET_DIR/etc/profile.d/adbd.sh"
	fi

	if [ -n "$RK_USB_ADBD_BASH" -a -x "$TARGET_DIR/bin/bash" ]; then
		echo "export ADBD_SHELL=/bin/bash" >> \
			"$TARGET_DIR/etc/profile.d/adbd.sh"
	fi

	echo -e "#!/bin/sh\ntail -f \${@:--n 99999999} /var/log/messages" > \
		"$TARGET_DIR/usr/bin/logcat"
	chmod 755 "$TARGET_DIR/usr/bin/logcat"

	[ -n "$RK_USB_ADBD_SECURE" ] || return 0

	echo "export ADB_SECURE=1" >> "$TARGET_DIR/etc/profile.d/adbd.sh"

	if [ -n "$RK_USB_ADBD_PASSWORD" ]; then
		ADBD_PASSWORD_MD5="$(echo $RK_USB_ADBD_PASSWORD | md5sum)"
		install -m 0755 "$RK_DATA_DIR/adbd-auth" \
			"$TARGET_DIR/usr/bin/adbd-auth"
		sed -i "s/ADBD_PASSWORD_MD5/$ADBD_PASSWORD_MD5/g" \
			"$TARGET_DIR/usr/bin/adbd-auth"
	fi

	[ "$RK_USB_ADBD_KEYS" ] || return 0

	sudo -u "#$RK_OWNER_UID" sh -c "cat $RK_USB_ADBD_KEYS" > \
		"$TARGET_DIR/adb_keys"
}

install_ums()
{
	[ -n "$RK_USB_UMS" ] || return 0

	message "Installing UMS..."

	{
		echo "export UMS_FILE=${RK_USB_UMS_FILE:-/userdata/ums_shared.img}"
		echo "export UMS_SIZE=${RK_USB_UMS_SIZE:-256M}"
		echo "export UMS_FSTYPE=${RK_USB_UMS_FSTYPE:-vfat}"
		echo "export UMS_MOUNT=$([ -z "$RK_USB_UMS_MOUNT" ] || echo 1)"
		echo "export UMS_MOUNTPOINT=${RK_USB_UMS_MOUNTPOINT:-/mnt/ums}"
		echo "export UMS_RO=$([ -z "$RK_USB_UMS_RO" ] || echo 1)"
	} >> "$TARGET_DIR/etc/profile.d/usbdevice.sh"
}

usb_funcs()
{
	{
		echo "${RK_USB_ADBD:+adb}"
		echo "${RK_USB_MTP:+mtp}"
		echo "${RK_USB_ACM:+acm}"
		echo "${RK_USB_NTB:+ntb}"
		echo "${RK_USB_UVC:+uvc}"
		echo "${RK_USB_UAC1:+uac1}"
		echo "${RK_USB_UAC2:+uac2}"
		echo "${RK_USB_HID:+hid}"
		echo "${RK_USB_RNDIS:+rndis}"
		echo "${RK_USB_UMS:+ums}"
		echo "$RK_USB_EXTRA"
	} | xargs
}

if [ "$RK_USB_DISABLED" ]; then
	notice "Disabling USB gadget..."
	remove_usb
	exit 0
fi

if [ "$RK_USB_DEFAULT" -a "$POST_OS" = buildroot ]; then
	notice "Keep original USB gadget for buildroot by default"
	exit 0
fi

cd "$RK_SDK_DIR"

mkdir -p "$TARGET_DIR/etc" "$TARGET_DIR/lib" "$TARGET_DIR/usr/bin" \
	"$TARGET_DIR/usr/lib"

remove_usb

message "USB gadget functions: $(usb_funcs)"
mkdir -p "$TARGET_DIR/etc/profile.d"
echo "export USB_FUNCS=\"$(usb_funcs)\"" > "$TARGET_DIR/etc/profile.d/usbdevice.sh"

install_adbd
install_ums

mkdir -p "$TARGET_DIR/lib/udev/rules.d"
install -m 0644 external/rkscript/61-usbdevice.rules \
	"$TARGET_DIR/lib/udev/rules.d/"

install -m 0755 external/rkscript/usbdevice "$TARGET_DIR/usr/bin/"

message "Installing USB services..."

install_sysv_service external/rkscript/S*usbdevice.sh 5 4 3 2 K01 0 1 6
install_busybox_service external/rkscript/S*usbdevice.sh
install_systemd_service external/rkscript/usbdevice.service

mkdir -p "$TARGET_DIR/etc/usbdevice.d"
for hook in $RK_USB_HOOKS; do
	if [ -r "$RK_CHIP_DIR/$hook" ]; then
		hook="$RK_CHIP_DIR/$hook"
	elif [ ! -r "$hook" ]; then
		warning "Ignore non-existant USB hook: $hook"
		continue
	fi

	message "Installing USB hook: $hook"
	install -m 0644 "$hook" "$TARGET_DIR/etc/usbdevice.d/"
done
