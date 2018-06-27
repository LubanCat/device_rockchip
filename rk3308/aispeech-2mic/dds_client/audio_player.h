#ifndef __AUDIO_PLAYER_H__
#define __AUDIO_PLAYER_H__

#ifdef __cplusplus
extern "C" {
#endif

#define AUDIO_PLAYER_EV_BEGIN    0x01
#define AUDIO_PLAYER_EV_START    0x02
#define AUDIO_PLAYER_EV_END      0x03
#define AUDIO_PLAYER_EV_ERROR    0x04
#define AUDIO_PLAYER_EV_PAUSED   0x05
#define AUDIO_PLAYER_EV_PLAYING  0x06
#define AUDIO_PLAYER_EV_STOPPED  0x07

typedef int (*audio_player_callback)(void *userdata, int ev);
typedef struct audio_player audio_player_t;

audio_player_t *audio_player_new(char *dev, audio_player_callback ccb, void *userdata);
int audio_player_delete(audio_player_t *aplayer);
int audio_player_play(audio_player_t *aplayer, char *path);
int audio_player_pause(audio_player_t *aplayer);
int audio_player_resume(audio_player_t *aplayer);
int audio_player_stop(audio_player_t *aplayer);

int audio_player_get_volume(char *dev, int *l_vol, int *r_vol);
int audio_player_set_volume(char *dev, int l_vol, int r_vol);

int audio_player_set_channel_volume(audio_player_t *aplayer, float multiplier);

#ifdef __cplusplus
}
#endif

#endif
