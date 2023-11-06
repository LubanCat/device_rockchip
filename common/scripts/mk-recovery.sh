#!/bin/bash -e

usage_hook()
{
	echo -e "recovery                          \tbuild recovery"
}

clean_hook()
{
	rm -rf buildroot/output/$RK_RECOVERY_CFG
	rm -rf "$RK_OUTDIR/recovery"

	rm -rf "$RK_FIRMWARE_DIR/recovery.img"
	rm -rf "$RK_ROCKDEV_DIR/recovery.img"
}

BUILD_CMDS="recovery"
build_hook()
{
	check_config RK_RECOVERY || false

	message "=========================================="
	message "          Start building recovery(buildroot)"
	message "=========================================="


	DST_DIR="$RK_OUTDIR/recovery/images"
	mkdir -p "$DST_DIR"

	touch "$(dirname "$DST_DIR")/.stamp_build_start"
	"$RK_SCRIPTS_DIR/mk-buildroot.sh" $RK_RECOVERY_CFG "$DST_DIR"
	touch "$(dirname "$DST_DIR")/.stamp_build_finish"

	"$RK_SCRIPTS_DIR/mk-ramdisk.sh" "$DST_DIR/rootfs.cpio.gz" \
		"$DST_DIR/recovery.img" "$RK_RECOVERY_FIT_ITS"
	ln -rsf "$DST_DIR/recovery.img" "$RK_FIRMWARE_DIR"

	finish_build build_recovery
}

source "${RK_BUILD_HELPER:-$(dirname "$(realpath "$0")")/../build-hooks/build-helper}"

build_hook $@
