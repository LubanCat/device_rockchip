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
sh /oem/isppx2_init.sh
#uvc_flow_test -i /dev/video0 -w 1280 -h 720 -f nv12 -t mjpeg &
#uvc_flow_test -i /dev/video0 -w 1920 -h 1080 -f nv12 -t mjpeg &
while true
do
  check_alive uvc_app
  check_alive smart_display_service
  sleep 2
done
