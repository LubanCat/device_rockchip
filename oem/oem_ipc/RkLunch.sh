#!/bin/sh
#

check_linker()
{
	[ ! -L "$2" ] && ln -sf $1 $2
}

check_linker /userdata   /oem/www/userdata
check_linker /userdata   /oem/www/userdata
check_linker /media/usb0 /oem/www/usb0
check_linker /mnt/sdcard /oem/www/sdcard

ipc-daemon &

