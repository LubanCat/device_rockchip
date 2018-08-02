#!/bin/bash

SRC=$1
DST=$2
SIZE=$(du -h -BM -s $SRC | awk '{print int($1)*1024}')
SIZE=`expr $SIZE + 1024`
echo "create image size=${SIZE}K"
genext2fs -b $SIZE -d $SRC $DST
e2fsck -fy $DST
