#!/bin/bash

SRC=$1
DST=$2
SIZE=`expr $(du -h --max-depth=1 $SRC | awk '{print int($1)}') + 1`
echo "create image size=${SIZE}M"
dd if=/dev/zero of=$DST bs=1M count=$SIZE
mke2fs -F -t ext2 $DST
mke2fs -F -d $SRC $DST
