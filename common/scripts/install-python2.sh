#!/bin/sh

RK_SCRIPTS_DIR="${RK_SCRIPTS_DIR:-$(dirname "$(realpath "$0")")}"

"$RK_SCRIPTS_DIR/install-python.sh" 2.7.18
