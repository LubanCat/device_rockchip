# set 1 if you need coredump
export dueros_debug=0

# vad

# arecord -D vad -c 8 -r 16000 -f S16_LE -d 1 -t raw /tmp/test.pcm
# rm /tmp/test.pcm
# echo 0x60 0x40ff0040 > /sys/kernel/debug/vad/reg
# echo 0x5c 0x000e2080 > /sys/kernel/debug/vad/reg

echo 1 > /proc/sys/vm/overcommit_memory

# zram swap

# echo 2 > /sys/block/zram0/max_comp_streams
# echo lz4 > /sys/block/zram0/comp_algorithm
# echo 16M > /sys/block/zram0/disksize
# mkswap /dev/zram0
# swapon /dev/zram0

cd /data/

# for ai-va demo
amixer cset name='Master Volume' 120
amixer cset name='Speaker Volume' 255

# for evb-codec
#amixer -c 1 cset name='DAC HPMIX Left Volume' 1
#amixer -c 1 cset name='DAC HPMIX Right Volume' 1

ifconfig lo 127.0.0.1 netmask 255.255.255.0

#dueros take over control
killall dhcpcd
killall hostapd
killall dnsmasq
killall ueventd

aplay /oem/duer/appresources/startup.wav &

#wpa_supplicant -B -i wlan0 -c /data/cfg/wpa_supplicant.conf
#sleep 3
#dhcpcd &

# start dueros
/oem/dueros_service.sh start

if [ $dueros_debug -eq 0 ]; then
/oem/watch_dueros_service.sh &
fi
