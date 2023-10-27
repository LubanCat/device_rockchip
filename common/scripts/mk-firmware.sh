#!/bin/bash -e

message() {
	echo -e "\e[36m$@\e[0m"
}

fatal() {
	echo -e "\e[31m$@\e[0m"
	exit 1
}

link_image() {
	SRC="$1"
	DST="$2"
	message "Linking $DST from $SRC..."
	ln -rsf "$SRC" "$DST"
}

build_firmware()
{
	if ! which fakeroot &>/dev/null; then
		echo "fakeroot not found! (sudo apt-get install fakeroot)"
		exit 1
	fi

	mkdir -p "$RK_FIRMWARE_DIR" "$RK_SECURITY_FIRMWARE_DIR"
	if [ "$RK_SECURITY" ]; then
		FIRMWARE_DIR="$RK_SECURITY_FIRMWARE_DIR"
	else
		FIRMWARE_DIR="$RK_FIRMWARE_DIR"
	fi

	rm -rf "$RK_ROCKDEV_DIR"
	ln -rsf "$FIRMWARE_DIR" "$RK_ROCKDEV_DIR"

	"$RK_SCRIPTS_DIR/check-grow-align.sh"

	link_image "$RK_CHIP_DIR/$RK_PARAMETER" "$RK_FIRMWARE_DIR/parameter.txt"

	"$RK_SCRIPTS_DIR/mk-extra-part.sh"

	if [ "$RK_SECURITY" ]; then
		# Link non-security images
		for f in $(ls "$RK_FIRMWARE_DIR/"); do
			if [ -r "$FIRMWARE_DIR/$f" ]; then
				continue
			fi

			link_image "$RK_FIRMWARE_DIR/$f" "$FIRMWARE_DIR/$f"
		done
	fi

	echo "Packed files:"
	for f in "$FIRMWARE_DIR"/*; do
		NAME=$(basename "$f")

		echo -n "$NAME"
		if [ -L "$f" ]; then
			echo -n "($(readlink -f "$f"))"
		fi

		FILE_SIZE=$(ls -lLh $f | xargs | cut -d' ' -f 5)
		echo ": $FILE_SIZE"

		echo "$NAME" | grep -q ".img$" || continue

		# Assert the image's size smaller then the limit
		PART_NAME="${NAME%.img}"
		PART_SIZE_KB="$(rk_partition_size_kb "$PART_NAME")"

		if [ "$PART_NAME" = rootfs -a "$PART_SIZE_KB" -eq 0 ]; then
			PART_NAME=system
			PART_SIZE_KB="$(rk_partition_size_kb "$PART_NAME")"
		fi

		[ ! "$PART_SIZE_KB" -eq 0 ] || continue

		FILE_SIZE_KB="$(( $(stat -Lc "%s" "$f") / 1024 ))"
		if [ "$PART_SIZE_KB" -lt "$FILE_SIZE_KB" ]; then
			fatal "error: $NAME's size exceed parameter's $PART_NAME partition size limit!"
		fi
	done

	[ -z "$RK_UPDATE" ] || "$RK_SCRIPTS_DIR/mk-updateimg.sh"

	message "Images under $RK_ROCKDEV_DIR/ are ready!"

	finish_build
}

# Hooks

usage_hook()
{
	echo -e "firmware                          \tpack and check firmwares"
}

clean_hook()
{
	rm -rf "$RK_FIRMWARE_DIR" "$RK_SECURITY_FIRMWARE_DIR" "$RK_ROCKDEV_DIR"
}

POST_BUILD_CMDS="firmware"
post_build_hook()
{
	echo "=========================================="
	echo "          Start packing firmwares"
	echo "=========================================="

	build_firmware
}

source "${RK_BUILD_HELPER:-$(dirname "$(realpath "$0")")/../build-hooks/build-helper}"

post_build_hook $@
