#!/bin/bash -e

TARGET_DIR="$1"
POST_OS="$2"
[ "$TARGET_DIR" ] || exit 1

OVERLAY_DIR="$(dirname "$(realpath "$0")")"

rm -f "$TARGET_DIR/usr/bin/modetest"
mkdir -p "$TARGET_DIR/usr/local/bin"
install -m 0755 "$RK_TOOL_DIR/armhf/modetest" "$TARGET_DIR/usr/local/bin/"
install -m 0755 "$RK_TOOL_DIR/armhf/kmsgrab" "$TARGET_DIR/usr/local/bin/"

rsync -av --chmod=u=rwX,go=rX --exclude=install.sh "$OVERLAY_DIR/" "$TARGET_DIR/"
