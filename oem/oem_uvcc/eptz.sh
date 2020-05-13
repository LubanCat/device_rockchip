#!/bin/sh
#

check_alive()
{
  PID=`ps |grep $1 |grep -v grep | wc -l`
  if [ $PID -le 0 ];then
     $1 &
  fi
  
}

uvc_config.sh rndis
eptz_demo -i rkispp_scale0 -f image:nv12 -n rockx_face_detect:300x300 &
while true
do
  check_alive smart_display_service
  sleep 2
done
