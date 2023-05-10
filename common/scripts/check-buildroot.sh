#!/bin/bash -e

SCRIPTS_DIR="${SCRIPTS_DIR:-$(dirname "$(realpath "$0")")}"
SDK_DIR="${SDK_DIR:-$SCRIPTS_DIR/../../../..}"
BUILDROOT_DIR="$SDK_DIR/buildroot"

# Buildroot brmake needs unbuffer
if ! which unbuffer >/dev/null 2>&1; then
	echo -e "\e[35mYour unbuffer is missing\e[0m"
	echo "Please install it:"
	echo "sudo apt-get install expect expect-dev"
	exit 1
fi

# The new buildroot Makefile needs make (>= 4.0)
if "$BUILDROOT_DIR/support/dependencies/check-host-make.sh" 4.0 make >/dev/null; then
	exit 0
fi

echo -e "\e[35mYour make is too old: $(make -v | head -n 1)\e[0m"
echo "Please update it:"
echo "git clone https://github.com/mirror/make.git --depth 1 -b 4.2"
echo "cd make"
echo "git am $BUILDROOT_DIR/package/make/*.patch"
echo "autoreconf -f -i"
echo "./configure"
echo "sudo make install -j8"
exit 1
