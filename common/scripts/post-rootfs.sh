#!/bin/bash -e

echo "Executing $(basename "$BASH_SOURCE")..."

if [ -z "$RK_POST_ROOTFS" ]; then
	# Trigger build.sh's post-rootfs hooks
	SCRIPT_DIR="$(dirname "$(realpath "$BASH_SOURCE")")"
	"$SCRIPT_DIR/build.sh" post-rootfs $@
	exit 0
fi

TARGET_DIR=$(realpath "$1")
IS_RECOVERY=$(echo "$TARGET_DIR" | grep -qvE "_recovery/target/*$" || echo y)
shift

LOCALE="$TARGET_DIR/etc/default/locale"
FSTAB="$TARGET_DIR/etc/fstab"
OS_RELEASE="$TARGET_DIR/etc/os-release"
INFO_DIR="$TARGET_DIR/info"

REBOOT_WRAPPER=busybox-reboot

fixup_root()
{
	echo "Fixing up rootfs type: $1"

	FS_TYPE=$1
	sed -i "s#\([[:space:]]/[[:space:]]\+\)\w\+#\1${FS_TYPE}#" "$FSTAB"
}

fixup_locale()
{
	[ -n "$RK_ROOTFS_LANG" ] || return 0

	echo "Fixing up LANG to $RK_ROOTFS_LANG"

	if [ -e "$LOCALE" ]; then
		sed -i "/\<LANG\>/d" "$LOCALE"
		echo "LANG=$RK_ROOTFS_LANG" >> "$LOCALE"
	else
		echo "export LANG=$RK_ROOTFS_LANG" > \
			"$TARGET_DIR/etc/profile.d/lang.sh"
	fi
}

del_part()
{
	echo "Deleting partition: ${@//:/ }"

	SRC="$1"
	MOUNTPOINT="$2"
	FS_TYPE="$3"

	# Remove old entries with same mountpoint
	sed -i "/[[:space:]]${MOUNTPOINT//\//\\\/}[[:space:]]/d" "$FSTAB"

	if [ "$SRC" != tmpfs ]; then
		# Remove old entries with same source
		sed -i "/^${SRC//\//\\\/}[[:space:]]/d" "$FSTAB"
	fi
}

fixup_part()
{
	echo "Fixing up partition: ${@//:/ }"

	del_part $@

	SRC="$1"
	MOUNTPOINT="$2"
	FS_TYPE="$3"
	MOUNT_OPTS="$4"
	PASS="$5"

	# Append new entry
	echo -e "$SRC\t$MOUNTPOINT\t$FS_TYPE\t$MOUNT_OPTS\t0 $PASS" >> "$FSTAB"

	mkdir -p "$TARGET_DIR/$MOUNTPOINT"
}

fixup_basic_part()
{
	echo "Fixing up basic partition: $@"

	FS_TYPE="$1"
	MOUNTPOINT="$2"
	MOUNT_OPTS="${3:-defaults}"

	fixup_part "$FS_TYPE" "$MOUNTPOINT" "$FS_TYPE" "$MOUNT_OPTS" 0
}

fixup_device_part()
{
	echo "Fixing up device partition: $@"

	DEV="$1"

	# Dev is either <name> or /dev/.../<name> or <UUID|LABEL|PARTLABEL>=xxx
	[ "$DEV" ] || return 0
	echo $DEV | grep -qE "^/|=" || DEV="PARTLABEL=$DEV"

	MOUNTPOINT="${2:-/${DEV##*[/=]}}"
	FS_TYPE="${3:-ext2}"
	MOUNT_OPTS="${4:-defaults}"

	fixup_part "$DEV" "$MOUNTPOINT" "$FS_TYPE" "$MOUNT_OPTS" 2
}

fixup_fstab()
{
	echo "Fixing up /etc/fstab..."

	cd "$TARGET_DIR"

	case "$RK_ROOTFS_TYPE" in
		ext[234])
			fixup_root "$RK_ROOTFS_TYPE"
			;;
		*)
			fixup_root auto
			;;
	esac

	fixup_basic_part proc /proc
	fixup_basic_part devtmpfs /dev
	fixup_basic_part devpts /dev/pts mode=0620,ptmxmode=0666,gid=5
	fixup_basic_part tmpfs /dev/shm nosuid,nodev,noexec
	fixup_basic_part sysfs /sys
	fixup_basic_part configfs /sys/kernel/config
	fixup_basic_part debugfs /sys/kernel/debug
	fixup_basic_part pstore /sys/fs/pstore

	if [ "$IS_RECOVERY" ]; then
		fixup_device_part /dev/sda1 /mnt/udisk auto
		fixup_device_part /dev/mmcblk1p1 /mnt/sdcard auto
	fi

	for idx in $(seq 1 "$(rk_partition_num)"); do
		DEV="$(rk_partition_dev $idx)"
		MOUNTPOINT="$(rk_partition_mountpoint $idx)"
		FS_TYPE="$(rk_partition_fstype $idx)"

		# No fstab entry for built-in partitions
		if rk_partition_builtin $idx; then
			del_part "$DEV" "$MOUNTPOINT" "$FS_TYPE"
			continue
		fi

		fixup_device_part "$DEV" "$MOUNTPOINT" "$FS_TYPE" \
			"$(rk_partition_options $idx)"
	done
}

