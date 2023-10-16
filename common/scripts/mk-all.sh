#!/bin/bash -e

BOARD=$(echo ${RK_KERNEL_DTS_NAME:-$(echo "$RK_DEFCONFIG" | \
	sed -n "s/.*\($RK_CHIP.*\)_defconfig/\1/p")} | \
	tr '[:lower:]' '[:upper:]')

build_all()
{
	echo "=========================================="
	echo "          Start building all images"
	echo "=========================================="

	rm -rf "$RK_FIRMWARE_DIR" "$RK_SECURITY_FIRMWARE_DIR"
	mkdir -p "$RK_FIRMWARE_DIR" "$RK_SECURITY_FIRMWARE_DIR"

	[ -z "$RK_SECURITY" ] || "$SCRIPTS_DIR/mk-security.sh" security_check

	[ -z "$RK_KERNEL" ] || "$SCRIPTS_DIR/mk-kernel.sh"
	[ -z "$RK_ROOTFS"] || "$SCRIPTS_DIR/mk-rootfs.sh"
	[ -z "$RK_RECOVERY" ] || "$SCRIPTS_DIR/mk-recovery.sh"

	[ -z "$RK_RTOS" ] || "$SCRIPTS_DIR/mk-rtos.sh"
	[ -z "$RK_SECURITY" ] || "$SCRIPTS_DIR/mk-security.sh" security_ramboot

	# Will repack boot and recovery images when security enabled
	[ -z "$RK_LOADER" ] || "$SCRIPTS_DIR/mk-loader.sh"

	"$SCRIPTS_DIR/mk-firmware.sh"

	finish_build
}

build_release()
{
	echo "=========================================="
	echo "          Start releasing images and build info"
	echo "=========================================="

	shift
	RELEASE_BASE_DIR="$RK_OUTDIR/$BOARD${1:+/$1}"
	case "$(grep "^ID=" "$RK_OUTDIR/os-release" 2>/dev/null)" in
		ID=buildroot) RELEASE_DIR="$RELEASE_BASE_DIR/BUILDROOT" ;;
		ID=debian) RELEASE_DIR="$RELEASE_BASE_DIR/DEBIAN" ;;
		ID=poky) RELEASE_DIR="$RELEASE_BASE_DIR/YOCTO" ;;
		*) RELEASE_DIR="$RELEASE_BASE_DIR" ;;
	esac
	[ "$1" ] || RELEASE_DIR="$RELEASE_DIR/$(date  +%Y%m%d_%H%M%S)"
	mkdir -p "$RELEASE_DIR"
	rm -rf "$RELEASE_BASE_DIR/latest"
	ln -rsf "$RELEASE_DIR" "$RELEASE_BASE_DIR/latest"

	echo "Saving into $RELEASE_DIR..."

	if [ "$RK_KERNEL" ]; then
		mkdir -p "$RELEASE_DIR/kernel"

		echo "Saving linux-headers..."
		"$SCRIPTS_DIR/mk-kernel.sh" linux-headers \
			"$RELEASE_DIR/kernel"

		echo "Saving kernel files..."
		cp kernel/.config kernel/System.map kernel/vmlinux \
			$RK_KERNEL_DTB "$RELEASE_DIR/kernel"
	fi

	echo "Saving images..."
	mkdir -p "$RELEASE_DIR/IMAGES"
	cp "$RK_FIRMWARE_DIR"/* "$RELEASE_DIR/IMAGES/"

	echo "Saving build info..."
	if yes | ${PYTHON3:-python3} .repo/repo/repo manifest -r \
		-o "$RELEASE_DIR/manifest.xml"; then
		# Only do this when repositories are available
		echo "Saving patches..."
		PATCHES_DIR="$RELEASE_DIR/PATCHES"
		mkdir -p "$PATCHES_DIR"
		.repo/repo/repo forall -j $(( $CPUS + 1 )) -c \
			"\"$SCRIPTS_DIR/release-patches.sh\" \
			\"$PATCHES_DIR/\$REPO_PATH\" \$REPO_PATH \$REPO_LREV"
		install -D -m 0755 "$RK_DATA_DIR/apply-all.sh" "$PATCHES_DIR"
	fi

	cp "$RK_FINAL_ENV" "$RK_CONFIG" "$RK_DEFCONFIG_LINK" "$RELEASE_DIR/"
	ln -sf .config "$RELEASE_DIR/build_info"

	echo "Saving build logs..."
	cp -rp "$RK_LOG_BASE_DIR" "$RELEASE_DIR/"

	finish_build
}

build_all_release()
{
	echo "=========================================="
	echo "          Start building and releasing images"
	echo "=========================================="

	build_all
	build_release $@

	finish_build
}

# Hooks

usage_hook()
{
	echo -e "all                               \tbuild images"
	echo -e "release                           \trelease images and build info"
	echo -e "save                              \talias of release"
	echo -e "all-release                       \tbuild and release images"
	echo -e "allsave                           \talias of all-release"
}

clean_hook()
{
	rm -rf "$RK_OUTDIR" "$RK_OUTDIR"/$BOARD*
}

BUILD_CMDS="all all-release allsave"
build_hook()
{
	case "$1" in
		all) build_all ;;
		all-release | allsave) build_all_release $@ ;;
	esac
}

POST_BUILD_CMDS="release save"
post_build_hook()
{
	build_release $@
}

source "${BUILD_HELPER:-$(dirname "$(realpath "$0")")/../build-hooks/build-helper}"

case "${1:-all-release}" in
	all) build_all ;;
	all-release | allsave) build_all_release $@ ;;
	release | save) build_release $@ ;;
	*) usage ;;
esac
