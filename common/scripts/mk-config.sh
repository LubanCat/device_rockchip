#!/bin/bash -e

MAKE="make -C $(realpath --relative-to="$SDK_DIR" "$COMMON_DIR")"

switch_defconfig()
{
	CONFIG="$1"

	[ -f "$CONFIG" ] || CONFIG="$CHIP_DIR/$CONFIG"

	if [ ! -f "$CONFIG" ]; then
		echo "No such defconfig: $1"
		exit 1
	fi

	echo "Switching to defconfig: $CONFIG"
	rm -f "$RK_DEFCONFIG"
	ln -rsf "$CONFIG" "$RK_DEFCONFIG"

	$MAKE $(basename "$CONFIG")
	exit 0
}

rockchip_defconfigs()
{
	cd "$CHIP_DIR"
	ls rockchip_defconfig 2>/dev/null || true
	ls *_defconfig | grep -v rockchip_defconfig || true
}

lunch()
{
	CONFIG_ARRAY=( $(rockchip_defconfigs) )

	CONFIG_ARRAY_LEN=${#CONFIG_ARRAY[@]}
	if [ $CONFIG_ARRAY_LEN -eq 0 ]; then
		echo "No available defconfig"
		return 1
	fi

	if [ $CONFIG_ARRAY_LEN -eq 1 ]; then
		switch_defconfig ${CONFIG_ARRAY[0]}
		return 0
	fi

	echo
	echo "You're building on Linux"
	echo "Lunch menu...pick a combo:"
	echo ""

	echo ${CONFIG_ARRAY[@]} | xargs -n 1 | sed "=" | sed "N;s/\n/. /"

	local INDEX
	read -p "Which would you like? [1]: " INDEX
	INDEX=$((${INDEX:-1} - 1))
	CONFIG="${CONFIG_ARRAY[$INDEX]}"

	switch_defconfig $CONFIG
}

# Hooks

usage_hook()
{
	echo "lunch              - choose defconfig"
	echo "*_defconfig        - switch to specified defconfig"
	echo "    Available defconfigs:"
	echo "$(ls "$CHIP_DIR/" | grep "defconfig$" | sed "s/^/\t/")"
	echo "olddefconfig       - resolve any unresolved symbols in .config"
	echo "savedefconfig      - save current config to defconfig"
	echo "menuconfig         - interactive curses-based configurator"
}

clean_hook()
{
	RK_BUILDING=1 $MAKE distclean
}

INIT_CMDS="lunch .*_defconfig olddefconfig savedefconfig menuconfig default"
init_hook()
{
	case "${1:-default}" in
		lunch) lunch ;;
		*_defconfig) switch_defconfig "$1" ;;
		olddefconfig | savedefconfig | menuconfig) $MAKE $1 ;;
		default) # End of init
			[ -r "$RK_DEFCONFIG" ] || lunch

			DEFCONFIG=$(basename "$(realpath "$RK_DEFCONFIG")")
			[ "$(realpath "$RK_DEFCONFIG")" = \
				"$(realpath "$CHIP_DIR/$DEFCONFIG")" ] || lunch

			if [ "$RK_CONFIG" -ot "$RK_DEFCONFIG" ]; then
				$MAKE $DEFCONFIG
			elif [ "$RK_CONFIG" -ot "$RK_CONFIG_IN" ]; then
				$MAKE $DEFCONFIG
			else
				$MAKE olddefconfig
			fi
			;;
		*) usage ;;
	esac
}

source "${BUILD_HELPER:-$(dirname "$(realpath "$0")")/../build-hooks/build-helper}"

init_hook $@
