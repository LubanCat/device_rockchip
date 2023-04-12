#!/bin/bash -e

SCRIPTS_DIR="${SCRIPTS_DIR:-$(dirname "$(realpath "$0")")}"
SDK_DIR="${SDK_DIR:-$SCRIPTS_DIR/../../../..}"

DEFCONFIG=$1
OUTPUT_DIR="${2:-$SDK_DIR/output/buildroot}"
BUILDROOT_DIR="$SDK_DIR/buildroot"

"$SCRIPTS_DIR/check-buildroot.sh"

source "$BUILDROOT_DIR/build/envsetup.sh" $DEFCONFIG
BUILDROOT_OUTPUT_DIR="$(realpath -e "$BUILDROOT_DIR/output/.board")"

# Use buildroot images dir as image output dir
IMAGE_DIR="$BUILDROOT_OUTPUT_DIR/images"
rm -rf "$OUTPUT_DIR"
mkdir -p "$IMAGE_DIR"
ln -rsf "$IMAGE_DIR" "$OUTPUT_DIR"
cd "${RK_LOG_DIR:-$OUTPUT_DIR}"

LOG_PREFIX="br-$(basename "$BUILDROOT_OUTPUT_DIR")"
LOG_FILE="$(start_log "$LOG_PREFIX" 2>/dev/null || echo $PWD/$LOG_PREFIX.log)"
ln -rsf "$LOG_FILE" br.log

# Buildroot doesn't like it
unset LD_LIBRARY_PATH

if ! "$BUILDROOT_DIR"/utils/brmake -C "$BUILDROOT_DIR"; then
	echo "Failed to build $DEFCONFIG:"
	tail -n 100 "$LOG_FILE"
	echo "Please check details in $LOG_FILE"
	exit 1
fi

echo "Log saved on $LOG_FILE"
echo "Generated images:"
ls "$OUTPUT_DIR"/rootfs.*
