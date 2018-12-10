#!/bin/bash

COMMON_DIR=$(cd `dirname $0`; pwd)
if [ -h $0 ]
then
        CMD=$(readlink $0)
        COMMON_DIR=$(dirname $CMD)
fi

if [ -n "$1" ]
then
        USERDATA_DIR="$1"
else
        exit 1
fi

if [ -n "$2" ]
then
        USERDATA_IMG="$2"
else
        exit 1
fi

if [ -n "$3" ]
then
        FS_TYPE="$3"
else
        exit 1
fi

case $FS_TYPE in
	ext[2-4])
		$COMMON_DIR/mke2img.sh $USERDATA_DIR $USERDATA_IMG
		;;
	fat|vfat)
		SIZE=$(du -sh -L -BM $USERDATA_DIR|grep -o "^[0-9]*")
		EXTRA_SIZE=4 #4M

		MAX_RETRY=10
		RETRY=0
		while true;do
			SIZE=$[SIZE+EXTRA_SIZE]
			echo "Creating vfat image with size ${SIZE}M"
			dd of=$USERDATA_IMG bs=1M seek=$SIZE count=0 && \
			mkfs.vfat $USERDATA_IMG && \
			MTOOLS_SKIP_CHECK=1 \
			mcopy -bspmn -D s -i $USERDATA_IMG $USERDATA_DIR/* ::/ && \
			break

			RETRY=$[RETRY+1]
			[ ! $RETRY -lt $MAX_RETRY ] && { echo "Failed to make vfat image! "; exit; }
			echo "Retring with increased size....($RETRY/$MAX_RETRY)"
		done
		;;
	*)
		echo "file system: $FS_TYPE not support."
		exit 1
		;;
esac
