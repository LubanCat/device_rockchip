#!/bin/sh
#

#for usb uvc iso
usbirq=`cat /proc/interrupts |grep dwc3| awk '{print $1}'|tr -cd "[0-9]"`
echo "usb irq:$usbirq"
echo 1 > /proc/irq/$usbirq/smp_affinity_list

export VIV_VX_ENABLE_NN_DDR_BURST_SIZE_256B=0
export VIV_VX_MAX_SOC_OT_NUMBER=16

#rkmedia isp ctrl
export HDR_MODE=0
export ENABLE_SKIP_FRAME=1

#export ENABLE_EPTZ=1

/oem/aicamera.sh &
