#!/bin/bash -e

RK_SCRIPTS_DIR="${RK_SCRIPTS_DIR:-$(dirname "$(realpath "$0")")}"
RK_SDK_DIR="${RK_SDK_DIR:-$RK_SCRIPTS_DIR/../../../..}"
RK_OWNER="${RK_OWNER:-$(stat --format %U "$RK_SDK_DIR")}"
RK_OWNER_UID="${RK_OWNER_UID:-$(stat --format %u "$RK_SDK_DIR")}"

# Check /etc/passwd directly for pseudo environment
if ! cut -d':' -f3 /etc/passwd | grep -q "^$RK_OWNER_UID$"; then
	echo -e "\e[35m"
	echo "ERROR: Unknown source owner($RK_OWNER_UID)"
	echo "Please create it:"
	echo "sudo useradd rk_compiler -u $RK_OWNER_UID"
	echo -e "\e[0m"
	exit 1
fi

if [ "$(id -u)" -ne 0 ] && [ "$RK_OWNER_UID" -ne "$(id -u)" ]; then
	echo -e "\e[35m"
	echo "ERROR: Current user is not the owner of SDK source!"
	echo "Please switch to user($RK_OWNER), or change owner of SDK code:"
	echo "sudo chown -h -R $(id -un) $RK_SDK_DIR/"
	echo -e "\e[0m"
	exit 1
fi

if ! which rsync >/dev/null 2>&1; then
	echo -e "\e[35m"
	echo "Your rsync is missing"
	echo "Please install it:"
	echo "sudo apt-get install rsync"
	echo -e "\e[0m"
	exit 1
fi

if ! which python3 >/dev/null 2>&1; then
	echo -e "\e[35m"
	echo "Your python3 is missing"
	echo "Please install it:"
	"$RK_SCRIPTS_DIR/install-python3.sh"
	echo -e "\e[0m"
	exit 1
fi
