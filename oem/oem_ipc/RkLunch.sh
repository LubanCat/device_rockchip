#!/bin/sh
#

check_linker()
{
	[ ! -L "$2" ] && ln -sf $1 $2
}

check_linker /userdata   /oem/www/userdata
check_linker /userdata   /oem/www/userdata
check_linker /media/usb0 /oem/www/usb0
check_linker /mnt/sdcard /oem/www/sdcard

#set max socket buffer size to 1.5MByte
sysctl -w net.core.wmem_max=1572864

export HDR_MODE=1
export enable_encoder_debug=0

#vpu 600M, kernel default 600M
#echo 600000000 >/sys/kernel/debug/mpp_service/rkvenc/clk_core

#cpu x2
#echo 0 > /sys/devices/system/cpu/cpu2/online
#echo 0 > /sys/devices/system/cpu/cpu3/online

ipc-daemon --no-mediaserver &
sleep 3
ispserver &
sleep 1

ls /sys/class/drm | grep "card0-"
if [ $? -ne 0 ] ;then
  echo "not found display"
  HasDisplay=0
else
  echo "find display"
  HasDisplay=1
  cat /proc/device-tree/compatible | grep lt9611
  if [ $? -ne 0 ] ;then
    echo "not HDMI"
  else
    echo "find HDMI"
    HasHDMI=1
  fi
fi

cnt=0
if [ $HasDisplay -eq 1 ]; then
	while [ 1 ];
	do
		cnt=$(( cnt + 1 ))
		if [ $cnt -eq 5 ]; then
			break;
		fi

		ps|grep mediaserver|grep -v grep|grep -v ipc-daemon
		if [ $? -ne 0 ]; then
			if [ $HasHDMI -eq 1 ]; then
				mediaserver -c /oem/usr/share/mediaserver/rv1109/ipc-hdmi-display.conf &
			else
				mediaserver -c /oem/usr/share/mediaserver/rv1109/ipc-display.conf &
			fi
		else
			break;
		fi
		sleep 3
	done
else
	while [ 1 ];
	do
		cnt=$(( cnt + 1 ))
		if [ $cnt -eq 5 ]; then
			break;
		fi
		ps|grep mediaserver|grep -v grep|grep -v ipc-daemon
		if [ $? -ne 0 ]; then
			mediaserver -c /oem/usr/share/mediaserver/rv1109/ipc.conf &
		else
			break;
		fi
		sleep 3
	done
fi
