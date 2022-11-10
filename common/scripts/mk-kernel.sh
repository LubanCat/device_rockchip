#!/bin/bash -e

KERNELS=$(ls | grep kernel- || true)

usage_hook()
{
	for k in $KERNELS; do
		echo "${k/-4\.4/-4.4 }        - build kernel ${k#kernel-}"
	done

	echo "kernel             - build kernel"
	echo "modules            - build kernel modules"
}

clean_hook()
{
	make -C kernel distclean
}

PRE_BUILD_CMDS="$KERNELS default"
pre_build_hook()
{
	if echo "$1" | grep -q "kernel-"; then
		RK_KERNEL_VERSION=${1#kernel-}
		return 0
	fi

	# End of pre-build

	# Fallback to current kernel
	RK_KERNEL_VERSION=${RK_KERNEL_VERSION:-$(kernel_version)}

	# Fallback to 5.10 kernel
	RK_KERNEL_VERSION=${RK_KERNEL_VERSION:-5.10}

	sed -i "s/^\(RK_KERNEL_VERSION=\).*/\1\"$RK_KERNEL_VERSION\"/" \
		"$RK_CONFIG"

	[ "$(kernel_version)" != "$RK_KERNEL_VERSION" ] || return 0

	# Update kernel
	KERNEL_DIR=kernel-$RK_KERNEL_VERSION
	echo "switching to $KERNEL_DIR"
	if [ ! -d "$KERNEL_DIR" ]; then
		echo "$KERNEL_DIR not exist!"
		exit 1
	fi

	rm -rf kernel
	ln -rsf $KERNEL_DIR kernel
}

BUILD_CMDS="$KERNELS kernel modules"
build_hook()
{
	check_config RK_KERNEL_DTS_NAME RK_KERNEL_CFG RK_BOOT_IMG || return 0

	echo "============Start building kernel ${1#kernel}============"
	echo "TARGET_KERNEL_VERSION =$RK_KERNEL_VERSION"
	echo "TARGET_KERNEL_ARCH   =$RK_KERNEL_ARCH"
	echo "TARGET_KERNEL_CONFIG =$RK_KERNEL_CFG"
	echo "TARGET_KERNEL_CONFIG_FRAGMENTS =$RK_KERNEL_CFG_FRAGMENTS"
	echo "TARGET_KERNEL_DTS    =$RK_KERNEL_DTS_NAME"
	echo "=========================================="

	$KMAKE $RK_KERNEL_CFG $RK_KERNEL_CFG_FRAGMENTS

	if [ "$1" = modules ]; then
		$KMAKE modules

		shift
		finish_build build_modules
		exit 0
	fi

	$KMAKE $RK_KERNEL_DTS_NAME.img

	ITS="$CHIP_DIR/$RK_BOOT_FIT_ITS"
	if [ -f "$ITS" ]; then
		"$SCRIPTS_DIR/mk-fitimage.sh" kernel/$RK_BOOT_IMG \
			"$ITS" $RK_KERNEL_IMG
	fi

	ln -rsf kernel/$RK_BOOT_IMG "$RK_FIRMWARE_DIR/boot.img"

	[ -z "$RK_SECURITY" ] || cp "$RK_FIRMWARE_DIR/boot.img" u-boot/

	"$SCRIPTS_DIR/check-power-domain.sh"

	finish_build build_kernel
}

source "${BUILD_HELPER:-$(dirname "$(realpath "$0")")/../build-hooks/build-helper}"

case "${1:-kernel}" in
	kernel-*) pre_build_hook $@ ;&
	kernel | modules)
		pre_build_hook
		build_hook ${@:-kernel}
		;;
	*) usage ;;
esac
