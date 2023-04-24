#!/bin/bash -e

TARGET_DIR="$1"
[ "$TARGET_DIR" ] || exit 1

OVERLAY_DIR="$(dirname "$(realpath "$0")")"

if [ -x "$TARGET_DIR/usr/bin/weston" ]; then
	echo "Installing weston overlay: $OVERLAY_DIR to $TARGET_DIR..."
	rsync -av --chmod=u=rwX,go=rX "$OVERLAY_DIR/" "$TARGET_DIR/" \
		--exclude="$(basename "$(realpath "$0")")"
fi
