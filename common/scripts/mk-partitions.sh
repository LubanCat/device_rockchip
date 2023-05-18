#!/bin/bash -e

print_parameter()
{
	return 0
}

# Hooks

usage_hook()
{
	echo -e "print-parts                        \tprint partitions"
	echo -e "edit-parts                         \tedit raw partitions"
	echo -e "new-parts:<offset>:<name>:<size>...\tre-create partitions"
	echo -e "insert-part:<idx>:<name>[:<size>]  \tinsert partition"
	echo -e "del-part:(<idx>|<name>)            \tdelete partition"
	echo -e "move-part:(<idx>|<name>):<idx>     \tmove partition"
	echo -e "rename-part:(<idx>|<name>):<name>  \trename partition"
	echo -e "resize-part:(<idx>|<name>):<size>  \tresize partition"
}

PRE_BUILD_CMDS="print-parts edit-parts new-parts insert-part del-part move-part rename-part resize-part"
pre_build_hook()
{
	check_config RK_PARAMETER || return 0

	CMD=$1
	shift

	case "$CMD" in
		print-parts) rk_partition_print $@ ;;
		edit-parts) rk_partition_edit $@ ;;
		new-parts) rk_partition_create $@ ;;
		insert-part) rk_partition_insert $@ ;;
		del-part) rk_partition_del $@ ;;
		move-part) rk_partition_move $@ ;;
		rename-part) rk_partition_rename $@ ;;
		resize-part) rk_partition_resize $@ ;;
	esac

	finish_build $CMD $@
}

source "${BUILD_HELPER:-$(dirname "$(realpath "$0")")/../build-hooks/build-helper}"

pre_build_hook $@
