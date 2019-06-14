#!/bin/bash

USR_LIB_DIR=/usr/lib
TOOLS_DIR=./build

if [ -d "$TOOLS_DIR" ]; then
    cp $TOOLS_DIR/* /tmp/
    chmod 777 /tmp/rknn_mobilenet
    chmod 777 /tmp/npu_transfer_proxy
    sudo cp -dpR $TOOLS_DIR/lib64/ $USR_LIB_DIR
fi
