#!/bin/bash -e

SCRIPTS_DIR="${SCRIPTS_DIR:-$(dirname "$(realpath "$0")")}"
SDK_DIR="${SDK_DIR:-$SCRIPTS_DIR/../../../..}"

cd "$SDK_DIR"

if [ -r "kernel/.config" ]; then
	EXT4_CONFIGS=$(export | grep -oE "\<RK_.*=\"ext4\"$" || true)

	if [ "$EXT4_CONFIGS" ] && \
		! grep -q "CONFIG_EXT4_FS=y" kernel/.config; then
		echo -e "\e[35mYour kernel doesn't support ext4 filesystem\e[0m"
		echo "Please enable CONFIG_EXT4_FS for:"
		echo "$EXT4_CONFIGS"
		exit 1
	fi
fi

if ! kernel/scripts/mkbootimg &>/dev/null; then
	echo -e "\e[35mYour python3 is too old for kernel: $(python3 --version)\e[0m"
	echo "Please update it:"
	"$SCRIPTS_DIR/python3-install.sh"
	exit 1
fi
