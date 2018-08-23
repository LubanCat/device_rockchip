libbdSPILAudioProc.so
md5: 78b343f4d5f393d119dc88e3c019835c

libbd_audio_vdev.so
md5: f31ade415b132a07eda1ccef039b260a

libbdaudResample.so
md5: 73f66d2c73248bb6778d455206cac7ed

libbd_alsa_audio_client.so
md5: 236132ef695cef50deffe2dde95e4fc8

使用说明：
1. adb push so库和alsa_audio_main_service, setup.sh, config_rk3229_linux_6_2.lst到/data目录
2. 修改权限chmod 777 setup.sh
   chmod 777 alsa_audio_main_service
3. 运行录音程序
	cd /data
   ./alsa_audio_main_service 6mic_loopback &
4. 运行duer_linux或者demo
