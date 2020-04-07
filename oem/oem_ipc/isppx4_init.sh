#!/bin/bash
# dmesg | egrep 'isp|camera|5695|v4l2'

#enable scal0
media-ctl -d /dev/media1 -l '"rkispp-subdev":2->"rkispp_scale0":0[1]'
#enable scal1
media-ctl -d /dev/media1 -l '"rkispp-subdev":2->"rkispp_scale1":0[1]'
#enable scal2
media-ctl -d /dev/media1 -l '"rkispp-subdev":2->"rkispp_scale2":0[1]'

# media-ctl -d /dev/media0 --set-v4l2 '"rkisp-isp-subdev":0[crop:(0,0)/2560x1440]'
# media-ctl -d /dev/media0 --set-v4l2 '"rkisp-isp-subdev":2[crop:(0,0)/2560x1440]'

v4l2-ctl -d /dev/video13  --set-fmt-video=width=2688,height=1520,pixelformat=NV12 &
v4l2-ctl -d /dev/video14  --set-fmt-video=width=2688,height=1520,pixelformat=NV12 &
v4l2-ctl -d /dev/video15  --set-fmt-video=width=1280,height=720,pixelformat=NV12 &
v4l2-ctl -d /dev/video16  --set-fmt-video=width=1280,height=720,pixelformat=NV12 &
