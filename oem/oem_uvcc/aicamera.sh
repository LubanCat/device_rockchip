#!/bin/sh
#

check_alive()
{
  PID=`busybox ps |grep $1 |grep -v grep | wc -l`
  if [ $PID -le 0 ];then
     killall  -3 mediaserver
     if [ "$1"x == "uvc_app"x ];then
       killall -9 uvc_app
       reboot
     else
       if [ "$1"x == "ispserver"x ];then
          ispserver -no-sync-db &
       else
          $1 &
       fi
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

usb_irq_set()
{
  #for usb uvc iso
  usbirq=`cat /proc/interrupts |grep dwc3| awk '{print $1}'|tr -cd "[0-9]"`
  echo "usb irq:$usbirq"
  echo 1 > /proc/irq/$usbirq/smp_affinity_list
}

dbserver &
ispserver -no-sync-db &
stop_unused_daemon
/oem/usb_config.sh rndis
usb_irq_set
uvc_app &
while true
do
  check_alive dbserver
  check_alive ispserver
  check_alive uvc_app
  check_alive smart_display_service
  sleep 2
done
