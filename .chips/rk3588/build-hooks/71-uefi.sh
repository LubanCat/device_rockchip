#!/bin/bash -e

build_uefi()
{
	check_config RK_UBOOT_CFG RK_KERNEL_DTS_NAME || false

	if [ ! -d uefi ]; then
		error "UEFI not supported!"
		return 1
	fi

	if [ ! -r "$RK_KERNEL_DTB" ]; then
		notice "Kernel is not ready, building it for UEFI..."
		"$RK_SCRIPTS_DIR/mk-kernel.sh"
	fi

	UEFI_DIR=uefi/edk2-platforms/Platform/Rockchip/DeviceTree

	run_command cp "$RK_KERNEL_DTB" $UEFI_DIR/$RK_CHIP.dtb
	run_command cd uefi
	run_command $UMAKE $RK_UBOOT_CFG
}

# Hooks

usage_hook()
{
	usage_oneline "uefi[:dry-run]" "build uefi"
}

BUILD_CMDS="uefi"
build_hook()
{
	RK_UBOOT_TOOLCHAIN="$(get_toolchain U-Boot "$RK_UBOOT_ARCH")"
	[ "$RK_UBOOT_TOOLCHAIN" ] || exit 1

	message "Toolchain for UEFI:"
	message "${RK_UBOOT_TOOLCHAIN:-gcc}"
	echo

	export UMAKE="./make.sh CROSS_COMPILE=$RK_UBOOT_TOOLCHAIN"

	if [ "$DRY_RUN" ]; then
		notice "Commands of building UEFI:"
	else
		message "=========================================="
		message "          Start building UEFI"
		message "=========================================="
	fi

	build_uefi

	if [ -z "$DRY_RUN" ]; then
		finish_build build_uefi
	fi
}

build_hook_dry()
{
	DRY_RUN=1 build_hook $@
}

source "${RK_BUILD_HELPER:-$(dirname "$(realpath "$0")")/../../../common/scripts/post-helper}"

build_hook $@
