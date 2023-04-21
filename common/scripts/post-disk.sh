#!/bin/bash -e

POST_OS_DISALLOWED="recovery pcba"

source "${POST_HELPER:-$(dirname "$(realpath "$0")")/../post-hooks/post-helper}"

[ -n "$RK_RESIZEALL" -o -n "$RK_MOUNTALL" ] || exit 0

install_service()
{
	TYPE=$1

	echo "Installing $TYPE service..."

	install -m 0755 external/rkscript/$TYPE-helper \
		"$TARGET_DIR/usr/bin/"

	if [ -f "$TARGET_DIR/etc/init.d/rcS" ]; then
		install -m 0755 external/rkscript/S21${TYPE}all.sh \
			"$TARGET_DIR/etc/init.d/"
	fi

	[ "$TYPE" = resize ] || return 0

	if [ -d "$TARGET_DIR/lib/systemd/system/" ]; then
		install -m 0755 external/rkscript/$TYPE-all.service \
			"$TARGET_DIR/lib/systemd/system/"
		mkdir -p "$TARGET_DIR/etc/systemd/system/sysinit.target.wants"
		ln -sf /lib/systemd/system/$TYPE-all.service \
			"$TARGET_DIR/etc/systemd/system/sysinit.target.wants/"
	fi

	if [ -d "$TARGET_DIR/etc/rcS.d" ]; then
		install -m 0755 external/rkscript/S21${TYPE}all.sh \
			"$TARGET_DIR/etc/init.d/${TYPE}all.sh"
		ln -sf ../init.d/${TYPE}all.sh \
			"$TARGET_DIR/etc/rcS.d/S04${TYPE}all.sh"
	fi
}

cd "$SDK_DIR"

mkdir -p "$TARGET_DIR/usr/bin"
install -m 0755 external/rkscript/disk-helper "$TARGET_DIR/usr/bin/"

[ -z "$RK_RESIZEALL" ] || install_service resize
[ -z "$RK_MOUNTALL" ] || install_service mount
