#!/bin/bash

fatal()
{
    echo $@
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

create_image()
{
    dd of=$TARGET bs=1M seek=$SIZE count=0 2>&1 || fatal "Failed to dd image!"
    case $FS_TYPE in
        ext[234])
            # Set max-mount-counts to 2, and disable the time-dependent checking.
            mke2fs $TARGET && tune2fs -c 2 -i 0 $TARGET
            ;;
        msdos|fat|vfat)
            # Use fat32 by default
            mkfs.vfat -F 32 $TARGET
            ;;
        ntfs)
            # Enable compression
            mkntfs -FCQ $TARGET
            ;;
    esac
}

mkimage()
{
    echo "Making $TARGET from $SRC_DIR with size(${SIZE}M)"
    create_image >/dev/null|| fatal "Failed to create empty image!"

    FAILED=
    mkdir $TEMP
    mount $TARGET $TEMP
    cp -rp $SRC_DIR/* $TEMP || FAILED=1
    umount $TEMP
    rm -rf $TEMP

    [ "$FAILED" ] && fatal "Failed to copy files!"
    echo "Generated $TARGET"
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
            mkimage
        fi
        ;;
    *)
        echo "File system: $FS_TYPE not support."
        usage
        ;;
esac
