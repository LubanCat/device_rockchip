#!/bin/bash

if [ -d "$TARGET_OUTPUT_DIR" ];then
    HOST_DIR=$TARGET_OUTPUT_DIR/host
    export PATH=$HOST_DIR/usr/sbin:$HOST_DIR/usr/bin:$HOST_DIR/sbin:$HOST_DIR/bin:$PATH
fi

fatal()
{
    echo -e "FATAL: " $@
    exit 1
}

usage()
{
    fatal "Usage: $0 <src_dir> <target_image> <fs_type> [size]"
}

[ ! $# -lt 3 ] || usage

SRC_DIR=$1
TARGET=$2
FS_TYPE=$3
SIZE=$4
TEMP=$(mktemp -u)

[ -d "$SRC_DIR" ] || usage

mkimage_auto_sized()
{
    tar cf $TEMP $SRC_DIR >/dev/null 2>&1
    SIZE=$(du -m $TEMP|grep -o "^[0-9]*")
    rm -rf $TEMP
    echo "Making $TARGET from $SRC_DIR (auto sized)"

    EXTRA_SIZE=4 #4M
    MAX_RETRY=10
    RETRY=0

    while true;do
        SIZE=$[SIZE+EXTRA_SIZE]
        $0 $SRC_DIR $TARGET $FS_TYPE $SIZE && break

        RETRY=$[RETRY+1]
        [ $RETRY -gt $MAX_RETRY ] && fatal "Failed to make image!"
        echo "Retring with increased size....($RETRY/$MAX_RETRY)"
    done
}

copy_to_ntfs()
{
    DEPTH=1
    while true;do
        DIRS=$(find $SRC_DIR -maxdepth $DEPTH -mindepth $DEPTH -type d|xargs)
        [ $DIRS ] || break
        for dir in $DIRS;do
            ntfscp $TARGET $dir ${dir#$SRC_DIR} || \
                fatal "Please update buildroot to: \n83c061e7c9 rockchip: Select host-ntfs-3g"
        done
        DEPTH=$(($DEPTH + 1))
    done

    FILES=$(find $SRC_DIR -type f|xargs)
    for file in $FILES;do
        ntfscp $TARGET $file ${file#$SRC_DIR} || \
            fatal "Failed to do ntfscp!"
    done
}

mkimage()
{
    echo "Making $TARGET from $SRC_DIR with size(${SIZE}M)"
    dd of=$TARGET bs=1M seek=$SIZE count=0 2>&1 || fatal "Failed to dd image!"
    case $FS_TYPE in
        ext[234])
            # Set max-mount-counts to 2, and disable the time-dependent checking.
            mke2fs $TARGET -d $SRC_DIR && tune2fs -c 2 -i 0 $TARGET
            ;;
        msdos|fat|vfat)
            # Use fat32 by default
            mkfs.vfat -F 32 $TARGET && \
			MTOOLS_SKIP_CHECK=1 \
			mcopy -bspmn -D s -i $TARGET $SRC_DIR/* ::/
            ;;
        ntfs)
            # Enable compression
            mkntfs -FCQ $TARGET && copy_to_ntfs
            ;;
    esac
}

rm -rf $TARGET
case $FS_TYPE in
    squashfs)
        mksquashfs $SRC_DIR $TARGET -noappend -comp gzip
        ;;
    ext[234]|msdos|fat|vfat|ntfs)
        if [ ! "$SIZE" ]; then
            mkimage_auto_sized
        else
            mkimage && echo "Generated $TARGET"
        fi
        ;;
    *)
        echo "File system: $FS_TYPE not support."
        usage
        ;;
esac
