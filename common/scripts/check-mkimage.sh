#!/bin/bash -e

# mk-image.sh requires -d option to pack e2fs for non-root user
if mke2fs -h 2>&1 | grep -wq "\-d"; then
	exit 0
fi

echo -e "\e[35mYour mke2fs is too old: $(mke2fs -V 2>&1 | head -n 1)\e[0m"
echo "Please update it:"
echo "git clone https://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git --depth 1 -b v1.47.0"
echo "cd e2fsprogs"
echo "./configure"
echo "make"
echo "install -m 0755 misc/mke2fs /usr/local/bin/mke2fs"
exit 1
