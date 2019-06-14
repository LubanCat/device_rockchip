#!/bin/bash

set -e

SCRIPT_DIR=$(dirname $(realpath $BASH_SOURCE))
TOP_DIR=$(realpath $SCRIPT_DIR/../../../../..)
cd $TOP_DIR

source $TOP_DIR/device/rockchip/.BoardConfig.mk
TOOLS_OUT_DIR=$TOP_DIR/device/rockchip/rk1808/rk1808_compute_stick_tool/rknputools/build/
LIB_OUT_DIR=$TOOLS_OUT_DIR/lib64

RKNPUTOOLS_DIR=$TOP_DIR/external/RKNPUTools
RKNN_API_DIR=$RKNPUTOOLS_DIR/rknn-api/$RK_RKNN_API_PLT
RKNN_SDK_DIR=$RKNN_API_DIR/rknn_api_sdk
RKNN_MOBILENET=$RKNN_SDK_DIR/build/rknn_mobilenet
NPU_TRANSFER_PROXY=$RKNPUTOOLS_DIR/npu_transfer_proxy/$RK_NPU_TRANSFER_PROXY_ARCH/npu_transfer_proxy

if [ -d "$TOOLS_OUT_DIR" ]; then
    rm -rf $TOOLS_OUT_DIR
fi
mkdir -p $LIB_OUT_DIR

# Require buildroot host tools to do image packing.
if [ ! -d "$TARGET_OUTPUT_DIR" ]; then
    echo "Source buildroot/build/envsetup.sh"
    source $TOP_DIR/buildroot/build/envsetup.sh $RK_CFG_BUILDROOT
fi

if [ -d $RKNN_SDK_DIR ]; then
    echo -n "compile rknn api sdk..."
    cd $RKNN_SDK_DIR
    if [ -d $RKNN_SDK_DIR/build ]; then
        rm -rf build
    fi
    mkdir build; cd build; cmake ..; make

    if [ -f $RKNN_MOBILENET ]
    then
        echo -n "copy rknn_mobilenet..."
        cp $RKNN_MOBILENET $TOOLS_OUT_DIR/rknn_mobilenet
        echo "done."
    else
        echo "warning: $RKNN_MOBILENET not found!"
    fi
fi

if [ -f $NPU_TRANSFER_PROXY ]
then
    echo -n "copy npu_transfer_proxy..."
    cp $NPU_TRANSFER_PROXY $TOOLS_OUT_DIR/npu_transfer_proxy
    echo "done."
else
    echo "warning: $NPU_TRANSFER_PROXY not found!"
fi

if [ -d $RKNN_API_DIR ]
then
    echo -n "copy libs and resource..."
    cp $RKNN_API_DIR/tmp/* $TOOLS_OUT_DIR/
    cp $RKNN_API_DIR/rknn_api_sdk/rknn_api/lib64/* $LIB_OUT_DIR/
    cp $RKNN_API_DIR/rknn_api_sdk/3rdparty/opencv/lib64/* $LIB_OUT_DIR/
    echo "done."
else
    echo -e "\e[31m error: $RKNN_API_DIR not found! \e[0m"
fi
