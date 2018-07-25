#!/bin/bash

SRC=$1
DST=$2
SIZE=$(du -h -BM -s $SRC | awk '{print int($1)*1000}')
SIZE=`expr $SIZE + 1000`
# echo "create image size=${SIZE}K"
genext2fs -B 1024 -b $SIZE -d $SRC $DST
e2fsck -fy $DST
