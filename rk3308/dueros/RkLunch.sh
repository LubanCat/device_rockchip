# vad
# arecord -D vad -c 8 -r 16000 -f S16_LE -d 1 -t raw /tmp/test.pcm
# rm /tmp/test.pcm
# echo 0x60 0x40ff0040 > /sys/kernel/debug/vad/reg
# echo 0x5c 0x000e2080 > /sys/kernel/debug/vad/reg
# mkdir -p /data/local/ipc

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

aplay /usr/appresources/startup.wav &

#wpa_supplicant -B -i wlan0 -c /data/cfg/wpa_supplicant.conf
#sleep 3
#dhcpcd &

# start dueros
/oem/dueros_service.sh start
