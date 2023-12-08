#!/bin/bash -e

usage_hook()
{
	echo -e "pcba                              \tbuild PCBA"
}

clean_hook()
{
	rm -rf buildroot/output/$RK_PCBA_CFG
	rm -rf "$RK_OUTDIR/pcba"

	rm -rf "$RK_FIRMWARE_DIR/pcba.img"
}

BUILD_CMDS="pcba"
build_hook()
{
	check_config RK_PCBA || false

	message "=========================================="
	message "          Start building pcba(buildroot)"
	message "=========================================="

	DST_DIR="$RK_OUTDIR/pcba"
	IMAGE_DIR="$DST_DIR/images"

	"$RK_SCRIPTS_DIR/mk-buildroot.sh" $RK_PCBA_CFG "$IMAGE_DIR"

	"$RK_SCRIPTS_DIR/mk-ramboot.sh" "$DST_DIR" \
		"$IMAGE_DIR/rootfs.cpio.gz"
	ln -rsf "$DST_DIR/ramboot.img" "$RK_FIRMWARE_DIR/pcba.img"

	finish_build build_pcba
}

source "${RK_BUILD_HELPER:-$(dirname "$(realpath "$0")")/../build-hooks/build-helper}"

build_hook $@
