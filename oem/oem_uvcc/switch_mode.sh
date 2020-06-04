#!/bin/sh
#
if [ $1x = "1"x ];then
  sed -i "s/^\#export ENABLE_EPTZ=1/export ENABLE_EPTZ=1/g" /oem/RkLunch.sh

else
  sed -i "s/^export ENABLE_EPTZ=1/\#export ENABLE_EPTZ=1/g" /oem/RkLunch.sh
fi
