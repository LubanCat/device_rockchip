#!/bin/bash

sleep 2

amixer -c 0 cset numid=34 12
amixer -c 0 cset numid=40 1
amixer -c 0 cset numid=41 1
amixer -c 0 cset numid=44 3
amixer -c 0 cset numid=45 3
amixer -c 0 cset numid=46 30
amixer -c 0 cset numid=47 30

echo 1 > /sys/devices/platform/ff560000.acodec/rk3308-acodec-dev/dac_output
sleep 1
echo 11 > /sys/devices/platform/ff560000.acodec/rk3308-acodec-dev/dac_output
sleep 1
while true; do
    dac_output=$(cat /sys/devices/platform/ff560000.acodec/rk3308-acodec-dev/dac_output)
    if [ "$dac_output" != "dac path: both line out and hp out" ]; then
        echo "Content is not 'dac path: both line out and hp out'. Setting dac_output to 1."
        echo 11 > /sys/devices/platform/ff560000.acodec/rk3308-acodec-dev/dac_output
    fi
    sleep 1
done
