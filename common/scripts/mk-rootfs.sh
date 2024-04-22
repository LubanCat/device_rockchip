#!/bin/bash -e

build_buildroot()
{
	check_config RK_BUILDROOT || false

	IMAGE_DIR="${1:-$RK_OUTDIR/buildroot}"

	BUILDROOT_VERSION=$(grep "export BR2_VERSION := " \
		"$RK_SDK_DIR/buildroot/Makefile" | xargs -n 1 | tail -n 1)

	message "=========================================="
	message "          Start building buildroot($BUILDROOT_VERSION)"
	message "=========================================="

	"$RK_SCRIPTS_DIR/mk-buildroot.sh" $RK_BUILDROOT_CFG "$IMAGE_DIR"

	[ -z "$RK_SECURITY" ] || "$RK_SCRIPTS_DIR/mk-security.sh" system \
		$RK_SECURITY_CHECK_METHOD $IMAGE_DIR/rootfs.$RK_ROOTFS_TYPE

	cat "$RK_LOG_DIR/post-rootfs.log"
	finish_build build_buildroot $@
}

build_yocto()
{
	check_config RK_YOCTO || false

	IMAGE_DIR="${1:-$RK_OUTDIR/yocto}"

	"$RK_SCRIPTS_DIR/check-yocto.sh"

	cd yocto
	rm -f build/conf/local.conf

	if [ "$RK_YOCTO_CFG_CUSTOM" ]; then
		if [ ! -r "build/conf/$RK_YOCTO_CFG" ]; then
			error "yocto/build/conf/$RK_YOCTO_CFG not exist!"
			return 1
		fi

		if [ "$RK_YOCTO_CFG" != local.conf ]; then
			ln -sf "$RK_YOCTO_CFG" build/conf/local.conf
		fi

		message "=========================================="
		message "          Start building for $RK_YOCTO_CFG"
		message "=========================================="
	else
		{
			echo "include include/common.conf"
			echo "include include/debug.conf"
			echo "include include/display.conf"
			echo "include include/multimedia.conf"
			echo "include include/audio.conf"

			if [ "$RK_WIFIBT_CHIP" ]; then
				echo "include include/wifibt.conf"
			fi

			if [ "$RK_YOCTO_CHROMIUM" ]; then
				echo "include include/browser.conf"
			fi

			echo
			echo "DISPLAY_PLATFORM := \"$RK_YOCTO_DISPLAY_PLATFORM\""

			echo
			echo "MACHINE = \"$RK_YOCTO_MACHINE\""
		} > build/conf/local.conf

		message "=========================================="
		message "          Start building for machine($RK_YOCTO_MACHINE)"
		message "=========================================="
	fi

	{
		echo "include include/rksdk.conf"
		echo

		echo "PREFERRED_VERSION_linux-rockchip :=" \
			"\"$RK_KERNEL_VERSION_REAL%\""
		echo "LINUXLIBCVERSION := \"$RK_KERNEL_VERSION_REAL-custom%\""
		case "$RK_CHIP_FAMILY" in
			px30|rk3326|rk3562|rk3566_rk3568|rk3588)
				echo "MALI_VERSION := \"g13p0\"" ;;
		esac
	} > build/conf/rksdk_override.conf

	source oe-init-build-env build
	LANG=en_US.UTF-8 LANGUAGE=en_US.en LC_ALL=en_US.UTF-8 \
		bitbake core-image-minimal -C rootfs \
		-R conf/rksdk_override.conf

	ln -rsf "$PWD/latest/rootfs.img" "$IMAGE_DIR/rootfs.ext4"

	touch "$RK_LOG_DIR/post-rootfs.log"
	cat "$RK_LOG_DIR/post-rootfs.log"
	finish_build build_yocto $@
}

