#!/bin/bash -e

SITE="${1:-www.baidu.com}"
SITE_NAME="${2:-$SITE}"
EXTRA_MSG="$3"

if [ $(curl -I -s -m 1 -w "%{http_code}" -o /dev/null $SITE) -eq 200 ]; then
	exit 0
fi

echo -e "\e[35m"
echo -e "Your network is not able to access $SITE_NAME!"
echo -e "$EXTRA_MSG"
echo -ne "\e[0m"

if [ -z "$RK_NETWORK_CHECK" ]; then
	echo -ne "\e[35m"
	echo "Will continue in 5 seconds ..."
	for S in $(seq 0 4); do
		echo "$((5 - $S)) ..."
		sleep 1
	done
	echo -e "\e[0m"
else
	echo -ne "\e[35m"
	echo "Unset RK_NETWORK_CHECK in the SDK config to continue..."
	echo -e "\e[0m"
	exit 1
fi
