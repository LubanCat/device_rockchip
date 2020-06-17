#!/bin/sh
#

check_alive()
{
  PID=`ps |grep $1 |grep -v grep | wc -l`
  if [ $PID -le 0 ];then
     killall -9 mediaserver
     if [ "$1"x == "uvc_app"x ];then
       killall -9 uvc_app
       reboot
     else
       $1 &
     fi
  fi
  
}

stop_unused_daemon()
{
  killall -9 adbd
  killall -9 ntpd
  killall -9 connmand
  killall -9 dropbear
}

ispserver &
uvc_config.sh rndis
stop_unused_daemon
uvc_app &
while true
do
  check_alive ispserver
  check_alive uvc_app
  check_alive smart_display_service
  sleep 2
done
