#!/bin/bash -e

source "${POST_HELPER:-$(dirname "$(realpath "$0")")/../post-hooks/post-helper}"

[ -n "$RK_ROOTFS_HOSTNAME" ] || exit 0

if [ "$RK_ROOTFS_HOSTNAME" = "<default>" ]; then
	HOSTNAME="$RK_CHIP-$POST_OS"
else
	HOSTNAME="$RK_ROOTFS_HOSTNAME"
fi

echo "Setting hostname: $HOSTNAME"

mkdir -p "$TARGET_DIR/etc"
echo "$HOSTNAME" > "$TARGET_DIR/etc/hostname"

touch "$TARGET_DIR/etc/hosts"
sed -i '/^127.0.1.1/d' "$TARGET_DIR/etc/hosts"
echo "127.0.1.1	$HOSTNAME" >> "$TARGET_DIR/etc/hosts"
