#!/bin/bash -e

# Hooks

usage_hook()
{
	echo -e "misc                              \tpack misc image"
}

BUILD_CMDS="misc"
build_hook()
{
	MISC_IMG="$RK_FIRMWARE_DIR/misc.img"
	rm -f "$MISC_IMG"

	[ "$RK_MISC" ] || return 0

	if [ -z "$(rk_partition_size misc)" ]; then
		echo "Misc ignored"
		return 0
	fi

	# The old windows tools don't accept misc > 64K
	truncate -s 48k "$MISC_IMG"

	if [ "$RK_MISC_BLANK" ]; then
		echo "Generated blank misc image"
	elif [ "$RK_MISC_RECOVERY" ]; then
		echo -n "boot-recovery" | \
			dd of="$MISC_IMG" bs=1 seek=$((16*1024)) conv=notrunc
		echo -e -n "recovery\n$RK_MISC_RECOVERY_ARG" | \
			dd of="$MISC_IMG" bs=1 seek=$((16*1024+64)) conv=notrunc
		echo -e "Generated recovery misc with: $RK_MISC_RECOVERY_ARG"
	else
		ln -rvsf "$CHIP_DIR/$RK_MISC_IMG" "$MISC_IMG"
	fi

	echo -e "\e[36m"
	echo "Done packing $MISC_IMG"
	echo -e "\e[0m"

	if grep -wq boot-recovery "$MISC_IMG" && \
		[ -z "$(rk_partition_size recovery)" ]; then
		echo -e "\e[31mRecovery misc requires recovery partition!\e[0m"
		return 1
	fi

	finish_build build_misc
}

source "${BUILD_HELPER:-$(dirname "$(realpath "$0")")/../build-hooks/build-helper}"

build_hook
