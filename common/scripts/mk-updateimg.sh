#!/bin/bash -e

RK_PACK_TOOL_DIR="$SDK_DIR/tools/linux/Linux_Pack_Firmware/rockdev"

build_updateimg()
{
	TARGET="${1:-$RK_FIRMWARE_DIR/update.img}"
	OUT_DIR="${2:-$RK_OUTDIR/update}"
	PKG_FILE="${3:-$RK_PACKAGE_FILE}"

	if [ ! -r "$RK_PACK_TOOL_DIR/$PKG_FILE" ]; then
		echo "$RK_PACK_TOOL_DIR/$PKG_FILE not exists!"
		exit 1
	fi

	rm -rf "$OUT_DIR"
	mkdir -p "$OUT_DIR"

	ln -rsf "$RK_FIRMWARE_DIR" "$OUT_DIR/Image"
	ln -rsf "$RK_PACK_TOOL_DIR/$PKG_FILE" "$OUT_DIR/package-file"
	ln -rsf "$RK_PACK_TOOL_DIR/afptool" "$OUT_DIR"
	ln -rsf "$RK_PACK_TOOL_DIR/rkImageMaker" "$OUT_DIR"
	ln -rsf "$RK_PACK_TOOL_DIR/mkupdate.sh" "$OUT_DIR"

	cd "$OUT_DIR"
	./mkupdate.sh

	mv update.img "$TARGET"

	finish_build build_updateimg $@
}

build_ota_updateimg()
{
	check_config RK_AB_UPDATE RK_OTA_PACKAGE_FILE || return 0

	echo "Make A/B update image for OTA"

	build_updateimg "$RK_FIRMWARE_DIR/update_ota.img" "$RK_OUTDIR/ota" \
		$RK_OTA_PACKAGE_FILE

	finish_build
}

build_sdcard_updateimg()
{
	check_config RK_AB_UPDATE RK_AB_UPDATE_SDCARD || return 0

	echo "Make A/B update image for SDcard"

	for f in "$RK_IMAGE_DIR/sdupdate-ab-misc.img" \
		"$RK_IMAGE_DIR/parameter-sdupdate.txt" \
		"$RK_PACK_TOOL_DIR/sdcard-update-package-file" \
		"$RK_FIRMWARE_DIR/recovery.img"; do
		[ ! -r $f ] || continue
		echo "$f not exists!"
		return 1
	done

	build_updateimg "$RK_FIRMWARE_DIR/update_sdcard.img" "$RK_OUTDIR/sdcard" \
		sdcard-update-package-file

	finish_build
}

build_ab_updateimg()
{
	check_config RK_AB_UPDATE || return 0

	build_ota_updateimg
	build_sdcard_updateimg

	echo "Make A/B update image"

	build_updateimg "$RK_FIRMWARE_DIR/update_ab.img" "$RK_OUTDIR/ab"

	finish_build
}

# Hooks

usage_hook()
{
	echo "updateimg          - build update image"
	echo "otapackage         - build OTA update image"
	echo "sdpackage          - build SDcard update image"
}

clean_hook()
{
	rm -rf "$RK_OUTDIR/update"
	rm -rf "$RK_OUTDIR/ota"
	rm -rf "$RK_OUTDIR/sdcard"
	rm -rf "$RK_OUTDIR/ab"
	rm -rf "$RK_FIRMWARE_DIR/*update.img"
}

POST_BUILD_CMDS="updateimg otapackage sdpackage"
post_build_hook()
{
	case "$1" in
		updateimg)
			if [ "$RK_AB_UPDATE" ]; then
				build_ab_updateimg
			else
				build_updateimg
			fi
			;;
		otapackage) build_ota_updateimg ;;
		sdpackage) build_sdcard_updateimg ;;
		*) usage ;;
	esac
}

source "${BUILD_HELPER:-$(dirname "$(realpath "$0")")/../build-hooks/build-helper}"

post_build_hook ${@:-updateimg}
