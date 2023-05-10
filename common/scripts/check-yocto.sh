#!/bin/bash -e

SCRIPTS_DIR="${SCRIPTS_DIR:-$(dirname "$(realpath "$0")")}"

if ! ping google.com -c 1 -W 1 &>/dev/null; then
	echo -e "\e[35mYour network is not able to access google.com\e[0m"
	echo -e "\e[35mPlease setup a VPN to bypass the GFW.\e[0m"
	exit 1
fi

if ! which zstd >/dev/null 2>&1; then
	echo -e "\e[35mYour zstd is missing\e[0m"
	echo "Please install it:"
	echo "sudo apt-get install zstd"
	exit 1
fi

PYTHON3_MIN_VER=$(python3 --version | cut -d'.' -f2)
if [ "${PYTHON3_MIN_VER:-0}" -lt 6 ]; then
	echo -e "\e[35mYour python3 is too old for yocto: $(python3 --version)\e[0m"
	echo "Please update it:"
	"$SCRIPTS_DIR/python3-install.sh"
	exit 1
fi
