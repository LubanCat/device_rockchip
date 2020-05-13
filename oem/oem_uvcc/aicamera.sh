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
while true
do
  check_alive uvc_app
  check_alive smart_display_service
  sleep 2
done
