#!/bin/bash -e

source "${POST_HELPER:-$(dirname "$(realpath "$0")")/../post-hooks/post-helper}"

cd "$SDK_DIR"

for overlay in $RK_ROOTFS_OVERLAY_DIRS; do
	[ -d "$overlay" ] || continue
	echo "Installing overlay: $overlay..."
	rsync -av --chmod=u=rwX,go=rX "$overlay/" "$TARGET_DIR/"
done
