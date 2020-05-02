#!/bin/sh
#

#vpu 600m
#echo 600 >/sys/kernel/debug/mpp_service/rkvenc/clk_core

#cpux2
#echo 0 > /sys/devices/system/cpu/cpu2/online
#echo 0 > /sys/devices/system/cpu/cpu3/online

#npu 600M
#echo userspace > /sys/devices/platform/ffbc0000.npu/devfreq/ffbc0000.npu/governor
#echo 600000000 > /sys/devices/platform/ffbc0000.npu/devfreq/ffbc0000.npu/userspace/set_freq

export VIV_VX_ENABLE_NN_DDR_BURST_SIZE_256B=0
export VIV_VX_MAX_SOC_OT_NUMBER=16

#rkmedia isp ctrl
export HDR_MODE=0
export RKISPP_DEV=rkispp_scale0


/oem/aicamera.sh &
#/oem/eptz.sh &
