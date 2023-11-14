#!/bin/bash -e

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
