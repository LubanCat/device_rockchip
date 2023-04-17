#!/bin/bash -e

source "${POST_HELPER:-$(dirname "$(realpath "$0")")/../post-hooks/post-helper}"

[ -n "$RK_ROOTFS_HOSTNAME" ] || exit 0

echo "Setting hostname: $RK_ROOTFS_HOSTNAME"
echo "$RK_ROOTFS_HOSTNAME" > "$TARGET_DIR/etc/hostname"
