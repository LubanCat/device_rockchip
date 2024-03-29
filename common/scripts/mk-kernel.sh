#!/bin/bash -e

KERNELS=$(ls | grep kernel- || true)

make_kernel_config()
{
	if [ "$RK_CHIP" = "$RK_CHIP_FAMILY" ]; then
		POSSIBLE_FRAGMENTS="$RK_CHIP"
	elif echo "$RK_CHIP" | grep -qE "[0-9][a-z]$"; then
		POSSIBLE_FRAGMENTS="$RK_CHIP_FAMILY ${RK_CHIP%[a-z]} $RK_CHIP"
	else
		POSSIBLE_FRAGMENTS="$RK_CHIP_FAMILY $RK_CHIP"
	fi

	POSSIBLE_FRAGMENTS="$(echo "$POSSIBLE_FRAGMENTS" | xargs -n 1 | uniq | \
		sed "s/\(.*\)/\1.config \1_linux.config/")"

	unset BASIC_CFG_FRAGMENTS
	for cfg in $POSSIBLE_FRAGMENTS; do
		[ -r "kernel/arch/$RK_KERNEL_ARCH/configs/$cfg" ] || continue

		message "# Found kernel's basic config fragment: $cfg"
		BASIC_CFG_FRAGMENTS="$BASIC_CFG_FRAGMENTS $cfg"
	done

	run_command $KMAKE $RK_KERNEL_CFG $BASIC_CFG_FRAGMENTS \
		$RK_KERNEL_CFG_FRAGMENTS
}

do_build()
{
	check_config RK_KERNEL RK_KERNEL_CFG || false

	if [ "$DRY_RUN" ]; then
		notice "Commands of building $1:"
	else
		message "=========================================="
		message "          Start building $1"
		message "=========================================="
	fi

	make_kernel_config

	if [ -z "$DRY_RUN" ]; then
		"$RK_SCRIPTS_DIR/check-kernel.sh"
	fi

	case "$1" in
		kernel-config | kconfig)
			KERNEL_CONFIG_DIR="kernel/arch/$RK_KERNEL_ARCH/configs"
			run_command $KMAKE menuconfig
			run_command $KMAKE savedefconfig
			run_command mv kernel/defconfig \
				"$KERNEL_CONFIG_DIR/$RK_KERNEL_CFG"
			;;
		kernel*)
			run_command $KMAKE "$RK_KERNEL_DTS_NAME.img"

			# The FIT image for initrd would be packed in rootfs stage
			if [ -n "$RK_BOOT_FIT_ITS" ] && \
				[ -z "$RK_ROOTFS_INITRD" ]; then
				run_command "$RK_SCRIPTS_DIR/mk-fitimage.sh" \
					"kernel/$RK_BOOT_IMG" \
					"$RK_BOOT_FIT_ITS" \
					"$RK_KERNEL_IMG" "$RK_KERNEL_DTB" \
					"kernel/resource.img"
			fi

			if [ "$RK_SECURITY" ]; then
				if [ "$RK_SECURITY_CHECK_BASE" ]; then
					run_command \
						"$RK_SCRIPTS_DIR/mk-security.sh" \
						sign boot "kernel/$RK_BOOT_IMG" \
						$RK_FIRMWARE_DIR/
				fi
			else
				run_command ln -rsf "kernel/$RK_BOOT_IMG" \
					"$RK_FIRMWARE_DIR/boot.img"
			fi

			[ -z "$DRY_RUN" ] || return 0

			"$RK_SCRIPTS_DIR/check-power-domain.sh"
			"$RK_SCRIPTS_DIR/check-security.sh" kernel dts

			if [ "$RK_WIFIBT" ] && \
				! grep -wq wireless-bluetooth "$RK_KERNEL_DTB"; then
				error "Missing wireless-bluetooth in $RK_KERNEL_DTS!"
			fi
			;;
		modules) run_command $KMAKE modules ;;
	esac
}

