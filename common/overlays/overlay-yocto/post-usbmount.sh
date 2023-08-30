#!/bin/bash -e

POST_ROOTFS_ONLY=1

source "${POST_HELPER:-$(dirname "$(realpath "$0")")/../post-hooks/post-helper}"

[ -z "$RK_USBMOUNT_DISABLED" ] || exit 0

if [ "$RK_USBMOUNT_DEFAULT" -a "$POST_OS" != yocto ]; then
	echo -e "\e[33mIgnore usbmount for $POST_OS by default\e[0m"
	exit 0
fi

