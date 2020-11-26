#!/bin/sh
#
killall -9 aicamera.sh
killall smart_display_service
killall dbserver
killall aiserver
#sleep for aiserver deint over
sleep 1
killall ispserver
killall uvc_app
killall uac_app
echo "All Stop Application ..."
