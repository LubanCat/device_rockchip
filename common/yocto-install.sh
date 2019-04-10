#!/bin/sh

[ -z "$1" ] && return

ROOTDIR=$1
echo "Runing install script for $ROOTDIR ..."

# For oem and userdata partitions
mkdir -p "${ROOTDIR}/oem" "${ROOTDIR}/userdata"
cat << EOF >> "${ROOTDIR}/etc/fstab"
PARTLABEL=oem        /oem                 auto       defaults              0  2
PARTLABEL=userdata   /userdata            auto       defaults              0  2
EOF
