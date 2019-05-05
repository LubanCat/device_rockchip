#!/bin/bash

if [ ! -d "$TARGET_OUTPUT_DIR" ]; then
    echo "Source buildroot/build/envsetup.sh firstly!!!"
    exit 1
fi

# Prefer using buildroot host tools for compatible.
HOST_DIR=$TARGET_OUTPUT_DIR/host
export PATH=$HOST_DIR/usr/sbin:$HOST_DIR/usr/bin:$HOST_DIR/sbin:$HOST_DIR/bin:$PATH

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

export SRC_DIR=$1
export TARGET=$2
FS_TYPE=$3
SIZE=$4
TEMP=$(mktemp -u)

[ -d "$SRC_DIR" ] || usage

copy_to_ntfs()
{
    DEPTH=1
    while true;do
        find $SRC_DIR -maxdepth $DEPTH -mindepth $DEPTH -type d|grep -q "" \
            || break
        find $SRC_DIR -maxdepth $DEPTH -mindepth $DEPTH -type d \
            -exec sh -c 'ntfscp $TARGET "$1" "${1#$SRC_DIR}"' sh {} \; || \
                fatal "Please update buildroot to: \n83c061e7c9 rockchip: Select host-ntfs-3g"
        DEPTH=$(($DEPTH + 1))
    done

    find $SRC_DIR -type f \
        -exec sh -c 'ntfscp $TARGET "$1" "${1#$SRC_DIR}"' sh {} \; || \
            fatal "Failed to do ntfscp!"
}

copy_to_image()
{
    echo "Copying $SRC_DIR into $TARGET (root permission required)"

    mkdir -p $TEMP || return -1
    sudo mount $TARGET $TEMP || return -1

    cp -rp $SRC_DIR/* $TEMP
    RET=$?

    sudo umount $TEMP
    rm -rf $TEMP

    return $RET
}

check_host_tool()
{
    which $1|grep -q "^$TARGET_OUTPUT_DIR"
}

mkimage()
{
    echo "Making $TARGET from $SRC_DIR with size(${SIZE}M)"
    dd of=$TARGET bs=1M seek=$SIZE count=0 2>&1 || fatal "Failed to dd image!"
    case $FS_TYPE in
        ext[234])
            if check_host_tool mke2fs; then
                mke2fs $TARGET -d $SRC_DIR || return -1
            else
                mke2fs $TARGET || return -1
                copy_to_image || return -1
            fi
            # Set max-mount-counts to 0, and disable the time-dependent checking.
            tune2fs -c 0 -i 0 $TARGET
            ;;
        msdos|fat|vfat)
            # Use fat32 by default
            mkfs.vfat -F 32 $TARGET && \
			MTOOLS_SKIP_CHECK=1 \
			mcopy -bspmn -D s -i $TARGET $SRC_DIR/* ::/
            ;;
        ntfs)
            # Enable compression
            mkntfs -FCQ $TARGET
            if check_host_tool ntfscp; then
                copy_to_ntfs
            else
                copy_to_image
            fi
            ;;
    esac
}

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
        mkimage && break

        RETRY=$[RETRY+1]
        [ $RETRY -gt $MAX_RETRY ] && fatal "Failed to make image!"
        echo "Retring with increased size....($RETRY/$MAX_RETRY)"
    done
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
