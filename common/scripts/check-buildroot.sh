#!/bin/bash -e

SCRIPTS_DIR="${SCRIPTS_DIR:-$(dirname "$(realpath "$0")")}"
SDK_DIR="${SDK_DIR:-$SCRIPTS_DIR/../../../..}"
BUILDROOT_DIR="$SDK_DIR/buildroot"

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
echo "make make -j8"
echo "install -m 0755 make /usr/local/bin/make"
exit 1
