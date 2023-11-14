#!/bin/bash -e

###################################################
RK_SCRIPTS_DIR="${RK_SCRIPTS_DIR:-$(dirname "$(realpath "$0")")}"
RK_SDK_DIR="${RK_SDK_DIR:-$RK_SCRIPTS_DIR/../../../..}"
UBOOT=$RK_SDK_DIR/u-boot
KERNEL=$RK_SDK_DIR/kernel
BUILDROOT=$RK_SDK_DIR/buildroot
RK_SIGN_TOOL=$RK_SDK_DIR/rkbin/tools/rk_sign_tool
###################################################

# 1 -> input misc	# 2 -> output misc
# 3 -> size		# 4 -> enc_key
rk_security_setup_misc()
{
	input=$1
	output=$2
	size=$3
	buf=$4
	echo buf=$buf

	tmpmisc=$(mktemp -u)
	mv $input $tmpmisc

	big_end=$[size / 256]
	lit_end=$[size - (big_end * 256)]
	big_end=$(echo "ibase=10;obase=16;$big_end" | bc)
	lit_end=$(echo "ibase=10;obase=16;$lit_end" | bc)

	rm -rf $output
	dd if="$tmpmisc" of="$output" bs=1k count=10
	echo -en "\x$lit_end\x$big_end" >> "$output"
	echo -n "$buf" >> "$output"
	skip=$[10 * 1024 + size + 2]
	dd if="$tmpmisc" of="$output" seek=$skip skip=$skip bs=1
	rm $tmpmisc
}

rk_security_setup_createkeys()
{
	mkdir -p $UBOOT/keys
	cd $UBOOT/keys

	$RK_SIGN_TOOL kk --bits 2048 --out ./

	ln -rsf private_key.pem dev.key
	ln -rsf public_key.pem dev.pubkey
	# TODO: Some rk_sign_tool may create privateKey.pem / publicKey.pem

	openssl req -batch -new -x509 -key $UBOOT/keys/dev.key \
		-out $UBOOT/keys/dev.crt

	if [ "$1" == "system-encryption" ]; then
		openssl rand -out $UBOOT/keys/system_enc_key -hex 32
	fi
}

rk_security_setup_system_verity()
{
	target_image=$(readlink -f $1)
	outdir=$(cd $(dirname $target_image);pwd)
	security_system=$outdir/security_system.img

	if [ -f "$outdir/security.info" ]; then
		source $outdir/security.info
		if [ "$(ls -l --time-style=long-iso $target_image | cut -d ' ' -f 6,7)" == "$touch" ]; then
			echo "security_system.img not be updated!!!"
			return
		fi
	fi

	sectors=$(ls -l "$target_image" | awk '{printf $5}')
	hash_offset=$[(sectors / 1024 / 1024 + 2) * 1024 * 1024]
	tmp_file=$(mktemp)
	cp "$target_image" "$security_system"
	veritysetup --hash-offset=$hash_offset format "$security_system" "$security_system" > $tmp_file

	echo "touch=\"$(ls -l --time-style=long-iso $target_image | cut -d ' ' -f 6,7)\"" > $outdir/security.info
	echo "hash_offset=$hash_offset" >> $outdir/security.info
	root_hash=$(cat $tmp_file)
	echo "root_hash=$(echo ${root_hash##*:})" >> $outdir/security.info
	# cat "$tmp_file" >> $outdir/info
	rm $tmp_file
}

rk_security_setup_system_encryption()
{
	target_image=$(readlink -f $1)
	outdir=$(cd $(dirname $target_image);pwd)
	security_system=$outdir/security_system.img

	key=$(cat $UBOOT/keys/system_enc_key)
	cipher=aes-cbc-plain

	if [ -f "$outdir/security.info" ]; then
		source $outdir/security.info
		if [ "$(ls -l --time-style=long-iso $target_image | cut -d ' ' -f 6,7)" == "$touch" ]; then
			echo "security_system.img not be updated!!!"
			return
		fi
	fi

	sectors=$(ls -l "$target_image" | awk '{printf $5}')
	sectors=$[(sectors + (21 * 1024 * 1024) - 1) / 512] # remain 20M for partition info / unit: 512 bytes

	loopdevice=$(losetup -f)
	mappername=encfs-$(shuf -i 1-10000000000000000000 -n 1)
	dd if=/dev/null of="$security_system" seek=$sectors bs=512

	sudo -S losetup $loopdevice "$security_system" < $UBOOT/keys/root_passwd
	sudo -S dmsetup create $mappername --table "0 $sectors crypt $cipher $key 0 $loopdevice 0 1 allow_discards" < $UBOOT/keys/root_passwd
	sudo -S dd if="$target_image" of=/dev/mapper/$mappername conv=fsync < $UBOOT/keys/root_passwd
	sync && sudo -S dmsetup remove $mappername < $UBOOT/keys/root_passwd
	sudo -S losetup -d $loopdevice < $UBOOT/keys/root_passwd

	echo "touch=\"$(ls -l --time-style=long-iso $target_image | cut -d ' ' -f 6,7)\"" > $outdir/security.info
	echo "sectors=$sectors" >> $outdir/security.info
	echo "cipher=$cipher" >> $outdir/security.info
	echo "key=$key" >> $outdir/security.info
}

