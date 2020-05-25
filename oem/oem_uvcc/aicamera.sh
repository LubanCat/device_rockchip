#!/bin/sh
#

check_alive()
{
  PID=`ps |grep $1 |grep -v grep | wc -l`
  if [ $PID -le 0 ];then
     if [ "$1"x == "uvc_app"x ];then
       killall -9 mediaserver
       killall -9 uvc_app
       reboot
     else
       $1 &
     fi
  fi
  
}

uvc_config.sh rndis
uvc_app &
while true
do
  check_alive uvc_app
  check_alive smart_display_service
  sleep 2
done