build_recovery_kernel()
{
	check_config RK_KERNEL || false

	if [ "$DRY_RUN" ]; then
		notice "Commands of building $1:"
	else
		message "=========================================="
		message "          Start building $1"
		message "=========================================="
	fi

	if [ -z "$RK_KERNEL_RECOVERY_CFG" ]; then
		RECOVERY_KERNEL_DIR=kernel
		do_build kernel
	else
		RECOVERY_KERNEL_DIR="$RK_OUTDIR/recovery-kernel"
		run_command mkdir -p "$RECOVERY_KERNEL_DIR"

		# HACK: Fake mrproper
		run_command tar cf "$RK_OUTDIR/kernel.tar" \
			--remove-files --ignore-failed-read \
			kernel/.config kernel/include/config \
			kernel/arch/$RK_KERNEL_ARCH/include/generated

		KMAKE="$KMAKE O=$RECOVERY_KERNEL_DIR"
		run_command $KMAKE $RK_KERNEL_RECOVERY_CFG
		run_command $KMAKE "$RK_KERNEL_DTS_NAME.img"

		run_command tar xf "$RK_OUTDIR/kernel.tar"
		run_command rm -f "$RK_OUTDIR/kernel.tar"
	fi

	run_command ln -rsf \
		"$RECOVERY_KERNEL_DIR/${RK_KERNEL_IMG#kernel/}" \
		"$RK_OUTDIR/recovery-kernel.img"
	run_command ln -rsf \
		"$RECOVERY_KERNEL_DIR/${RK_KERNEL_DTB#kernel/}" \
		"$RK_OUTDIR/recovery-kernel.dtb"
	run_command ln -rsf \
		"$RECOVERY_KERNEL_DIR/resource.img" \
		"$RK_OUTDIR/recovery-resource.img"
}

# Hooks

usage_hook()
{
	for k in $KERNELS; do
		echo -e "$k[:cmds]               \tbuild kernel ${k#kernel-}"
	done

	echo -e "kernel[:cmds]                    \tbuild kernel"
	echo -e "recovery-kernel[:cmds]           \tbuild kernel for recovery"
	echo -e "modules[:cmds]                   \tbuild kernel modules"
	echo -e "linux-headers[:cmds]             \tbuild linux-headers"
	echo -e "kernel-config[:cmds]             \tmodify kernel defconfig"
	echo -e "kconfig[:cmds]                   \talias of kernel-config"
	echo -e "kernel-make[:<arg1>:<arg2>]      \trun kernel make"
	echo -e "kmake[:<arg1>:<arg2>]            \talias of kernel-make"
}

clean_hook()
{
	[ ! -d kernel ] || make -C kernel distclean

	rm -rf "$RK_OUTDIR/recovery-*"
	rm -f "$RK_FIRMWARE_DIR/linux-headers.tar"
	rm -rf "$RK_FIRMWARE_DIR/boot.img"
}

