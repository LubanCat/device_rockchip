#!/bin/sh

sleep 3

while true;do
    pid=`ps aux | grep duer_linux | grep -v grep | busybox awk '{print \$1}'`
    if [ "$pid" = "" ];then
        echo "duer_linux died, restart it."
        /oem/dueros_service.sh restart
    fi
    sleep 2
done
