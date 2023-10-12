#!/bin/bash -e

source "${POST_HELPER:-$(dirname "$(realpath "$0")")/../post-hooks/post-helper}"

[ "$RK_ROOTFS_STRIP_MODULES" ] || exit 0

echo "Strip kernel modules..."

source "$SCRIPTS_DIR/kernel-helper"

find "$TARGET_DIR" -name "*.ko" -print0 | xargs -0 ${RK_KERNEL_TOOLCHAIN}strip
