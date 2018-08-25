#!/bin/bash

mkdir /tmp/loopbacktest
rm /tmp/loopbacktest/$1_$2.wav
arecord -D $1 -c $2 -r 16000 -d 10000  --period-size 1024 --buffer-size 65536 -f S16_LE /tmp/loopbacktest/$1_$2.wav&    
for((i=1;i<=10;i++));  
do
j=$(expr $i % 9 + 1);   
echo $j;
aplay ./r.wav -d $j

done  
killall arecord 
