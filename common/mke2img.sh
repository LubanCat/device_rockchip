#!/bin/bash

SRC=$1
DST=$2
SIZE=`du -sk --apparent-size $SRC | cut --fields=1`
inode_counti=`find $SRC | wc -l`
inode_counti=$[inode_counti+512]
EXTRA_SIZE=$[inode_counti*4]

MAX_RETRY=10
RETRY=0
while true;do
    SIZE=$[SIZE+EXTRA_SIZE]
    echo "genext2fs -b $SIZE -N $inode_counti -d $SRC $DST"
    genext2fs -b $SIZE -N $inode_counti -d $SRC $DST && break

    RETRY=$[RETRY+1]
    [ ! $RETRY -lt $MAX_RETRY ] && { echo "Failed to make e2fs image! "; exit; }
    echo "Retring with increased size....($RETRY/$MAX_RETRY)"
done

tune2fs -c 1 -i 0 $DST
resize2fs -M $DST
e2fsck -fyD $DST