INIT_CMDS="default $KERNELS"
init_hook()
{
	load_config RK_KERNEL_CFG
	check_config RK_KERNEL_CFG &>/dev/null || return 0

	# Priority: cmdline > env > last selected > preferred > current symlink
	if echo $1 | grep -q "^kernel-"; then
		export RK_KERNEL_VERSION=${1#kernel-}
		notice "Using kernel version($RK_KERNEL_VERSION) from cmdline"
	elif [ "$RK_KERNEL_VERSION" ]; then
		export RK_KERNEL_VERSION=${RK_KERNEL_VERSION//\"/}
		notice "Using kernel version($RK_KERNEL_VERSION) from environment"
	fi

	load_config RK_KERNEL_PREFERRED

	local KERNEL_LAST="$(cat "$RK_OUTDIR/.kernel" 2>/dev/null || true)"
	local KERNEL_CURRENT="$(kernel_version)"

	# Fallback to last
	RK_KERNEL_VERSION=${RK_KERNEL_VERSION:-$KERNEL_LAST}

	# Fallback to preferred
	RK_KERNEL_VERSION=${RK_KERNEL_VERSION:-$RK_KERNEL_PREFERRED}

	# Fallback to current
	RK_KERNEL_VERSION=${RK_KERNEL_VERSION:-$KERNEL_CURRENT}

	# Fallback to 5.10
	RK_KERNEL_VERSION=${RK_KERNEL_VERSION:-5.10}

	# Save the selected version
	echo "$RK_KERNEL_VERSION" > "$RK_OUTDIR/.kernel"

	[ "$RK_KERNEL_VERSION" != "$KERNEL_CURRENT" ] || return 0

	# Update kernel
	KERNEL_DIR=kernel-$RK_KERNEL_VERSION
	notice "\nSwitching to $KERNEL_DIR"
	if [ ! -d "$KERNEL_DIR" ]; then
		error "$KERNEL_DIR not exist!"
		exit 1
	fi

	rm -rf kernel
	ln -rsf $KERNEL_DIR kernel
}

PRE_BUILD_CMDS="kernel-config kconfig kernel-make kmake"
pre_build_hook()
{
	check_config RK_KERNEL RK_KERNEL_CFG || false
	source "$RK_SCRIPTS_DIR/kernel-helper"

	message "Toolchain for kernel:"
	message "${RK_KERNEL_TOOLCHAIN:-gcc}"
	echo

	case "$1" in
		kernel-make | kmake)
			shift
			[ "$1" != cmds ] || shift

			if [ "$DRY_RUN" ]; then
				notice "Commands of building ${@:-stuff}:"
			else
				message "=========================================="
				message "          Start building $@"
				message "=========================================="
			fi

			if [ ! -r kernel/.config ]; then
				make_kernel_config
			fi
			run_command $KMAKE $@
			;;
		kernel-config | kconfig)
			do_build $@
			;;
	esac

	if [ -z "$DRY_RUN" ]; then
		finish_build $@
	fi
}

pre_build_hook_dry()
{
	DRY_RUN=1 pre_build_hook $@
}

BUILD_CMDS="$KERNELS kernel recovery-kernel modules"
build_hook()
{
	check_config RK_KERNEL RK_KERNEL_CFG || false
	source "$RK_SCRIPTS_DIR/kernel-helper"

	message "Toolchain for kernel:"
	message "${RK_KERNEL_TOOLCHAIN:-gcc}"
	echo

	case "$1" in
		recovery-kernel) build_recovery_kernel $@ ;;
		kernel-*)
			if [ "$RK_KERNEL_VERSION" != "${1#kernel-}" ]; then
				warning "Kernel version ${1#kernel-} ignored"
			fi
			;&
		*) do_build $@ ;;
	esac

	finish_build build_$1
}

build_hook_dry()
{
	DRY_RUN=1 build_hook $@
}

