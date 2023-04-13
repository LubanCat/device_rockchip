#!/bin/bash -e

MAKE="make ${DEBUG:+V=1} -C $(realpath --relative-to="$SDK_DIR" "$COMMON_DIR")"

switch_defconfig()
{
	DEFCONFIG="$1"

	[ -f "$DEFCONFIG" ] || DEFCONFIG="$CHIP_DIR/$DEFCONFIG"

	if [ ! -f "$DEFCONFIG" ]; then
		echo "No such defconfig: $1"
		exit 1
	fi

	echo "Switching to defconfig: $DEFCONFIG"
	rm -f "$RK_DEFCONFIG"
	ln -rsf "$DEFCONFIG" "$RK_DEFCONFIG"

	DEFCONFIG="$(realpath "$DEFCONFIG")"
	rm -rf "$CHIP_DIR"
	ln -rsf "$(dirname "$DEFCONFIG")" "$CHIP_DIR"

	$MAKE $(basename "$DEFCONFIG")
	exit 0
}

rockchip_defconfigs()
{
	cd "$CHIP_DIR"
	ls rockchip_defconfig 2>/dev/null || true
	ls *_defconfig | grep -v rockchip_defconfig || true
}

choose_defconfig()
{
	DEFCONFIG_ARRAY=( $(rockchip_defconfigs) )

	DEFCONFIG_ARRAY_LEN=${#DEFCONFIG_ARRAY[@]}
	if [ $DEFCONFIG_ARRAY_LEN -eq 0 ]; then
		echo "No available defconfig"
		return 1
	fi

	if [ $DEFCONFIG_ARRAY_LEN -eq 1 ]; then
		switch_defconfig ${DEFCONFIG_ARRAY[0]}
		return 0
	fi

	echo "Pick a defconfig:"
	echo ""

	echo ${DEFCONFIG_ARRAY[@]} | xargs -n 1 | sed "=" | sed "N;s/\n/. /"

	local INDEX
	read -p "Which would you like? [1]: " INDEX
	INDEX=$((${INDEX:-1} - 1))
	DEFCONFIG="${DEFCONFIG_ARRAY[$INDEX]}"

	switch_defconfig $DEFCONFIG
}

choose_chip()
{
	CHIP_ARRAY=( $(ls "$CHIPS_DIR") )
	CHIP_ARRAY_LEN=${#CHIP_ARRAY[@]}
	echo "Pick a chip:"
	echo ""

	echo ${CHIP_ARRAY[@]} | xargs -n 1 | sed "=" | sed "N;s/\n/. /"

	local INDEX
	read -p "Which would you like? [1]: " INDEX
	INDEX=$((${INDEX:-1} - 1))
	CHIP="${CHIP_ARRAY[$INDEX]}"

	rm -rf "$CHIP_DIR"
	ln -rsf "$CHIPS_DIR/$CHIP" "$CHIP_DIR"

	choose_defconfig
}

prepare_config()
{
	[ -e "$CHIP_DIR" ] || choose_chip

	cd "$DEVICE_DIR"
	rm -f $(ls "$CHIPS_DIR")
	ln -rsf "$(readlink "$CHIP_DIR")" .
	cd -

	if [ ! -r "$RK_DEFCONFIG" ]; then
		echo "WARN: $RK_DEFCONFIG not exists"
		choose_defconfig
		return 0
	fi

	DEFCONFIG=$(basename "$(realpath "$RK_DEFCONFIG")")
	if [ ! "$RK_DEFCONFIG" -ef "$CHIP_DIR/$DEFCONFIG" ]; then
		echo "WARN: $RK_DEFCONFIG is invalid"
		choose_defconfig
		return 0
	fi

	if [ "$RK_CONFIG" -ot "$RK_DEFCONFIG" ]; then
		echo "WARN: $RK_CONFIG is out-dated"
		$MAKE $DEFCONFIG
		return 0
	fi

	CONFIG_DIR="$(dirname "$RK_CONFIG_IN")"
	if find "$CONFIG_DIR" -cnewer "$RK_CONFIG" | grep -q ""; then
		echo "WARN: $CONFIG_DIR is updated"
		$MAKE $DEFCONFIG
		return 0
	fi

	CFG="RK_DEFCONFIG=\"$(realpath "$RK_DEFCONFIG")\""
	if ! grep -wq "$CFG" "$RK_CONFIG"; then
		echo "WARN: $RK_CONFIG is invalid"
		$MAKE $DEFCONFIG
		return 0
	fi

	$MAKE olddefconfig
}

# Hooks

usage_hook()
{
	echo "chip               - choose chip"
	echo "defconfig          - choose defconfig"
	echo " *_defconfig       - switch to specified defconfig"
	echo "    Available defconfigs:"
	echo "$(ls "$CHIP_DIR/" | grep "defconfig$" | sed "s/^/\t/")"
	echo " olddefconfig      - resolve any unresolved symbols in .config"
	echo " savedefconfig     - save current config to defconfig"
	echo " menuconfig        - interactive curses-based configurator"
}

clean_hook()
{
	$MAKE distclean
}

INIT_CMDS="chip defconfig lunch .*_defconfig olddefconfig savedefconfig menuconfig default"
init_hook()
{
	case "${1:-default}" in
		chip) choose_chip ;;
		lunch|defconfig) choose_defconfig ;;
		*_defconfig) switch_defconfig "$1" ;;
		olddefconfig | savedefconfig | menuconfig) $MAKE $1 ;;
		default) prepare_config ;; # End of init
		*) usage ;;
	esac
}

source "${BUILD_HELPER:-$(dirname "$(realpath "$0")")/../build-hooks/build-helper}"

init_hook $@
