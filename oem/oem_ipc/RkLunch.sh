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

export HDR_MODE=0

#vpu 600M
echo 600 >/sys/kernel/debug/mpp_service/rkvenc/clk_core

#cpu x2
#echo 0 > /sys/devices/system/cpu/cpu2/online
#echo 0 > /sys/devices/system/cpu/cpu3/online

#npu 600M
echo userspace > /sys/devices/platform/ffbc0000.npu/devfreq/ffbc0000.npu/governor
echo 600000000 > /sys/devices/platform/ffbc0000.npu/devfreq/ffbc0000.npu/userspace/set_freq

ipc-daemon --no-mediaserver &

ls /sys/class/drm | grep "card0-"
if [ $? -ne 0 ] ;then
  echo "not found display"
  HasDisplay=0
else
  echo "find display"
  HasDisplay=1
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
			sh /oem/isppx4_init.sh
			mediaserver -c /oem/usr/share/mediaserver/rv1109/ipc-display.conf &
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
			sh /oem/isppx3_init.sh
			mediaserver -c /oem/usr/share/mediaserver/rv1109/ipc.conf &
		else
			break;
		fi
		sleep 3
	done
fi