prepare_partitions()
{
	for idx in $(seq 1 "$(rk_partition_num)"); do
		MOUNTPOINT="$(rk_partition_mountpoint $idx)"
		OUTDIR="$(rk_partition_outdir $idx)"

		rk_partition_prepare $idx "$TARGET_DIR/$MOUNTPOINT"
		rk_partition_builtin $idx || continue

		echo "Merging $OUTDIR into $TARGET_DIR/$MOUNTPOINT (built-in)"
		rsync -a "$OUTDIR/" "$TARGET_DIR/$MOUNTPOINT"
	done
}

fixup_os_release()
{
	KEY=$1
	shift

	sed -i "/^$KEY=/d" "$OS_RELEASE"
	echo "$KEY=\"$@\"" >> "$OS_RELEASE"
}

add_build_info()
{
	[ -f "$OS_RELEASE" ] || touch "$OS_RELEASE"

	echo "Adding information to /etc/os-release..."

	cd "$SDK_DIR"

	KVER=$(grep -A 1 "^VERSION = " kernel/Makefile | cut -d' ' -f 3 | \
		paste -sd'.')

	fixup_os_release BUILD_INFO "$(whoami)@$(hostname) $(date)${@:+ - $@}"
	fixup_os_release KERNEL "$KVER - ${RK_KERNEL_CFG:-unkown}"

	mkdir -p "$INFO_DIR"

	yes | ${PYTHON3:-python3} .repo/repo/repo manifest -r \
		-o "$INFO_DIR/manifest.xml"

	cp "$RK_OUTDIR/.config" "$INFO_DIR/rockchip_config"

	cp kernel/.config "$INFO_DIR/config-$KVER"
	cp kernel/System.map "$INFO_DIR/System.map-$KVER"

	EXTRA_FILES=" \
		/etc/os-release /etc/fstab /var/log \
		/tmp/usbdevice.log /tmp/bootanim.log \
		/tmp/resize-all.log /tmp/mount-all.log \
		/proc/version /proc/cmdline /proc/kallsyms /proc/interrupts /proc/cpuinfo \
		/proc/softirqs /proc/device-tree /proc/diskstats /proc/iomem \
		/proc/meminfo /proc/partitions /proc/slabinfo \
		/proc/rk_dmabuf /proc/rkcif-mipi-lvds /proc/rkisp0-vir0 \
		/sys/kernel/debug/wakeup_sources /sys/kernel/debug/clk/clk_summary \
		/sys/kernel/debug/gpio /sys/kernel/debug/pinctrl/ \
		/sys/kernel/debug/dma_buf /sys/kernel/debug/dri \
		"
	ln -sf $EXTRA_FILES "$INFO_DIR/"
}

fixup_reboot()
{
	echo "Fixup busybox reboot commands..."

	cd "$TARGET_DIR"

	[ "$(readlink sbin/reboot)" = busybox ] || return 0

	install -D -m 0755 "$SCRIPT_DIR/data/$REBOOT_WRAPPER" \
		sbin/$REBOOT_WRAPPER

	for cmd in halt reboot poweroff shutdown; do
		ln -sf $REBOOT_WRAPPER sbin/$cmd
	done
}

add_dirs_and_links()
{
	echo "Adding dirs and links..."

	cd "$TARGET_DIR"

	rm -rf mnt/* udisk sdcard data
	mkdir -p mnt/sdcard mnt/udisk
	ln -sf udisk mnt/usb_storage
	ln -sf sdcard mnt/external_sd
	ln -sf mnt/udisk udisk
	ln -sf mnt/sdcard sdcard
	ln -sf userdata data
}

source "$PARTITION_HELPER"

add_build_info $@
fixup_locale
fixup_fstab
fixup_reboot
add_dirs_and_links

[ "$IS_RECOVERY" ] || prepare_partitions

exit 0
