#!/bin/bash -e

[ "$RK_ROOTFS_FSTRIM" ] || exit 0

TARGET_DIR="$1"
[ "$TARGET_DIR" ] || exit 1

# Systemd should use util-linux's fstrim.timer and fstrim.service
if [ "$POST_INIT_SYSTEMD" ]; then
	notice "Skip fstrim service for systemd..."
	exit 0
fi

OVERLAY_DIR="$(dirname "$(realpath "$0")")"

message "Installing fstrim service to $TARGET_DIR..."

install_sysv_service "$OVERLAY_DIR/S99fstrim" 5 4 3 2 K01 0 1 6
install_busybox_service "$OVERLAY_DIR/S99fstrim"
