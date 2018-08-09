#!/bin/bash

SRC=$1
DST=$2
SIZE=$(du -h -BM -s $SRC | awk '{print int($1)*1024}')
SIZE=`expr $SIZE + $SIZE / 20`
echo "create image size=${SIZE}K"
echo "genext2fs -b $SIZE -d $SRC $DST"
genext2fs -b $SIZE -d $SRC $DST
e2fsck -fy $DST