build_debian()
{
	check_config RK_DEBIAN || false

	IMAGE_DIR="${1:-$RK_OUTDIR/debian}"
	ARCH=${RK_DEBIAN_ARCH:-armhf}

	"$RK_SCRIPTS_DIR/check-debian.sh"

	message "=========================================="
	message "          Start building $RK_DEBIAN_VERSION($ARCH)"
	message "=========================================="

	cd debian

	## Not always using full build
	if [ -f $RK_ROOTFS_IMAGE ]; then
	# image build with SDK
		notice "[    Already Exists IMG,  Skip Make Debian Scripts    ]"
		notice "[ Delate $RK_ROOTFS_IMAGE To Rebuild Debian IMG ]"
		ln -rsf "$PWD/$RK_ROOTFS_IMAGE" "$IMAGE_DIR/rootfs.ext4"
	elif [ -f linaro-$RK_ROOTFS_TARGET-rootfs.img  ]; then
	# image build with debian scripts
		notice Use linaro-$RK_ROOTFS_TARGET-rootfs.img to build update.img
		ln -rsf "$PWD/linaro-$RK_ROOTFS_TARGET-rootfs.img" \
			"$IMAGE_DIR/rootfs.ext4"
	else
	# building iamge
		notice "No $RK_ROOTFS_IMAGE, Run Make Debian Scripts"
			if [ ! -f linaro-$RK_DEBIAN_VERSION-$RK_ROOTFS_TARGET-$ARCH-alip-*.tar.gz ]; then
				notice "build linaro-$RK_DEBIAN_VERSION-$RK_ROOTFS_TARGET-$ARCH-alip-*.tar.gz"
				RELEASE=$RK_DEBIAN_VERSION TARGET=$RK_ROOTFS_TARGET ARCH=$ARCH \
					./mk-base-debian.sh
			fi
		RELEASE=$RK_DEBIAN_VERSION TARGET=$RK_ROOTFS_TARGET VERSION=$RK_ROOTFS_DEBUG \
		RK_ROOTFS_IMAGE=$RK_ROOTFS_IMAGE SOC=$RK_CHIP ARCH=$ARCH \
			./mk-rootfs.sh
		ln -rsf "$PWD/$RK_ROOTFS_IMAGE" "$IMAGE_DIR/rootfs.ext4"
	fi

	finish_build build_debian $@
}

build_ubuntu()
{
	check_config RK_UBUNTU || false

	IMAGE_DIR="${1:-$RK_OUTDIR/ubuntu}"
	ARCH=${RK_UBUNTU_ARCH:-armhf}

	# "$RK_SCRIPTS_DIR/check-ubuntu.sh"

	message "=========================================="
	message "          Start building $RK_UBUNTU_VERSION($ARCH)"
	message "=========================================="

	cd "$RK_UBUNTU_NUMBER"

	## Not always using full build
	if [ -f $RK_ROOTFS_IMAGE ]; then
	# image build with SDK
		notice "[    Already Exists IMG,  Skip Make Ubuntu Scripts    ]"
		notice "[ Delate $RK_ROOTFS_IMAGE To Rebuild Ubuntu IMG ]"
		ln -rsf "$PWD/$RK_ROOTFS_IMAGE" "$IMAGE_DIR/rootfs.ext4"
	elif [ -f ubuntu-$RK_ROOTFS_TARGET-rootfs.img  ]; then
	# image build with ubuntu scripts
		notice Use ubuntu-$RK_ROOTFS_TARGET-rootfs.img to build update.img
		ln -rsf "$PWD/ubuntu-$RK_ROOTFS_TARGET-rootfs.img" \
			"$IMAGE_DIR/rootfs.ext4"
	else
	# building iamge
		notice "No $RK_ROOTFS_IMAGE, Run Make Ubuntu Scripts"
			if [ ! -f ubuntu-base-$RK_ROOTFS_TARGET-$ARCH-*.tar.gz ]; then
				notice "build ubuntu-base-$RK_ROOTFS_TARGET-$ARCH-*.tar.gz"
				TARGET=$RK_ROOTFS_TARGET ARCH=$ARCH ./mk-base-ubuntu.sh
			fi
		TARGET=$RK_ROOTFS_TARGET VERSION=$RK_ROOTFS_DEBUG \
		RK_ROOTFS_IMAGE=$RK_ROOTFS_IMAGE SOC=$RK_CHIP ARCH=$ARCH \
			./mk-ubuntu-rootfs.sh
		ln -rsf "$PWD/$RK_ROOTFS_IMAGE" "$IMAGE_DIR/rootfs.ext4"
	fi

	finish_build build_ubuntu $@
}

