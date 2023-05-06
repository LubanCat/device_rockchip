#!/bin/bash -e

BOARD=$(echo ${RK_KERNEL_DTS_NAME:-$(echo "$RK_DEFCONFIG" | \
	sed -n "s/.*\($RK_CHIP.*\)_defconfig/\1/p")} | \
	tr '[:lower:]' '[:upper:]')

build_all()
{
	echo "=========================================="
	echo "          Start building all images"
	echo "=========================================="

	rm -rf $RK_FIRMWARE_DIR
	mkdir -p $RK_FIRMWARE_DIR

	# NOTE: On secure boot-up world, if the images build with fit(flattened image tree)
	#       we will build kernel and ramboot firstly,
	#       and then copy images into u-boot to sign the images.
	if [ -z "$RK_SECURITY" ];then
		"$SCRIPTS_DIR/mk-loader.sh" loader
	fi

	"$SCRIPTS_DIR/mk-security.sh" security_check

	if [ "$RK_KERNEL_CFG" ]; then
		"$SCRIPTS_DIR/mk-kernel.sh"
		"$SCRIPTS_DIR/mk-rootfs.sh"
		"$SCRIPTS_DIR/mk-recovery.sh"
	fi

	if [ "$RK_SECURITY" ];then
		"$SCRIPTS_DIR/mk-loader.sh" loader
	fi

	"$SCRIPTS_DIR/mk-firmware.sh"
	"$SCRIPTS_DIR/mk-updateimg.sh"

	finish_build
}

build_save()
{
	echo "=========================================="
	echo "          Start saving images and build info"
	echo "=========================================="

	shift
	SAVE_DIR="$RK_OUTDIR/$BOARD${1:+/$1}"
	case "$(grep "^ID=" "$RK_OUTDIR/os-release" 2>/dev/null)" in
		ID=buildroot) SAVE_DIR="$SAVE_DIR/BUILDROOT" ;;
		ID=debian) SAVE_DIR="$SAVE_DIR/DEBIAN" ;;
		ID=poky) SAVE_DIR="$SAVE_DIR/YOCTO" ;;
	esac
	[ -n "$1" ] || SAVE_DIR="$SAVE_DIR/$(date  +%Y%m%d_%H%M%S)"
	mkdir -p "$SAVE_DIR"

	echo "Saving into $SAVE_DIR..."

	if [ "$RK_KERNEL_CFG" ]; then
		echo "Saving linux-headers..."
		"$SCRIPTS_DIR/mk-kernel.sh" linux-headers \
			"$SAVE_DIR/linux-headers"

		echo "Saving kernel files..."
		mkdir -p "$SAVE_DIR/kernel"
		cp kernel/.config kernel/System.map kernel/vmlinux \
			$RK_KERNEL_DTB "$SAVE_DIR/kernel"
	fi

	echo "Saving images..."
	rsync -av --chmod=u=rwX,go=rX  "$RK_FIRMWARE_DIR" "$SAVE_DIR/IMAGES/"

	echo "Saving build info..."
	if yes | ${PYTHON3:-python3} .repo/repo/repo manifest -r \
		-o "$SAVE_DIR/manifest.xml"; then
		# Only do this when repositories are available
		echo "Saving patches..."
		PATCHES_DIR="$SAVE_DIR/PATCHES"
		mkdir -p "$PATCHES_DIR"
		.repo/repo/repo forall -j $(( $CPUS + 1 )) -c \
			"\"$SCRIPTS_DIR/save-patches.sh\" \
			\"$PATCHES_DIR/\$REPO_PATH\" \$REPO_PATH \$REPO_LREV"
		install -D -m 0755 "$RK_DATA_DIR/misc/apply-all.sh" \
			"$PATCHES_DIR"
	fi

	cp "$RK_FINAL_ENV" "$RK_CONFIG" "$RK_DEFCONFIG_LINK" "$SAVE_DIR/"
	ln -rsf "$RK_CONFIG" "$SAVE_DIR/build_info"

	echo "Saving build logs..."
	cp -r "$RK_LOG_BASE_DIR" "$SAVE_DIR/"

	finish_build
}

build_allsave()
{
	echo "=========================================="
	echo "          Start building allsave"
	echo "=========================================="

	build_all
	build_save $@

	finish_build
}

# Hooks

usage_hook()
{
	echo "all                - build all images"
	echo "save               - save images and build info"
	echo "allsave            - build all images and save images and build info"
}

clean_hook()
{
	rm -rf "$RK_OUTDIR"/$BOARD*
}

BUILD_CMDS="all allsave"
build_hook()
{
	case "$1" in
		all) build_all ;;
		allsave) build_allsave $@ ;;
	esac
}

POST_BUILD_CMDS="save"
post_build_hook()
{
	build_save $@
}

source "${BUILD_HELPER:-$(dirname "$(realpath "$0")")/../build-hooks/build-helper}"

case "${1:-allsave}" in
	all) build_all ;;
	allsave) build_allsave $@ ;;
	save) build_save $@ ;;
	*) usage ;;
esac
