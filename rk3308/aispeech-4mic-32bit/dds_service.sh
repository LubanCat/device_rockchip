#!/bin/sh
#
#

case "$1" in
  start)
        echo "Starting $0..."
        cd /oem/dds_client && ./dui dui_cfg.json &
        ;;
  stop)
        echo "Stop $0..."
        killall dui
        ;;
  restart|reload)
        killall dui
        cd /oem/dds_client && ./dui dui_cfg.json &
        ;;
  *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
esac

exit $?
