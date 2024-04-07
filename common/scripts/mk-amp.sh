#!/bin/bash -e

RK_RTOS_BSP_DIR=$RK_SDK_DIR/rtos/bsp/rockchip
ITS_FILE="$RK_CHIP_DIR/$RK_AMP_FIT_ITS"

RK_SCRIPTS_DIR="${RK_SCRIPTS_DIR:-$(dirname "$(realpath "$0")")}"

usage_hook()
{
	echo -e "amp                              \tbuild and pack amp system"
}

amp_get_value()
{
	echo "$1" | grep -owP "$2\s*=\s*<([^>]+)>" | awk -F'<|>' '{print $2}'
}

amp_get_string()
{
	echo "$1" | grep -owP "$2\s*=.*\"([^>]+)\"" | awk -F'"' '{print $2}'
}

amp_get_node()
{
	echo "$1" | \
	awk -v node="$2" \
		'$0 ~ node " {" {
		in_block = 1;
		block = $0;
		next;
		}
		in_block {
			block = block "\n" $0;
			if (/}/) {
				count_open = gsub(/{/, "&", block);
				count_close = gsub(/}/, "&", block);
				if (count_open == count_close) {
					in_block = 0;
					print block;
					block = "";
				}
			}
		}'
}

build_hal()
{
	check_config "$1" || return 0

	message "=========================================="
	message "  Building CPU $2: HAL-->${!1}"
	message "=========================================="

	cd "$RK_RTOS_BSP_DIR/common/hal/project/"${!1}"/GCC"

	make clean > /dev/null
	rm -rf $3.elf $3.bin
	make -j$(nproc) > ${RK_SDK_DIR}/hal.log 2>&1
	cp TestDemo.elf $3.elf
	mv TestDemo.bin $3.bin
	ln -rsf $3.bin $RK_OUTDIR/$3.bin

	finish_build build_hal $@
}

