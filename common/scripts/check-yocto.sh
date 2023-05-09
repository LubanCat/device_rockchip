#!/bin/bash -e

if ! ping google.com -c 1 -W 1 &>/dev/null; then
	echo -e "\e[35mYour network is not able to access google.com\e[0m"
	echo -e "\e[35mPlease setup a VPN to bypass the GFW.\e[0m"
	exit 1
fi

TEMP=$(mktemp -d)
{
	mkdir -p $TEMP/sensitive &&
		echo "secret" >$TEMP/sensitive/file &&
		git init $TEMP/malicious &&
		rm -fr $TEMP/malicious/.git/objects &&
		ln -s "$TEMP/sensitive" $TEMP/malicious/.git/objects &&
		git clone --local $TEMP/malicious $TEMP/clone && exit 0
} &>/dev/null

echo -e "\e[35mYour git is too new for local clone: \e[0m"
echo -e "\e[35mhttps://www.cve.org/CVERecord?id=CVE-2022-39253\e[0m"
echo "Please downgrade it:"
echo "git clone https://github.com/git/git.git --depth 1 -b v2.38.0"
echo "cd git"
echo "make prefix=/usr/local/ install -j8"
exit 1
