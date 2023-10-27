#!/bin/bash -e

RK_SCRIPTS_DIR="${RK_SCRIPTS_DIR:-$(dirname "$(realpath "$0")")}"
RK_SDK_DIR="${RK_SDK_DIR:-$RK_SCRIPTS_DIR/../../../..}"

cd "$RK_SDK_DIR"

for chip in ${@:-""}; do
	for c in $(find "device/rockchip/.chips/$(basename "$chip")" \
		-mindepth 1 -maxdepth 2 -type f \
		-name "rockchip_*_defconfig"); do
		./build.sh $c
		make savedefconfig
		sed -i '/RK_KERNEL_VERSION/d' $c
	done
done
