#!/bin/bash -e

echo "Executing $(basename "$BASH_SOURCE")..."

RK_SCRIPTS_DIR="$(dirname "$(realpath "$BASH_SOURCE")")"

# HACK: Allow host tools, e.g. python2 in yocto building
export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \

# Trigger build.sh's post-rootfs hooks
RK_SESSION=latest "$RK_SCRIPTS_DIR/build.sh" post-rootfs "$1"