# Hooks

usage_hook()
{
	echo -e "buildroot-config[:<config>]       \tmodify buildroot defconfig"
	echo -e "bconfig[:<config>]                \talias of buildroot-config"
	echo -e "buildroot-make[:<arg1>:<arg2>]    \trun buildroot make"
	echo -e "bmake[:<arg1>:<arg2>]             \talias of buildroot-make"
	echo -e "rootfs[:<rootfs type>]            \tbuild default rootfs"
	echo -e "buildroot                         \tbuild buildroot rootfs"
	echo -e "yocto                             \tbuild yocto rootfs"
	echo -e "debian                            \tbuild debian rootfs"
	echo -e "ubuntu                            \tbuild ubuntu rootfs"
}

clean_hook()
{
	message "Clean up rootfs ..."

	rm -rf yocto/build/tmp yocto/build/*cache
	sudo rm -rf debian/binary

	if check_config RK_BUILDROOT &>/dev/null; then
		rm -rf buildroot/output/$RK_BUILDROOT_CFG
	fi

	rm -rf "$RK_OUTDIR/buildroot"
	rm -rf "$RK_OUTDIR/yocto"
	rm -rf "$RK_OUTDIR/debian"
	rm -rf "$RK_OUTDIR/ubuntu"
	rm -rf "$RK_OUTDIR/rootfs"
	rm -rf "$RK_FIRMWARE_DIR/rootfs.img"
}

INIT_CMDS="default buildroot debian ubuntu yocto"
init_hook()
{
	load_config RK_ROOTFS
	check_config RK_ROOTFS &>/dev/null || return 0

	# Priority: cmdline > custom env
	if [ "$1" != default ]; then
		export RK_ROOTFS_SYSTEM=$1
		notice "Using rootfs system($RK_ROOTFS_SYSTEM) from cmdline"
	elif [ "$RK_ROOTFS_SYSTEM" ]; then
		export RK_ROOTFS_SYSTEM=${RK_ROOTFS_SYSTEM//\"/}
		notice "Using rootfs system($RK_ROOTFS_SYSTEM) from environment"
	else
		return 0
	fi

	ROOTFS_CONFIG="RK_ROOTFS_SYSTEM=\"$RK_ROOTFS_SYSTEM\""
	ROOTFS_UPPER=$(echo $RK_ROOTFS_SYSTEM | tr 'a-z' 'A-Z')
	ROOTFS_CHOICE="RK_ROOTFS_SYSTEM_$ROOTFS_UPPER"
	if ! grep -q "^$ROOTFS_CONFIG$" "$RK_CONFIG"; then
		if ! grep -wq "$ROOTFS_CHOICE" "$RK_CONFIG"; then
			error "$RK_ROOTFS_SYSTEM not supported!"
			return 1
		fi

		sed -i -e "/RK_ROOTFS_SYSTEM/d" "$RK_CONFIG"
		echo "$ROOTFS_CONFIG" >> "$RK_CONFIG"
		echo "$ROOTFS_CHOICE=y" >> "$RK_CONFIG"
		"$RK_SCRIPTS_DIR/mk-config.sh" olddefconfig &>/dev/null
	fi
}

PRE_BUILD_CMDS="buildroot-config bconfig buildroot-make bmake"
pre_build_hook()
{
	check_config RK_ROOTFS || false

	case "$1" in
		buildroot-make | bmake)
			check_config RK_BUILDROOT || false

			shift
			"$RK_SCRIPTS_DIR/mk-buildroot.sh" \
				$RK_BUILDROOT_CFG make $@
			finish_build buildroot-make $@
			;;
		buildroot-config | bconfig)
			BUILDROOT_BOARD="${2:-"$RK_BUILDROOT_CFG"}"

			[ "$BUILDROOT_BOARD" ] || return 0

			TEMP_DIR=$(mktemp -d)
			unset BUILDROOT_OUTPUT_DIR
			make -C "$RK_SDK_DIR/buildroot" O="$TEMP_DIR" \
				"${BUILDROOT_BOARD}_defconfig" menuconfig
			"$RK_SDK_DIR/buildroot/build/update_defconfig.sh" \
				"$BUILDROOT_BOARD" "$TEMP_DIR"
			rm -rf "$TEMP_DIR"

			finish_build $@
			;;
	esac
}

BUILD_CMDS="rootfs buildroot debian ubuntu yocto"
build_hook()
{
	check_config RK_ROOTFS || false

	if [ -z "$1" -o "$1" = rootfs ]; then
		ROOTFS=${RK_ROOTFS_SYSTEM:-buildroot}
	else
		ROOTFS=$1
	fi

	ROOTFS_IMG=rootfs.${RK_ROOTFS_TYPE}
	ROOTFS_DIR="$RK_OUTDIR/$ROOTFS"
	IMAGE_DIR="$ROOTFS_DIR/images"

	message "=========================================="
	message "          Start building rootfs($ROOTFS)"
	message "=========================================="

	case "$ROOTFS" in
		yocto | debian | ubuntu | buildroot) ;;
		*) usage ;;
	esac

	rm -rf "$ROOTFS_DIR" "$RK_OUTDIR/rootfs"
	mkdir -p "$IMAGE_DIR"
	ln -rsf "$ROOTFS_DIR" "$RK_OUTDIR/rootfs"

	touch "$ROOTFS_DIR/.stamp_build_start"
	case "$ROOTFS" in
		yocto) build_yocto "$IMAGE_DIR" ;;
		debian) build_debian "$IMAGE_DIR" ;;
		ubuntu) build_ubuntu "$IMAGE_DIR" ;;
		buildroot) build_buildroot "$IMAGE_DIR" ;;
	esac
	touch "$ROOTFS_DIR/.stamp_build_finish"

	if [ ! -f "$IMAGE_DIR/$ROOTFS_IMG" ]; then
		error "There's no $ROOTFS_IMG generated..."
		exit 1
	fi

	if [ "$RK_ROOTFS_INITRD" ]; then
		"$RK_SCRIPTS_DIR/mk-ramboot.sh" "$ROOTFS_DIR" \
			"$IMAGE_DIR/$ROOTFS_IMG" "$RK_BOOT_FIT_ITS"
		ln -rsf "$ROOTFS_DIR/ramboot.img" "$RK_FIRMWARE_DIR/boot.img"
	elif [ "$RK_SECURITY_CHECK_SYSTEM_ENCRYPTION" -o \
		"$RK_SECURITY_CHECK_SYSTEM_VERITY" ]; then
		ln -rsf "$IMAGE_DIR/security_system.img" \
			"$RK_FIRMWARE_DIR/rootfs.img"
	else
		ln -rsf "$IMAGE_DIR/$ROOTFS_IMG" "$RK_FIRMWARE_DIR/rootfs.img"
	fi

	finish_build build_rootfs $@
}

source "${RK_BUILD_HELPER:-$(dirname "$(realpath "$0")")/../build-hooks/build-helper}"

case "${1:-rootfs}" in
	buildroot-config | bconfig | buildroot-make | bmake) pre_build_hook $@ ;;
	buildroot | debian | ubuntu | yocto) init_hook $@ ;&
	*) build_hook $@ ;;
esac
