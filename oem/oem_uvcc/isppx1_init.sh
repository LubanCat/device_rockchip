#!/bin/bash
# dmesg | egrep 'isp|camera|5695|v4l2'

#disable bypass
media-ctl -d /dev/media1 -l '"rkispp-subdev":2->"rkispp_m_bypass":0[0]'
#enable scal0
media-ctl -d /dev/media1 -l '"rkispp-subdev":2->"rkispp_scale0":0[1]'


#v4l2-ctl -d /dev/video13  --set-fmt-video=width=2688,height=1520,pixelformat=NV12 --stream-mmap=4 --stream-count=1 --stream-poll &
v4l2-ctl -d /dev/video14  --set-fmt-video=width=2688,height=1520,pixelformat=NV12 &
sleep 3
