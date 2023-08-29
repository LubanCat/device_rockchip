#!/bin/bash -e

POST_ROOTFS_ONLY=1

source "${POST_HELPER:-$(dirname "$(realpath "$0")")/../post-hooks/post-helper}"

[ -z "$RK_USBMOUNT_DISABLED" ] || exit 0

if [ "$RK_USBMOUNT_DEFAULT" -a "$POST_OS" != yocto ]; then
	echo -e "\e[33mIgnore usbmount for $POST_OS by default\e[0m"
	exit 0
fi

cd "$SDK_DIR"

mkdir -p "$TARGET_DIR/usr/bin/"
install -m 0755 "$RK_TOOL_DIR/armhf/lockfile-create" "$TARGET_DIR/usr/bin/"
install -m 0755 "$RK_TOOL_DIR/armhf/lockfile-remove" "$TARGET_DIR/usr/bin/"

tar xvf "$RK_DATA_DIR"/usbmount-*.tar -C "$TARGET_DIR"

for type in storage udisk sdcard; do
	mkdir -p "$TARGET_DIR/media/$type"{1,2,3}
	mkdir -p "$TARGET_DIR/mnt/$type"
	rm -rf "$TARGET_DIR/media/${type}0"
	ln -sf "/mnt/$type" "$TARGET_DIR/media/${type}0"
done
