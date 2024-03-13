#!/bin/bash
# Usage: ./gen-part-config.sh <max extra partition num> <default extra partition num>

RK_EXTRA_PARTITION_MAX_NUM=${1:-5}
RK_EXTRA_PARTITION_NUM=${2:-2}

cat <<EOF
# Auto generated by $0${@:+ $@}

comment "Extra partitions depends on rootfs system"
	depends on !RK_ROOTFS

menu "Extra partitions (oem, userdata, etc.)"
	depends on RK_ROOTFS

EOF

for i in $(seq 1 $RK_EXTRA_PARTITION_MAX_NUM); do
	case $i in
		1)
			echo "if RK_EXTRA_PARTITION_${i}_FSTYPE = \"ubi\" || \\"
			;;
		$RK_EXTRA_PARTITION_MAX_NUM)
			echo "	RK_EXTRA_PARTITION_${i}_FSTYPE = \"ubi\""
			;;
		*)
			echo "	RK_EXTRA_PARTITION_${i}_FSTYPE = \"ubi\" || \\"
			;;
	esac
done

cat <<EOF

config RK_UBI_PAGE_SIZE
	hex "ubi image page size (B)"
	default "0x800"

config RK_UBI_BLOCK_SIZE
	hex "ubi image block size (B)"
	default "0x20000"

config RK_FLASH_SIZE
	int "size of flash storage (M)"
	default "1024"

endif

config RK_EXTRA_PARTITION_NUM
	int "number of extra partitions"
	range 0 $RK_EXTRA_PARTITION_MAX_NUM
	default $RK_EXTRA_PARTITION_NUM
EOF

unset RK_EXTRA_PARTITIONS
for i in $(seq 1 $RK_EXTRA_PARTITION_MAX_NUM); do
	cat <<EOF

menu "Extra partition $i"
	depends on RK_EXTRA_PARTITION_NUM > $(( $i - 1 ))

config RK_EXTRA_PARTITION_${i}_DEV
	string "device identifier"
EOF
	case $i in
		1) echo -e "\tdefault \"oem\"" ;;
		2) echo -e "\tdefault \"userdata\"" ;;
	esac

	cat <<EOF
	help
	  Device identifier, like oem or /dev/mmcblk0p7 or PARTLABEL=oem.

config RK_EXTRA_PARTITION_${i}_NAME
	string "partition name"
	default "<dev>"
	help
	  Partition name, set "<dev>" to detect from device identifier.

config RK_EXTRA_PARTITION_${i}_NAME_STR
	string
	default "\${RK_EXTRA_PARTITION_${i}_DEV##*[/=]}" \\
		if RK_EXTRA_PARTITION_${i}_NAME = "<dev>"
	default RK_EXTRA_PARTITION_${i}_NAME

config RK_EXTRA_PARTITION_${i}_MOUNTPOINT
	string "mountpoint"
	default "/<name>"

config RK_EXTRA_PARTITION_${i}_MOUNTPOINT_STR
	string
	default "/\$RK_EXTRA_PARTITION_${i}_NAME_STR" \\
		if RK_EXTRA_PARTITION_${i}_MOUNTPOINT = "/<name>"
	default RK_EXTRA_PARTITION_${i}_MOUNTPOINT

config RK_EXTRA_PARTITION_${i}_FSTYPE
	string "filesystem type"
	default "ext4"

config RK_EXTRA_PARTITION_${i}_OPTIONS
	string "mount options"
	default "defaults"

config RK_EXTRA_PARTITION_${i}_SRC
	string "source dirs"
EOF

	if [ $i -lt 3 ]; then
		cat << EOF
	default "empty" if RK_CHIP_FAMILY = "rk3308"
	default "normal"
	help
	  Source dirs, each of them can be either of absolute path(/<dir>) or
	  relative to <RK_IMAGE_DIR> or relative to <RK_IMAGE_DIR>/<part name>.
EOF
	fi

	cat <<EOF

config RK_EXTRA_PARTITION_${i}_SIZE
	string "image size (size(M|K)|auto(0)|max)"
	default "max" if RK_EXTRA_PARTITION_1_FSTYPE = "ubi"
	default "auto"
	help
	  Size of image.
	  Set "auto" to auto detect.
	  Set "max" to use maxium partition size in parameter file.

config RK_EXTRA_PARTITION_${i}_BUILTIN
	bool "merged into rootfs"
	help
	  Virtual parition that merged into rootfs.

config RK_EXTRA_PARTITION_${i}_NOPACK
	bool "skip packing image"
	depends on !RK_EXTRA_PARTITION_${i}_BUILTIN

config RK_EXTRA_PARTITION_${i}_FEATURES
	string
	default "\${RK_EXTRA_PARTITION_${i}_BUILTIN:+builtin,}\${RK_EXTRA_PARTITION_${i}_NOPACK:+nopack,}"

config RK_EXTRA_PARTITION_${i}_STR
	string
	depends on RK_EXTRA_PARTITION_${i}_DEV != ""
	default "\$RK_EXTRA_PARTITION_${i}_DEV:\$RK_EXTRA_PARTITION_${i}_NAME_STR:\$RK_EXTRA_PARTITION_${i}_MOUNTPOINT_STR:\$RK_EXTRA_PARTITION_${i}_FSTYPE:\$RK_EXTRA_PARTITION_${i}_OPTIONS:\${RK_EXTRA_PARTITION_${i}_SRC// /,}:\$RK_EXTRA_PARTITION_${i}_SIZE:\$RK_EXTRA_PARTITION_${i}_FEATURES"

endmenu # Extra partition $i
EOF

	RK_EXTRA_PARTITIONS="${RK_EXTRA_PARTITIONS:+${RK_EXTRA_PARTITIONS}@}\$RK_EXTRA_PARTITION_${i}_STR"
done

cat << EOF

config RK_EXTRA_PARTITION_STR
	string
	default "$RK_EXTRA_PARTITIONS"

endmenu # Extra partitions
EOF
