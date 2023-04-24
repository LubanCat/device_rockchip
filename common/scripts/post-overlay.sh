#!/bin/bash -e

source "${POST_HELPER:-$(dirname "$(realpath "$0")")/../post-hooks/post-helper}"

cd "$SDK_DIR"

for overlay in "$COMMON_DIR/overlays/overlay-$POST_OS" \
	$RK_ROOTFS_OVERLAY_DIRS; do
	[ -d "$overlay" ] || continue

	if [ -x "$overlay/install.sh" ]; then
		echo "Handling overlay: $overlay..."
		"$overlay/install.sh" "$TARGET_DIR" "$POST_OS"
		continue
	fi

	echo "Installing overlay: $overlay to $TARGET_DIR..."
	rsync -av --chmod=u=rwX,go=rX "$overlay/" "$TARGET_DIR/"
done
