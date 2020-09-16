#!/bin/sh
#

check_alive()
{
  PID=`busybox ps |grep $1 |grep -v grep | wc -l`
  if [ $PID -le 0 ];then
     killall -3 aiserver
     if [ "$1"x == "uvc_app"x ];then
       echo " uvc app die ,restart it and usb reprobe !!!"
       sleep 1
       rm -rf /sys/kernel/config/usb_gadget/rockchip/configs/b.1/f*
       echo ffd00000.dwc3  > /sys/bus/platform/drivers/dwc3/unbind
       echo ffd00000.dwc3  > /sys/bus/platform/drivers/dwc3/bind
       /oem/usb_config.sh rndis off #disable adb
       usb_irq_set
       uvc_app &
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
  killall -9 start_rknn.sh
  killall -9 rknn_server
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
