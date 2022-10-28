#!/bin/bash

set -e

if ! which fakeroot &>/dev/null; then
    echo "fakeroot not found! (sudo apt-get install fakeroot)"
    exit -1
fi

PARAMETER=device/rockchip/$RK_TARGET_PRODUCT/$RK_PARAMETER
MISC_IMG=device/rockchip/rockimg/${RK_MISC:-blank-misc.img}
MKIMAGE=device/rockchip/common/mk-image.sh

message() {
    echo -e "\e[36m $@ \e[0m"
}

fatal() {
    echo -e "\e[31m $@ \e[0m"
    exit -1
}

mkdir -p rockdev

# Parse size limit from parameter.txt, 0 means unlimited or not exists.
partition_size_kb() {
    PART_NAME=$1
    PART_STR=$(grep -oE "[^,^:^\(]*\(${PART_NAME}[\)_:][^\)]*\)" $PARAMETER)
    PART_SIZE=$(echo $PART_STR | grep -oE "^[^@^-]*")
    echo $(( ${PART_SIZE:-0} / 2 ))
}

link_image() {
    SRC="$1"
    DST="$2"
    FALLBACK="$3"

    message "Linking $DST from $SRC..."

    if [ ! -f "$SRC" ]; then
        if [ -f "$FALLBACK" ]; then
            SRC="$FALLBACK"
            message "Fallback to $SRC"
        else
            message "warning: $SRC not found!"
            return 1
        fi
    fi

    ln -rsf "$SRC" "rockdev/$DST"

    message "Done linking $DST"
}

link_image_optional() {
    link_image "$@" || true
}

pack_image() {
    SRC="$1"
    DST="$2"
    FS_TYPE="$3"
    SIZE="${4:-$(partition_size_kb "${DST%.img}")}"
    LABEL="$5"
    EXTRA_CMD="$6"

    FAKEROOT_SCRIPT="rockdev/${DST%.img}.fs"

    message "Packing $DST from $SRC..."

    if [ ! -d "$SRC" ]; then
        message "warning: $SRC not found!"
        return 0
    fi

    cat << EOF > $FAKEROOT_SCRIPT
#!/bin/sh -e
$EXTRA_CMD
$MKIMAGE "$SRC" "rockdev/$DST" "$FS_TYPE" "$SIZE" "$LABEL"
EOF

    chmod a+x "$FAKEROOT_SCRIPT"
    fakeroot -- "$FAKEROOT_SCRIPT"
    rm -f "$FAKEROOT_SCRIPT"

    message "Done packing $DST"
}

# Convert legacy partition variables to new style
legacy_partion() {
    PART_NAME="$1"
    SRC="$2"
    FS_TYPE="$3"
    SIZE="${4:-0}"
    MOUNT="/$PART_NAME"
    OPT=""

    [ "$FS_TYPE" ] || return 0
    [ "$SRC" ] || return 0

    # Fixed size for ubi
    if [ "$FS_TYPE" = ubi ]; then
        OPT="fixed"
    fi

    case $SIZE in
        *k|*K)
            SIZE=${SIZE//k/K}
            ;;
        *m|*M)
            SIZE=${SIZE//m/M}
            ;;
        *)
            SIZE=$(( ${SIZE} / 1024 ))K # default is bytes
            ;;
    esac

    echo "$PART_NAME:$MOUNT:$FS_TYPE:defaults:$SRC:${SIZE}:$OPT"
}

RK_LEGACY_PARTITIONS=" \
    $(legacy_partion oem "$RK_OEM_DIR" "$RK_OEM_FS_TYPE" "$RK_OEM_PARTITION_SIZE")
    $(legacy_partion userdata "$RK_USERDATA_DIR" "$RK_USERDATA_FS_TYPE" "$RK_USERDATA_PARTITION_SIZE")
"

# <dev>:<mount point>:<fs type>:<mount flags>:<source dir>:<image size(M|K|auto)>:[options]
# for example:
# RK_EXTRA_PARTITIONS="oem:/oem:ext2:defaults:oem_normal:256M:fixed
# userdata:/userdata:vfat:errors=remount-ro:userdata_empty:auto"
RK_EXTRA_PARTITIONS="${RK_EXTRA_PARTITIONS:-${RK_LEGACY_PARTITIONS}}"

partition_arg() {
    PART="$1"
    I="$2"
    DEFAULT="$3"

    ARG=$(echo $PART | cut -d':' -f"$I")
    echo ${ARG:-$DEFAULT}
}

pack_extra_partitions() {
    for part in ${RK_EXTRA_PARTITIONS//@/ }; do
        DEV="$(partition_arg "$part" 1)"

        # Dev is either <name> or /dev/.../<name>
        [ "$DEV" ] || continue
        PART_NAME="${DEV##*/}"

        MOUNT="$(partition_arg "$part" 2 "/$PART_NAME")"
        FS_TYPE="$(partition_arg "$part" 3)"

        SRC="$(partition_arg "$part" 5)"

        # Src is either none or relative path to device/rockchip/<name>/
        # or absolute path
        case "$SRC" in
            "")
                continue
                ;;
            /*)
                ;;
            *)
                SRC="device/rockchip/$PART_NAME/$SRC"
                ;;
        esac

        SIZE="$(partition_arg "$part" 6 auto)"
        OPTS="$(partition_arg "$part" 7)"
        LABEL="$PART_NAME"
        EXTRA_CMD=

        # Special handling for oem
        if [ "$PART_NAME" = oem ]; then
            # Skip packing oem when builtin
            [ -z "${RK_OEM_BUILDIN_BUILDROOT}" ] || continue

            if [ -d "$SRC/www" ]; then
                EXTRA_CMD="chown -R www-data:www-data $SRC/www"
            fi
        fi

        # Skip boot time resize by adding a tag file
        echo $OPTS | grep -wq fixed || touch "$SRC/.fixed"

        pack_image "$SRC" "${PART_NAME}.img" "$FS_TYPE" "$SIZE" "$LABEL" \
            "$EXTRA_CMD"

        rm -rf "$SRC/.fixed"
    done
}

link_image_optional "$PARAMETER" parameter.txt
link_image_optional "$MISC_IMG" misc.img

pack_extra_partitions

echo "Packed files:"
for f in rockdev/*; do
	NAME=$(basename "$f")

	echo -n "$NAME"
	if [ -L "$f" ]; then
		echo -n "($(readlink -f "$f"))"
	fi

	FILE_SIZE=$(ls -lLh $f | xargs | cut -d' ' -f 5)
	echo ": $FILE_SIZE"

	echo "$NAME" | grep -q ".img$" || continue

	# Assert the image's size smaller than parameter.txt's limit
	PART_SIZE="$(partition_size_kb "${NAME%.img}")"
	FILE_SIZE_KB="$(( $(stat -Lc "%s" "$f") / 1024 ))"
	if [ "$PART_SIZE" -gt 0 -a "$PART_SIZE" -lt "$FILE_SIZE_KB" ]; then
		fatal "error: $NAME's size exceed parameter.txt's limit!"
	fi
done

message "Images in rockdev are ready!"
