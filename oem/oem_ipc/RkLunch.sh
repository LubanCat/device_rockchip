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

#vpu 600M
echo 600 >/sys/kernel/debug/mpp_service/rkvenc/clk_core

#cpu x2
echo 0 > /sys/devices/system/cpu/cpu2/online
echo 0 > /sys/devices/system/cpu/cpu3/online

#npu 600M
echo 600000000 > /sys/kernel/debug/clk/clk_core_npu/clk_rate
echo 600000000 > /sys/kernel/debug/clk/aclk_npu/clk_rate

ipc-daemon --no-mediaserver &

ls /sys/class/drm | grep "card0-"
if [ $? -ne 0 ] ;then
  echo "not found display"
  HasDisplay=0
else
  echo "find display"
  HasDisplay=1
fi

if [ $HasDisplay -eq 1 ]; then
  sh /oem/isppx4_init.sh
  sleep 2
  mediaserver -c /oem/usr/share/mediaserver/rv1109/camerax4_audio_g711a_rga_mp4_rtsp_rtmp_jpeg_face_display_v2.conf &
  #mediaserver -c /oem/usr/share/mediaserver/rv1109/camerax4_audio_g711a_rga_mp4_rtsp_rtmp_face_display_v3.conf &
else
  sh /oem/isppx3_init.sh
  sleep 2
  mediaserver -c /oem/usr/share/mediaserver/rv1109/camerax3_audio_g711a_rga_mp4_rtsp_rtmp_jpeg_face_v2.conf &
  #mediaserver -c /oem/usr/share/mediaserver/rv1109/camerax3_audio_g711a_rga_mp4_rtsp_rtmp_face_v3.conf &
fi
