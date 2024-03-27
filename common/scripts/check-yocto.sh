#!/bin/bash -e

RK_SCRIPTS_DIR="${RK_SCRIPTS_DIR:-$(dirname "$(realpath "$0")")}"
RK_SDK_DIR="${RK_SDK_DIR:-$(realpath "$RK_SCRIPTS_DIR/../../../..")}"

if ! ping google.com -c 1 -W 1 &>/dev/null; then
	echo -e "\e[35m"
	echo "Your network is not able to access google.com"
	echo "Please setup a VPN to bypass the GFW."
	echo -e "\e[0m"
	exit 1
fi

if ! which zstd >/dev/null 2>&1; then
	echo -e "\e[35m"
	echo "Your zstd is missing"
	echo "Please install it:"
	echo "sudo apt-get install zstd"
	echo -e "\e[0m"
	exit 1
fi

PYTHON3_MIN_VER=$(python3 --version | cut -d'.' -f2)
if [ "${PYTHON3_MIN_VER:-0}" -lt 6 ]; then
	echo -e "\e[35m"
	echo "Your python3 is too old for yocto: $(python3 --version)"
	echo "Please update it:"
	"$RK_SCRIPTS_DIR/install-python3.sh"
	echo -e "\e[0m"
	exit 1
fi

# The yocto's e2fsprogs doesn't support new features like
# metadata_csum_seed and orphan_file
if grep -wq metadata_csum_seed /etc/mke2fs.conf; then
	echo -e "\e[35m"
	echo "Your mke2fs is too new: $(mke2fs -V 2>&1 | head -n 1)"
	echo "Please downgrade it:"
	"$RK_SCRIPTS_DIR/install-e2fsprogs.sh"
	echo -e "\e[0m"
	exit 1
fi

cd "$RK_SDK_DIR/yocto/poky/"
if ! git log --oneline bitbake/lib/bb/fetch2/git.py | \
	grep -q -m 1 "Fix local clone url to make it work with repo"; then
	echo -e "\e[35m"
	echo "Your yocto poky layer is too old for local clone."
	echo "Please upgrade it to:"
	echo "https://github.com/yoctoproject/poky/commit/ac3eb241"
	echo -e "\e[0m"
	exit 1
fi

for dir in "$RK_SDK_DIR"/*/.git "$RK_SDK_DIR"/external/*/.git; do
	PROJ="$(dirname "$dir")"
	[ -f "$PROJ/.git/gc.pid" ] || continue

	echo -e "\e[35m"
	echo "GIT is automatically packing loose objects in $PROJ/"
	echo "Please wait for it:"
	echo "while [ -f \"$PROJ/.git/gc.pid\" ]; do sleep 1; done"
	echo -e "\e[0m"
	exit 1
done

if ! [ "$(git config --global gc.autoDetach)" = false ]; then
	echo -e "\e[35m"
	echo "Please disable the auto-detaching feature of git gc:"
	echo "git config --global gc.autoDetach false"
	echo -e "\e[0m"
	exit 1
fi
