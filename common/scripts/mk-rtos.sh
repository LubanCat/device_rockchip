#!/bin/bash -e

MAX_CORE_NUMBERS=16
RK_RTOS_BSP_DIR=$RK_SDK_DIR/rtos/bsp/rockchip
ITS_FILE="$RK_CHIP_DIR/$RK_RTOS_FIT_ITS"

RK_SCRIPTS_DIR="${RK_SCRIPTS_DIR:-$(dirname "$(realpath "$0")")}"

usage_hook()
{
	echo -e "rtos                             \tbuild and pack RTOS"
}

build_hal()
{
	check_config RK_RTOS_HAL_TARGET || return 0

	message "=========================================="
	message "  Building CPU$1: HAL-->$RK_RTOS_HAL_TARGET"
	message "=========================================="

	cd "$RK_RTOS_BSP_DIR/common/hal/project/$RK_RTOS_HAL_TARGET/GCC"

	export FIRMWARE_CPU_BASE=$(grep -wE "amp[0-9]* {|load" $ITS_FILE | grep amp$1 -A1 | grep load | cut -d'<' -f2 | cut -d'>' -f1)
	echo "FIRMWARE_CPU_BASE=$FIRMWARE_CPU_BASE"
	export DRAM_SIZE=$(grep -wE "amp[0-9]* {|size" $ITS_FILE | grep amp$1 -A1 | grep size | cut -d'<' -f2 | cut -d'>' -f1)
	echo "DRAM_SIZE=$DRAM_SIZE"
	export SRAM_BASE=$(grep -wE "amp[0-9]* {|srambase" $ITS_FILE | grep amp$1 -A1 | grep srambase | cut -d'<' -f2 | cut -d'>' -f1)
	echo "SRAM_BASE=$SRAM_BASE"
	export SRAM_SIZE=$(grep -wE "amp[0-9]* {|sramsize" $ITS_FILE | grep amp$1 -A1 | grep sramsize | cut -d'<' -f2 | cut -d'>' -f1)
	echo "SRAM_SIZE=$SRAM_SIZE"
	export SHMEM_BASE=$(grep -wE -A3 "share_memory {" $ITS_FILE | grep base | cut -d'<' -f2 | cut -d'>' -f1)
	echo "SHMEM_BASE=$SHMEM_BASE"
	export SHMEM_SIZE=$(grep -wE -A3 "share_memory {" $ITS_FILE | grep size | cut -d'<' -f2 | cut -d'>' -f1)
	echo "SHMEM_SIZE=$SHMEM_SIZE"

	export CUR_CPU=$1
	echo "CUR_CPU=$CUR_CPU"
	AMP_PRIMARY_CORE=$(printf "%d" $(grep -wE "configurations {|primary" $ITS_FILE | grep primary | cut -d'<' -f2 | cut -d'>' -f1))
	if [ "$AMP_PRIMARY_CORE" = "$1" ]; then
		export AMP_PRIMARY_CORE=$AMP_PRIMARY_CORE
		echo "AMP_PRIMARY_CORE=$AMP_PRIMARY_CORE"
	fi

	make clean > /dev/null
	rm -rf hal$1.elf hal$1.bin
	make -j$(nproc) > ${RK_SDK_DIR}/hal.log 2>&1
	cp TestDemo.elf hal$1.elf
	mv TestDemo.bin hal$1.bin
	ln -rsf hal$1.bin $RK_OUTDIR/cpu$1.bin

	finish_build build_hal $@
}