build_rtthread()
{
	check_config "$1" || return 0

	message "=========================================="
	message "  Building CPU $2: RT-Thread-->${!1}"
	message "                  Config-->$4"
	message "=========================================="

	cd "$RK_RTOS_BSP_DIR/${!1}"

	export RTT_ROOT=$RK_RTOS_BSP_DIR/../../
	export RTT_PRMEM_BASE=$FIRMWARE_CPU_BASE
	export RTT_PRMEM_SIZE=$DRAM_SIZE
	export RTT_SRAM_BASE=$SRAM_BASE
	export RTT_SRAM_SIZE=$SRAM_SIZE
	export RTT_SHMEM_BASE=$SHMEM_BASE
	export RTT_SHMEM_SIZE=$SHMEM_SIZE

	ROOT_PART_OFFSET=$(rk_partition_start rootfs)
	if [ -n $ROOT_PART_OFFSET ];then
		export ROOT_PART_OFFSET=$ROOT_PART_OFFSET
	fi

	ROOT_PART_SIZE=$(rk_partition_size rootfs)
	if [ -n $ROOT_PART_SIZE ];then
		export ROOT_PART_SIZE=$ROOT_PART_SIZE
	fi

	if [ -f "$4" ] ;then
		scons --useconfig="$4"
	else
		warning "Warning: Config $4 not exit!\n"
		warning "Default config(.config) will be used!\n"
	fi

	scons -c > /dev/null
	rm -rf gcc_arm.ld Image/rtt$2.elf Image/rtt$2.bin
	scons -j$(nproc) > ${RK_SDK_DIR}/rtt.log 2>&1
	cp rtthread.elf Image/rtt$2.elf
	mv rtthread.bin Image/rtt$2.bin
	ln -rsf Image/rtt$2.bin $RK_OUTDIR/$3.bin

	if [ -n "$RK_AMP_RTT_ROOTFS_DATA" ] && [ -n "$ROOT_PART_SIZE" ] ;then

		RTT_TOOLS_PATH=$RK_RTOS_BSP_DIR/$RK_AMP_RTT_TARGET/../tools
		RTT_ROOTFS_USERDAT=$RK_RTOS_BSP_DIR/$RK_AMP_RTT_TARGET/$RK_AMP_RTT_ROOTFS_DATA
		RTT_ROOTFS_SECTOR_SIZE=$(($(printf "%d" $ROOT_PART_SIZE) / 8)) # covert to 4096B

		ROOT_SECTOR_SIZE=$(grep -r "CONFIG_RT_DFS_ELM_MAX_SECTOR_SIZE" "$4" | cut -d '=' -f 2)
		if [ -z $ROOT_SECTOR_SIZE ];then
			ROOT_SECTOR_SIZE=512
		fi

		dd of=root.img bs=4K seek=$RTT_ROOTFS_SECTOR_SIZE count=0 2>&1 || fatal "Failed to dd image!"
		mkfs.fat -S $ROOT_SECTOR_SIZE root.img
		MTOOLS_SKIP_CHECK=1 $RTT_TOOLS_PATH/mcopy -bspmn -D s -i root.img $RTT_ROOTFS_USERDAT/* ::/

		mv root.img Image/
		ln -rsf Image/root.img $RK_FIRMWARE_DIR/rootfs.img
	fi

	finish_build build_rtthread $@
}

clean_hook()
{
	[ "$RK_AMP" ] || return 0

	if [ "$RK_AMP_RTT_TARGET" ]; then
		cd "$RK_RTOS_BSP_DIR/$RK_AMP_RTT_TARGET"
		scons -c >/dev/null || true
	fi

	if [ "$RK_AMP_HAL_TARGET" ]; then
		cd "$RK_RTOS_BSP_DIR/common/hal/project/$RK_AMP_HAL_TARGET/GCC"
		make clean >/dev/null || true
	fi

	rm -rf "$RK_FIRMWARE_DIR/amp.img"
}

build_images()
{
	for item in $1
	do
		ITS_IMAGE=$(amp_get_node "$(cat $ITS_FILE)" $item)
		export FIRMWARE_CPU_BASE=$(amp_get_value "$ITS_IMAGE" load)
		export DRAM_SIZE=$(amp_get_value "$ITS_IMAGE" size)
		export SRAM_BASE=$(amp_get_value "$ITS_IMAGE" srambase)
		export SRAM_SIZE=$(amp_get_value "$ITS_IMAGE" sramsize)
		export CUR_CPU=$(amp_get_value "$ITS_IMAGE" cpu)
		CPU_BIN=$(amp_get_string "$ITS_IMAGE" data)
		if (( $CUR_CPU > 0xff )); then
			CUR_CPU=$((CUR_CPU >> 8))
		fi
		CUR_CPU=$(($CUR_CPU))

		echo Image info: $item
		for p in FIRMWARE_CPU_BASE DRAM_SIZE SRAM_BASE SRAM_SIZE SHMEM_BASE \
			 SHMEM_SIZE LINUX_RPMSG_BASE LINUX_RPMSG_SIZE CUR_CPU
		do
			echo $(env | grep -w $p && true)
		done

		SYS=$(amp_get_string "$ITS_IMAGE" sys)
		CORE=$(amp_get_string "$ITS_IMAGE" core)
		SYS="${SYS}${CORE:+_$CORE}"

		case $SYS in
			hal_mcu)
				build_hal RK_AMP_MCU_HAL_TARGET mcu \
					  "$(basename -s .bin $CPU_BIN)"
				;;
			hal|hal_ap)
				build_hal RK_AMP_HAL_TARGET $CUR_CPU \
					  "$(basename -s .bin $CPU_BIN)"
				;;
			rtt_mcu)
				build_rtthread RK_AMP_MCU_RTT_TARGET mcu \
					       "$(basename -s .bin $CPU_BIN)" \
					       "$(amp_get_string "$ITS_IMAGE" rtt_config)"
				;;
			rtt|rtt_ap)
				build_rtthread RK_AMP_RTT_TARGET $CUR_CPU \
					       "$(basename -s .bin $CPU_BIN)" \
					       "$(amp_get_string "$ITS_IMAGE" rtt_config)" \
				;;
			*)
				break;;
		esac
	done
}

BUILD_CMDS="amp"
build_hook()
{
	local i

	check_config RK_AMP || false

	message "=========================================="
	message "          Start building AMP"
	message "=========================================="

	"$RK_SCRIPTS_DIR/check-amp.sh"

	export CROSS_COMPILE=$(get_toolchain AMP "$RK_AMP_ARCH" "" none)
	[ "$CROSS_COMPILE" ] || exit 1

	if [ -f "$RK_CHIP_DIR/$RK_AMP_CFG" ]; then
		set -a
		source $RK_CHIP_DIR/$RK_AMP_CFG
		set +a
	fi

	CORE_NUMBERS=$(grep -wcE "amp[0-9]* {" $ITS_FILE)
	echo "CORE_NUMBERS=$CORE_NUMBERS"

	EXT_SHARE=$(amp_get_node "$(cat $ITS_FILE)" share)
	if [ "$EXT_SHARE" ]; then
		SHMEM_BASE=$(amp_get_value "$EXT_SHARE" "shm_base")
		if [ "$SHMEM_BASE" ]; then
			export SHMEM_BASE
			export SHMEM_SIZE=$(amp_get_value "$EXT_SHARE" "shm_size")
			AMP_PRIMARY_CORE=$(amp_get_value "$EXT_SHARE" primary)
			[ ! $AMP_PRIMARY_CORE ] || export AMP_PRIMARY_CORE=$(($AMP_PRIMARY_CORE))
		fi

		LINUX_RPMSG_BASE=$(amp_get_value "$EXT_SHARE" "rpmsg_base")
		if [ "$LINUX_RPMSG_BASE" ]; then
			export LINUX_RPMSG_BASE=$LINUX_RPMSG_BASE
			export LINUX_RPMSG_SIZE=$(amp_get_value "$EXT_SHARE" "rpmsg_size")
		fi
	fi

	ITS_IMAGES=$(grep -wE "amp[0-9]* {" $ITS_FILE | grep -o amp[0-9]*)
	build_images "$ITS_IMAGES"

	cd "$RK_OUTDIR"
	ln -rsf $ITS_FILE amp.its
	sed -i '/share {/,/}/d' amp.its
	sed -i '/compile {/,/}/d' amp.its

	$RK_RTOS_BSP_DIR/tools/mkimage -f amp.its -E -p 0xe00 $RK_FIRMWARE_DIR/amp.img

	finish_build amp $@
}

source "${RK_BUILD_HELPER:-$(dirname "$(realpath "$0")")/../build-hooks/build-helper}"

build_hook $@
