#!/bin/sh
#
#

case "$1" in
  start)
	echo "Starting $0..."

	# start audio preProcess
	ln -s /oem/baidu_spil_rk3308/* /data/ -f
	cd /data
	mkdir -p local/ipc
	./setup.sh
	./alsa_audio_main_service 6mic_loopback &

	# start dueros
	ln -snf /oem/duer /data/duer
#	mkdir -p /data/duer && cd /data/duer
#	ln -s /usr/duer_linux . -f
#	ln -s /usr/lib . -f
#	ln -s /usr/appresources . -f
#	ln -s /oem/duer/* . -f
	./duer_linux &
	;;
  stop)
	echo "Stop $0..."
	killall alsa_audio_main_service
	killall duer_linux
	;;
  restart|reload)
	killall alsa_audio_main_service
	killall duer_linux
	cd /data && ./alsa_audio_main_service 6mic_loopback &
	cd /data/duer && ./duer_linux &
	;;
  *)
	echo "Usage: $0 {start|stop|restart}"
	exit 1
esac

exit $?
