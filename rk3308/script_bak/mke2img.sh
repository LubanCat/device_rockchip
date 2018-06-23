#!/bin/bash

SRC=$1
DST=$2
dd if=/dev/zero of=$DST bs=1M count=1
mke2fs -t ext2 $DST
mke2fs -F -d $SRC $DST
