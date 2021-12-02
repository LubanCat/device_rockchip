#!/bin/sh
#

[ -f /etc/profile.d/enable_coredump.sh ] && source /etc/profile.d/enable_coredump.sh

export enable_encoder_debug=0

LD_PRELOAD=/oem/libthird_media.so cvr_app &