build_rtthread()
{
	check_config RK_RTOS_RTT_TARGET || return 0

	message "=========================================="
	message "  Building CPU$1: RT-Thread-->$RK_RTOS_RTT_TARGET"
	message "=========================================="

	cd "$RK_RTOS_BSP_DIR/$RK_RTOS_RTT_TARGET"

	export RTT_PRMEM_BASE=$(grep -wE "amp[0-9]* {|load" $ITS_FILE | grep amp$1 -A1 | grep load | cut -d'<' -f2 | cut -d'>' -f1)
	echo "RTT_PRMEM_BASE=$RTT_PRMEM_BASE"
	export RTT_PRMEM_SIZE=$(grep -wE "amp[0-9]* {|size" $ITS_FILE | grep amp$1 -A1 | grep size | cut -d'<' -f2 | cut -d'>' -f1)
	echo "RTT_PRMEM_SIZE=$RTT_PRMEM_SIZE"
	export RTT_SRAM_BASE=$(grep -wE "amp[0-9]* {|srambase" $ITS_FILE | grep amp$1 -A1 | grep srambase | cut -d'<' -f2 | cut -d'>' -f1)
	echo "RTT_SRAM_BASE=$RTT_SRAM_BASE"
	export RTT_SRAM_SIZE=$(grep -wE "amp[0-9]* {|sramsize" $ITS_FILE | grep amp$1 -A1 | grep sramsize | cut -d'<' -f2 | cut -d'>' -f1)
	echo "RTT_SRAM_SIZE=$RTT_SRAM_SIZE"
	export RTT_SHMEM_BASE=$(grep -wE -A3 "share_memory {" $ITS_FILE | grep base | cut -d'<' -f2 | cut -d'>' -f1)
	echo "RTT_SHMEM_BASE=$RTT_SHMEM_BASE"
	export RTT_SHMEM_SIZE=$(grep -wE -A3 "share_memory {" $ITS_FILE | grep size | cut -d'<' -f2 | cut -d'>' -f1)
	echo "RTT_SHMEM_SIZE=$RTT_SHMEM_SIZE"

	ROOT_PART_OFFSET=$(rk_partition_start rootfs)
	if [ -n $ROOT_PART_OFFSET ];then
		export ROOT_PART_OFFSET=$ROOT_PART_OFFSET
	fi

	ROOT_PART_SIZE=$(rk_partition_size rootfs)
	if [ -n $ROOT_PART_SIZE ];then
		export ROOT_PART_SIZE=$ROOT_PART_SIZE
	fi

	export CUR_CPU=$1
	echo "CUR_CPU=$CUR_CPU"
	AMP_PRIMARY_CORE=$(printf "%d" $(grep -wE "configurations {|primary" $ITS_FILE | grep primary | cut -d'<' -f2 | cut -d'>' -f1))
	if [ "$AMP_PRIMARY_CORE" = "$1" ]; then
		export AMP_PRIMARY_CORE=$AMP_PRIMARY_CORE
		echo "AMP_PRIMARY_CORE=$AMP_PRIMARY_CORE"
	fi

	export RK_RTTHREAD_DEFCONFIG=$(eval echo \$RK_RTOS_RTT$1_BOARD_CONFIG)

	if [ -f "$RK_RTTHREAD_DEFCONFIG" ] ;then
		scons --useconfig="$RK_RTTHREAD_DEFCONFIG"
	else
		warning "Warning: RK_RTOS_RTT$1_BOARD_CONFIG config ($RK_RTTHREAD_DEFCONFIG) not exit!\n"
		warning "Default config(.config) will be used!\n"
	fi

	scons -c > /dev/null
	rm -rf gcc_arm.ld Image/rtt$1.elf Image/rtt$1.bin
	scons -j$(nproc) > ${RK_SDK_DIR}/rtt.log 2>&1
	cp rtthread.elf Image/rtt$1.elf
	mv rtthread.bin Image/rtt$1.bin
	ln -rsf Image/rtt$1.bin $RK_OUTDIR/cpu$1.bin

	if [ -n "$RK_RTOS_RTT_ROOTFS_DATA" ] && [ -n "$ROOT_PART_SIZE" ] ;then

		RTT_TOOLS_PATH=$RK_RTOS_BSP_DIR/$RK_RTOS_RTT_TARGET/../tools
		RTT_ROOTFS_USERDAT=$RK_RTOS_BSP_DIR/$RK_RTOS_RTT_TARGET/$RK_RTOS_RTT_ROOTFS_DATA
		RTT_ROOTFS_SECTOR_SIZE=$(($(printf "%d" $ROOT_PART_SIZE) / 8)) # covert to 4096B

		dd of=root.img bs=4K seek=$RTT_ROOTFS_SECTOR_SIZE count=0 2>&1 || fatal "Failed to dd image!"
		mkfs.fat -S 4096 root.img
		MTOOLS_SKIP_CHECK=1 $RTT_TOOLS_PATH/mcopy -bspmn -D s -i root.img $RTT_ROOTFS_USERDAT/* ::/

		mv root.img Image/
		ln -rsf Image/root.img $RK_FIRMWARE_DIR/rootfs.img
	fi

	finish_build build_rtthread $@
}

clean_hook()
{
	[ "$RK_RTOS" ] || return 0

	cd "$RK_RTOS_BSP_DIR/$RK_RTOS_RTT_TARGET"
	scons -c >/dev/null || true

	cd "$RK_RTOS_BSP_DIR/common/hal/project/$RK_RTOS_HAL_TARGET/GCC"
	make clean >/dev/null || true

	rm -rf "$RK_FIRMWARE_DIR/amp.img"
}

BUILD_CMDS="rtos"
build_hook()
{
	local i

	check_config RK_RTOS || false

	message "=========================================="
	message "          Start building RTOS"
	message "=========================================="

	"$RK_SCRIPTS_DIR/check-rtos.sh"

	export CROSS_COMPILE=$(get_toolchain RTOS "$RK_RTOS_ARCH" "" none)
	[ "$CROSS_COMPILE" ] || exit 1

	if [ -f "$RK_CHIP_DIR/$RK_RTOS_CFG" ]; then
		set -a
		source $RK_CHIP_DIR/$RK_RTOS_CFG
		set +a
	fi

	CORE_NUMBERS=$(grep -wcE "amp[0-9]* {" $ITS_FILE)
	echo "CORE_NUMBERS=$CORE_NUMBERS"
	for ((i = 0; i < $MAX_CORE_NUMBERS; i++)); do
		CORE_ID=$(printf "%d" $(grep -wE "amp[0-9]* {|cpu" $ITS_FILE | grep amp${i} -A1 | grep cpu | cut -d'<' -f2 | cut -d'>' -f1))
		CORE_SYS=$(grep -wE "amp[0-9]* {|sys" $ITS_FILE | grep amp${i} -A1 | grep sys | cut -d'"' -f2)

		if ! [ "$CORE_ID" -lt "$MAX_CORE_NUMBERS" ] 2>/dev/null; then
			error "Invalid core($CORE_ID) should be (0-$MAX_CORE_NUMBERS)!"
			exit 1
		fi

		case $CORE_SYS in
			hal)
				build_hal $CORE_ID
				;;
			rtt)
				build_rtthread $CORE_ID
				;;
		esac
	done

	cd "$RK_OUTDIR"
	ln -rsf $ITS_FILE amp.its
	$RK_RTOS_BSP_DIR/tools/mkimage -f amp.its -E -p 0xe00 $RK_FIRMWARE_DIR/amp.img

	finish_build rtos $@
}

source "${RK_BUILD_HELPER:-$(dirname "$(realpath "$0")")/../build-hooks/build-helper}"

build_hook $@
