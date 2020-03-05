#!/bin/sh
#

dbserver &
storage_manager &
netserver &
mkdir -p /data/video0
mkdir -p /data/video1
mkdir -p /data/photo0
mkdir -p /data/photo1

if [ -f $HOME/usr/share/mediaserver/mediaserver.conf  ]; then
    mediaserver -c $HOME/usr/share/mediaserver/mediaserver.conf -d &
else
    mediaserver -c /usr/share/mediaserver/mediaserver.conf -d &
fi