POST_BUILD_CMDS="linux-headers"
post_build_hook()
{
	check_config RK_KERNEL RK_KERNEL_CFG || false
	source "$RK_SCRIPTS_DIR/kernel-helper"

	[ "$1" = "linux-headers" ] || return 0
	shift

	[ "$1" != cmds ] || shift
	OUTPUT_FILE="${1:-"$RK_OUTDIR"}/linux-headers.tar"
	mkdir -p "$(dirname "$OUTPUT_FILE")"

	HEADER_FILES_SCRIPT=$(mktemp)

	if [ "$DRY_RUN" ]; then
		notice "Commands of building linux-headers:"
	else
		notice "Saving linux-headers to $OUTPUT_FILE"
	fi

	# Preparing kernel
	make_kernel_config
	run_command $KMAKE $RK_KERNEL_IMG_NAME

	# Packing headers
	cat << EOF > "$HEADER_FILES_SCRIPT"
{
	# Based on kernel/scripts/package/builddeb
	find . arch/$RK_KERNEL_ARCH -maxdepth 1 -name Makefile\*
	find include -type f -o -type l
	find arch/$RK_KERNEL_ARCH -name module.lds -o -name Kbuild.platforms -o -name Platform
	find \$(find arch/$RK_KERNEL_ARCH -name include -o -name scripts -type d) -type f
	find arch/$RK_KERNEL_ARCH/include Module.symvers -type f
	echo .config
} | tar --no-recursion --ignore-failed-read -T - \
	-cf "$OUTPUT_FILE"
EOF

	run_command cd "$RK_SDK_DIR/kernel"

	cat "$HEADER_FILES_SCRIPT"

	if [ -z "$DRY_RUN" ]; then
		. "$HEADER_FILES_SCRIPT"
	fi

	# Packing kbuild
	case "$RK_KERNEL_KBUILD_ARCH" in
		host) run_command tar -uf "$OUTPUT_FILE" scripts tools ;;
		*)
			run_command cd "$RK_KBUILD_DIR/$RK_KERNEL_KBUILD_ARCH"
			run_command cd "linux-kbuild-$RK_KERNEL_VERSION_RAW"
			run_command tar -uf "$OUTPUT_FILE" .
			;;
	esac

	run_command cd "$RK_SDK_DIR"

	rm -f "$HEADER_FILES_SCRIPT"

	[ -z "$DRY_RUN" ] || return 0

	case "$RK_KERNEL_KBUILD_ARCH" in
		host)
			if [ $(uname -m) = x86_64 ]; then
				DEBIAN_ARCH=amd64
			else
				return 0
			fi
			;;
		*) DEBIAN_ARCH="$RK_KERNEL_KBUILD_ARCH" ;;
	esac

	# Packing .deb package
	TEMP_DIR="$(mktemp -d)"
	DEBIAN_PKG="linux-headers-${RK_KERNEL_VERSION_RAW}-$RK_KERNEL_ARCH"
	DEBIAN_DIR="$TEMP_DIR/${DEBIAN_PKG}_$DEBIAN_ARCH"
	DEBIAN_KBUILD_DIR="$DEBIAN_DIR/usr/src/$DEBIAN_PKG"
	DEBIAN_DEB="$DEBIAN_DIR.deb"
	DEBIAN_CONTROL="$DEBIAN_DIR/DEBIAN/control"
	mkdir -p "$(dirname "$DEBIAN_CONTROL")" "$DEBIAN_KBUILD_DIR"

	message "Unpacking $OUTPUT_FILE ..."
	tar xf "$OUTPUT_FILE" -C "$DEBIAN_KBUILD_DIR"
	cat << EOF > "$DEBIAN_CONTROL"
Package: $DEBIAN_PKG
Source: linux-rockchip ($RK_KERNEL_VERSION_RAW)
Version: $RK_KERNEL_VERSION_RAW-rockchip
Architecture: $DEBIAN_ARCH
Section: kernel
Priority: optional
Multi-Arch: foreign
Maintainer: Tao Huang <huangtao@rock-chips.com>
Homepage: https://www.kernel.org/
Description: Kbuild and headers for Rockchip Linux $RK_KERNEL_VERSION_RAW $RK_KERNEL_ARCH configuration
EOF

	message "Debian control file:"
	cat "$DEBIAN_CONTROL"

	message "Packing $(basename "$DEBIAN_DEB")..."
	dpkg-deb -b "$DEBIAN_DIR" >/dev/null 2>&1
	mv "$DEBIAN_DEB" "$(dirname "$OUTPUT_FILE")"

	rm -rf "$TEMP_DIR"
}

post_build_hook_dry()
{
	DRY_RUN=1 post_build_hook $@
}

source "${RK_BUILD_HELPER:-$(dirname "$(realpath "$0")")/../build-hooks/build-helper}"

case "${1:-kernel}" in
	kernel-config | kconfig | kernel-make | kmake) pre_build_hook $@ ;;
	kernel* | recovery-kernel | modules)
		init_hook $@
		build_hook ${@:-kernel}
		;;
	linux-headers) post_build_hook $@ ;;
	*) usage ;;
esac
