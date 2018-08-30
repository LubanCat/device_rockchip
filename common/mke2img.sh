#!/bin/bash

SRC=$1
DST=$2
SIZE=`du -s --apparent-size $SRC | cut --fields=1`
SIZE=`expr '(' '(' $SIZE / 1024 ')' + 3 ')' '*' 1024 `
inode_counti=`expr '(' $SIZE / 4 ')'`
echo "SIZE = $SIZE"
echo "genext2fs -b $SIZE -N $inode_counti -d $SRC $DST"
genext2fs -b $SIZE -N $inode_counti -d $SRC $DST
e2fsck -fy $DST
