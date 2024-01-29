#! /bin/sh


ln -sf /oem/eq_drc_player.bin /data/eq_drc_player.bin
ln -sf /oem/eq_drc_recorder.bin /data/eq_drc_recorder.bin
ln -sf /oem/wozai-48k2ch.pcm /data/wozai-48k2ch.pcm
ln -sf /oem/SmileySans-Oblique.ttf /data/SmileySans-Oblique.ttf

export player_weight=100
export rt_level_det_up=400
export rt_level_det_hold=400
export rt_level_det_down=400
export mic_weight=65
export audiosink_weight=35
export bt_weight=35
export max_mic_adc_volume=20
export ai_period=128
export ao_period=128
export play_start_threshold=1
export ai_buf=1
export ai_eqdrc_bypass=1
rkpartybox
