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

# ispp using fbc420 mode to save ddr bandwidth
echo 1 > /sys/module/video_rkispp/parameters/mode

#vpu 600M, kernel default 600M
#echo 600000000 >/sys/kernel/debug/mpp_service/rkvenc/clk_core

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

# mount media part for video recording
export MEDIA_DEV=/dev/block/by-name/media
export FSTYPE=ext4

prepare_part()
{
  dumpe2fs -h $MEDIA_DEV 2>/dev/null| grep "media"
  if [ $? -ne 0 ]; then
    echo "Auto formatting $MEDIA_DEV to $FSTYPE"
    mke2fs -F -L media $MEDIA_DEV && tune2fs -c 0 -i 0 $MEDIA_DEV && prepare_part && return
  fi
}
prepare_part()
echo "prepare_part /userdata/media"
mkdir -p /userdata/media && sync
echo "fsck /userdata/media"
fsck.$FSTYPE -y $MEDIA_DEV
mount $MEDIA_DEV /userdata/media
dbus-send --system --print-reply --dest=rockchip.StorageManager / rockchip.StorageManager.file.AddDisk string:"/userdata/media"
