#!/bin/bash -e

SCRIPTS_DIR="$(dirname "$(realpath "$BASH_SOURCE")")"
DEVICE_DIR="$(realpath "$SCRIPTS_DIR/../../")"
SDK_DIR="$(realpath "$DEVICE_DIR/../../")"
CHIPS_DIR="$DEVICE_DIR/.chips"

choose_chip()
{
	CHIP_ARRAY=( $(ls "$CHIPS_DIR") )
	CHIP_ARRAY_LEN=${#CHIP_ARRAY[@]}
	echo "Pick a chip:"
	echo ""

	echo ${CHIP_ARRAY[@]} | xargs -n 1 | sed "=" | sed "N;s/\n/. /"

	local INDEX
	read -p "Which would you like? [1]: " INDEX
	INDEX=$((${INDEX:-1} - 1))
	CHIP="${CHIP_ARRAY[$INDEX]}"
}

CHIP=$1
if [ -z "$CHIP" -o ! -e "$CHIPS_DIR/$CHIP" ]; then
	choose_chip
	[ "$CHIP" ] || exit 1
fi

[ -d "$SDK_DIR/docs/Socs" ] || exit 0

echo "Releasing docs for $CHIP"

cd "$SDK_DIR/docs/Socs"

COMMIT_MSG=$(mktemp)
cat << EOF > $COMMIT_MSG
Release $CHIP - $(date +%Y-%m-%d)

Based on:
$(git log -1 --format="%h %s")
EOF

git add -f .
git stash

git branch -D $CHIP &>/dev/null || true
git checkout --orphan $CHIP
git reset

SOC_DIR=$(echo $CHIP | tr '[:lower:]' '[:upper:]')

ls | grep -v "$SOC_DIR" | xargs rm -rf || true
git add .
git commit -s -F $COMMIT_MSG
