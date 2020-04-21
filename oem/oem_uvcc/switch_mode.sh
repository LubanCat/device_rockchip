#!/bin/sh
#
if [ $1x = "1"x ];then
  sed -i "s/^\/oem\/aicamera.sh/\#\/oem\/aicamera.sh/g" /oem/RkLunch.sh
  sed -i "s/^\#\/oem\/eptz.sh/\/oem\/eptz.sh/g" /oem/RkLunch.sh

else
  sed -i "s/^\#\/oem\/aicamera.sh/\/oem\/aicamera.sh/g" /oem/RkLunch.sh
  sed -i "s/^\/oem\/eptz.sh/\#\/oem\/eptz.sh/g" /oem/RkLunch.sh

fi
