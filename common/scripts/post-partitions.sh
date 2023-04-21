#!/bin/bash -e

POST_OS_DISALLOWED="recovery pcba"

source "${POST_HELPER:-$(dirname "$(realpath "$0")")/../post-hooks/post-helper}"

source "$PARTITION_HELPER"

echo "Preparing extra partitions..."

for idx in $(seq 1 "$(rk_partition_num)"); do
	MOUNTPOINT="$(rk_partition_mountpoint $idx)"
	OUTDIR="$(rk_partition_outdir $idx)"

	rk_partition_prepare $idx "$TARGET_DIR/$MOUNTPOINT"
	rk_partition_builtin $idx || continue

	echo "Merging $OUTDIR into $TARGET_DIR/$MOUNTPOINT (built-in)"
	rsync -a "$OUTDIR/" "$TARGET_DIR/$MOUNTPOINT"
done
