#!/bin/bash -e

source "${POST_HELPER:-$(dirname "$(realpath "$0")")/../post-hooks/post-helper}"

[ -z "$RK_ROOTFS_KEEP_HOSTNAME" ] || exit 0

if [ -z "$RK_ROOTFS_CUSTOM_HOSTNAME" -a "$POST_OS" = debian ]; then
	echo -e "\e[33mKeep original hostname for debian by default\e[0m"
	exit 0
fi

HOSTNAME="${RK_ROOTFS_CUSTOM_HOSTNAME:-"$RK_CHIP-$POST_OS"}"

echo "Setting hostname: $HOSTNAME"

mkdir -p "$TARGET_DIR/etc"
echo "$HOSTNAME" > "$TARGET_DIR/etc/hostname"

touch "$TARGET_DIR/etc/hosts"
sed -i '/^127.0.1.1/d' "$TARGET_DIR/etc/hosts"
echo "127.0.1.1	$HOSTNAME" >> "$TARGET_DIR/etc/hosts"
