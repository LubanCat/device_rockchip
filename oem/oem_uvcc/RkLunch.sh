#!/bin/sh
#

#for usb uvc iso
echo 1 > /proc/irq/71/smp_affinity_list
echo performance > /sys/bus/cpu/devices/cpu0/cpufreq/scaling_governor

#vpu 600m
#echo 600 >/sys/kernel/debug/mpp_service/rkvenc/clk_core

#cpux2
#echo 0 > /sys/devices/system/cpu/cpu2/online
#echo 0 > /sys/devices/system/cpu/cpu3/online

#npu 600m
#echo 600000000 >/sys/kernel/debug/clk/clk_core_npu/clk_rate
#echo 600000000 >/sys/kernel/debug/clk/aclk_npu/clk_rate


#mediaserver need
dbserver &
storage_manager &

/oem/aicamera.sh &
#/oem/eptz.sh &
