#!/bin/bash -e

DEFCONFIG=$1
OUTPUT_DIR="$2"
BUILDROOT_DIR="${SDK_DIR:-$PWD}/buildroot"

source "$BUILDROOT_DIR/build/envsetup.sh" $DEFCONFIG

# Use buildroot images dir as image output dir
IMAGE_DIR="$TARGET_OUTPUT_DIR"/images
rm -rf "$OUTPUT_DIR"
mkdir -p "$IMAGE_DIR"
ln -rsf "$IMAGE_DIR" "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

LOG_FILE="$(pwd)/br.log"

if ! "$BUILDROOT_DIR"/utils/brmake -C "$BUILDROOT_DIR"; then
	echo "Failed to build $DEFCONFIG:"
	tail -n 100 "$LOG_FILE"
	echo "Please check details in $LOG_FILE"
	exit 1
fi

echo "Log saved on $LOG_FILE"
echo "Generated images:"
ls rootfs.*
