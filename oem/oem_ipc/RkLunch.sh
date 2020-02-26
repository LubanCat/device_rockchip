#!/bin/sh
#

dbserver &
storage_manager &
netserver &
mkdir -p /data/video0
mkdir -p /data/video1
mkdir -p /data/photo0
mkdir -p /data/photo1

mediaserver  -c /usr/share/mediaserver/camerax2_audio_capture_nv12_pcm_enc_h264_mp2_muxer_mp4_rtsp_rtmp.conf -d &
