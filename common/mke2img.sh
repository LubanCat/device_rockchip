#!/bin/bash

SRC=$1
DST=$2
SIZE=$(du -h -BM --max-depth=0 $SRC | awk '{print int($1)}')
# echo "create image size=${SIZE}M"
dd if=/dev/zero of=$DST bs=1M count=$SIZE >/dev/null 2>&1
mke2fs -F -t ext2 $DST >/dev/null 2>&1
mke2fs -F -d $SRC $DST >/dev/null 2>&1
