#!/bin/bash -e

TARGET_DIR="$1"
[ "$TARGET_DIR" ] || exit 1

OVERLAY_DIR="$(dirname "$(realpath "$0")")"

echo "Installing prebuilt tools: $OVERLAY_DIR to $TARGET_DIR..."

mkdir -p "$TARGET_DIR/usr/local/bin/"
rsync -av --chmod=u=rwX,go=rX --exclude=install.sh --exclude=adbd \
	"$OVERLAY_DIR/" "$TARGET_DIR/usr/local/bin/"
