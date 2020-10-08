#!/bin/sh
#

export LD_LIBRARY_PATH=/oem/ispserver:$LD_LIBRARY_PATH
echo "ispserver LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
ispserver -no-sync-db &

