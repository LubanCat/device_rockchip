#!/bin/bash -e

source "${POST_HELPER:-$(dirname "$(realpath "$0")")/../post-hooks/post-helper}"

if [ "$RK_OWNER" != "root" ] && [ "${USER:-$(id -un)}" = "root" ]; then
	echo "Fixing up owner for $RK_OUTDIR..."
	find "$RK_OUTDIR" -user root -exec chown -ch $RK_OWNER:$RK_OWNER {} \;
fi

# buildroot would fixup owner in its fakeroot script
[ "$POST_OS" != buildroot ] || exit 0

echo "Fixing up owner for $TARGET_DIR..."

if [ "$RK_OWNER" != "root" ]; then
	echo "Fixing up uid=$RK_OWNER($RK_OWNER_UID) to 0(root)..."
	find . -user $RK_OWNER -exec chown -ch 0:0 {} \;
fi

if [ -d home ]; then
	for u in $(ls home/); do
		ID=$(grep "^$u:" etc/passwd | cut -d':' -f3 || true)
		[ "$ID" ] || continue
		echo "Fixing up /home/$u for uid=$ID($u)..."
		chown -ch -R $ID:$ID home/$u
	done
fi
