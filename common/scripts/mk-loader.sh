#!/bin/bash -e

build_uefi()
{
	if [ "$RK_CHIP" != rk3588 -o ! -d uefi ]; then
		echo "UEFI not supported!"
		return 1
	fi

	UEFI_DIR=uefi/edk2-platforms/Platform/Rockchip/DeviceTree

	echo "============Start building uefi============"
	echo "Copy kernel dtb $RK_KERNEL_DTB to $UEFI_DIR/$RK_CHIP.dtb"
	echo "========================================="
	if [ ! -f $RK_KERNEL_DTB ]; then
		echo "$RK_KERNEL_DTB not exists!"
		return 1
	fi

	cp "$RK_KERNEL_DTB" $UEFI_DIR/$RK_CHIP.dtb
	cd uefi
	./make.sh $RK_UBOOT_CFG

	finish_build
}

build_uboot()
{
	check_config RK_UBOOT_CFG || return 0

	echo "============Start building uboot============"
	echo "TARGET_UBOOT_CONFIG=$RK_UBOOT_CFG"
	echo "========================================="

	cd u-boot
	rm -f *.bin *.img

	ARGS="$RK_UBOOT_OPTS \
		${RK_UBOOT_TRUST_INI:+../rkbin/RKTRUST/$RK_UBOOT_TRUST_INI} \
		${RK_UBOOT_SPL_INI:+../rkbin/RKBOOT/$RK_UBOOT_SPL_INI}"

	if [ "$RK_SECURITY" ]; then
		if [ -z "$RK_SECURITY_OTP_DEBUG" ]; then
			ARGS="$ARGS --burn-key-hash"
		fi

		if [ "$RK_AB_UPDATE" ]; then
			DEFAULT_IMAGES=boot
		else
			DEFAULT_IMAGES="boot recovery"
		fi

		for p in ${1:-$DEFAULT_IMAGES}; do
			ARGS="--${p}_img $SDK_DIR/u-boot/$p.img $ARGS"
		done
	fi

	./make.sh CROSS_COMPILE=$CROSS_COMPILE \
		$RK_UBOOT_CFG $RK_UBOOT_CFG_FRAGMENTS $(echo $ARGS)

	cd ..

	if [ "$RK_SECURITY" ];then
		ln -rsf u-boot/boot.img "$RK_FIRMWARE_DIR"
		[ "$RK_AB_UPDATE" ] || \
			ln -rsf u-boot/recovery.img "$RK_FIRMWARE_DIR"
	fi

	LOADER="$(echo u-boot/*_loader_*v*.bin | head -1)"
	SPL="$(echo u-boot/*_loader_spl.bin | head -1)"
	ln -rsf "${LOADER:-$SPL}" "$RK_FIRMWARE_DIR"/MiniLoaderAll.bin

	ln -rsf u-boot/uboot.img "$RK_FIRMWARE_DIR"
	[ ! -e u-boot/trust.img ] || \
		ln -rsf u-boot/trust.img "$RK_FIRMWARE_DIR"

	finish_build
}

build_spl()
{
	check_config RK_UBOOT_SPL_CFG || return 0

	echo "============Start building spl============"
	echo "TARGET_SPL_CONFIG=$RK_UBOOT_SPL_CFG"
	echo "========================================="

	cd u-boot
	rm -f *spl.bin
	./make.sh $RK_UBOOT_SPL_CFG
	./make.sh --spl
	cd ..

	SPL="$(echo u-boot/*_loader_spl.bin | head -1)"
	ln -rsf "$SPL" "$RK_FIRMWARE_DIR"/MiniLoaderAll.bin

	finish_build
}

# Hooks

usage_hook()
{
	echo "loader             - build loader (uboot|spl)"
	echo "uboot              - build u-boot"
	echo "spl                - build spl"
	echo "uefi               - build uefi"
}

clean_hook()
{
	make -C u-boot distclean
}

BUILD_CMDS="loader uboot spl uefi"
build_hook()
{
	TARGET="$1"
	shift

	if [ "$TARGET" = loader ]; then
		if [ $RK_UBOOT_SPL_CFG ]; then
			TARGET=spl
		else
			TARGET=uboot
		fi
	fi

	case "$TARGET" in
		uboot) build_uboot $@ ;;
		spl) build_spl $@ ;;
		uefi) build_uefi $@ ;;
		*) usage ;;
	esac
}

source "${BUILD_HELPER:-$(dirname "$(realpath "$0")")/../build-hooks/build-helper}"

build_hook ${@:-loader}