rk_security_setup_system()
{
	case $1 in
		system-verity) shift; rk_security_setup_system_verity $@ ;;
		system-encryption) shift; rk_security_setup_system_encryption $@ ;;
		base) ;;
		*) exit -1;;
	esac
}

rk_security_setup_ramboot_prebuild()
{
	check_method=$1
	shift
	init_in=$1
	shift
	security_file=$1
	shift

	case $check_method in
		system-encryption) echo encryption ;;
		system-verity) echo verity ;;
		base) return ;;
		*) exit -1;;
	esac

	if [ ! -f "$init_in" ] || [ ! -f "$security_file" ]; then
		echo -e "\e[41;1;37minit_in or security_file is missed\e[0m"
		exit -1
	fi

	init_file="$(dirname $init_in)/init"
	cp $init_in $init_file

	if [ "$check_method" == "system-encryption" ]; then
		source "$security_file"
		sed -i "s/ENC_EN=/ENC_EN=true/" "$init_file"
		sed -i "s/CIPHER=/CIPHER=$cipher/" "$init_file"
	else
		source "$security_file"
		sed -i "s/ENC_EN=/ENC_EN=false/" "$init_file"
		sed -i "s/OFFSET=/OFFSET=$hash_offset/" "$init_file"
		sed -i "s/HASH=/HASH=$root_hash/" "$init_file"
	fi

	sed -i "s/# exec busybox switch_root/exec busybox switch_root/" "$init_file"
	echo "Generate ramdisk init for security"
}

rk_security_setup_sign()
{
	input=$(realpath $2)
	output=$(realpath $3)

	cd $UBOOT
	case $1 in
		boot|recovery)
			./scripts/fit.sh --${1}_img $input
			cp ${1}.img $output
			;;
		*) exit -1;;
	esac
	cd -
}

# -----------------------------------
# For SDK
# -----------------------------------
build_security_system()
{
	[ "$RK_ROOTFS_SYSTEM_BUILDROOT" ] || warning "rootfs is not buildroot!"
	"$RK_SCRIPTS_DIR/mk-rootfs.sh"
	[ -z "$RK_SECURITY_CHECK_SYSTEM_VERITY" ] ||
		"$RK_SCRIPTS_DIR/mk-security.sh" security-ramboot

	notice "Security rootfs.img has update in output/firmware/rootfs.img"
	finish_build $@
}

build_security_ramboot()
{
	check_config RK_SECURITY_INITRD_CFG || false

	message "=========================================="
	message "          Start building security ramboot(buildroot)"
	message "=========================================="

	if [ ! -r "$RK_FIRMWARE_DIR/rootfs.img" ]; then
		notice "Rootfs is not ready, building it for security..."
		"$RK_SCRIPTS_DIR/mk-rootfs.sh"
	fi

	"$RK_SCRIPTS_DIR/mk-security.sh" ramboot_prebuild $RK_SECURITY_CHECK_METHOD \
			$RK_SDK_DIR/buildroot/board/rockchip/common/security-ramdisk-overlay/init.in \
			$RK_OUTDIR/buildroot/images/security.info

	DST_DIR="$RK_OUTDIR/security-ramboot"
	IMAGE_DIR="$DST_DIR/images"

	"$RK_SCRIPTS_DIR/mk-buildroot.sh" $RK_SECURITY_INITRD_CFG "$IMAGE_DIR"

	"$RK_SCRIPTS_DIR/mk-ramboot.sh" "$DST_DIR" \
		"$IMAGE_DIR/rootfs.$RK_SECURITY_INITRD_TYPE" \
		"$RK_SECURITY_FIT_ITS"
	"$RK_SCRIPTS_DIR/mk-security.sh" sign boot $DST_DIR/ramboot.img $RK_FIRMWARE_DIR/boot.img
	notice "Security boot.img has update in output/firmware/boot.img"

	finish_build $@
}

# Hooks

BUILD_CMDS="security-createkeys security-misc security-ramboot security-system"
HID_CMDS="createkeys misc system ramboot_prebuild sign"
build_hook()
{
	case $1 in
		security-createkeys)
			rk_security_setup_createkeys $RK_SECURITY_CHECK_METHOD;;
		security-misc)
			[ -z "$RK_SECURITY_CHECK_SYSTEM_ENCRYPTION" ] || \
			       $RK_SCRIPTS_DIR/mk-misc.sh;;
		security-ramboot) build_security_ramboot;;
		security-system) build_security_system;;
	esac

	for item in $HID_CMDS
	do
		if [ "$item" = "$1" ]; then
			append=$1
			shift
			"rk_security_setup_$append" $@
			return
		fi
	done
}

usage_hook()
{
	echo -e "security-createkeys               \tcreate keys for security"
	echo -e "security-misc                     \tbuild misc with system encryption key"
	echo -e "security-ramboot                  \tbuild security ramboot"
	echo -e "security-system                   \tbuild security system"
}

clean_hook()
{
	rm -rf $RK_OUTDIR/security-ramboot
}

[ -z "$RK_SESSION" ] || \
	source "${RK_BUILD_HELPER:-$(dirname "$(realpath "$0")")/../build-hooks/build-helper}"

[ -z "$1" ] || build_hook $@
