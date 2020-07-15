#!/bin/sh
#

#for usb uvc iso
usbirq=`cat /proc/interrupts |grep dwc3| awk '{print $1}'|tr -cd "[0-9]"`
echo "usb irq:$usbirq"
echo 1 > /proc/irq/$usbirq/smp_affinity_list

export VIV_VX_ENABLE_NN_DDR_BURST_SIZE_256B=0
export VIV_VX_MAX_SOC_OT_NUMBER=16

if [ -e /sys/firmware/devicetree/base/__symbols__/gc4c33 ] ;then
  echo "isp sensor is gc4c33,disable HDR"
  export HDR_MODE=0
else
if [ -e /sys/firmware/devicetree/base/__symbols__/os04a10 ] ;then
  echo "isp sensor is os04a10,enable HDR"
  export HDR_MODE=1
else
if [ -e /sys/firmware/devicetree/base/__symbols__/imx347 ] ;then
  echo "isp sensor is imx347,enable HDR"
  export HDR_MODE=1
else
if [ -e /sys/firmware/devicetree/base/__symbols__/ov4689 ] ;then
  echo "isp sensor is ov4689,enable HDR"
  export HDR_MODE=1
else
  echo "unkonw sensor,disable HDR default"
  export HDR_MODE=0
fi
fi
fi
fi

camera_max_width=`media-ctl -p | awk -v line=$(media-ctl -p | awk '/Sensor/{print NR}') '{if(NR==line+3){print $0}}' | awk -F '[/,@,x]' '{print $2}'`
camera_max_height=`media-ctl -p | awk -v line=$(media-ctl -p | awk '/Sensor/{print NR}') '{if(NR==line+3){print $0}}' | awk -F '[/,@,x]' '{print $3}'`

echo ${camera_max_width}
echo ${camera_max_height}
export CAMERA_MAX_WIDTH=${camera_max_width}
export CAMERA_MAX_HEIGHT=${camera_max_height}

#rkmedia isp ctrl
export ENABLE_SKIP_FRAME=1

#export ENABLE_EPTZ=1

/oem/aicamera.sh &
