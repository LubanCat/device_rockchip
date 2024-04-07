#!/bin/bash -e

# The AMP RTT needs scons support
if [ "$RK_AMP_RTT_TARGET" ] && ! scons -v >/dev/null; then
	echo -e "\e[35m"
	echo "Your scons is missing"
	echo "Please install it:"
	echo "sudo apt-get install scons"
	echo -e "\e[0m"
	exit 1
fi
