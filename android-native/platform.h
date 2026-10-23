#ifndef CHORDREADER_PLATFORM_H
#define CHORDREADER_PLATFORM_H

#include <stddef.h>

/* Ordinary C at the Android/JNI ABI boundary. Application state and musical
 * decisions belong to the runtime provider, never to these transport records. */
typedef struct Platform Platform;
typedef struct { const char *identifier, *label; } UiAction;
typedef struct { int beginning, ending; } UiSpan; /* UTF-16 code units */
typedef struct {
    const char *title, *notice, *body, *edit_title;
    int editable, text_size;
    const UiAction *actions;
    size_t action_count;
    const UiSpan *spans;
    size_t span_count;
    const int *frets;
    size_t string_count;
    int base_fret;
} UiScreen;

void platform_present(Platform *, const UiScreen *);
void platform_scroll(Platform *, int);
int platform_scroll_position(Platform *);
void platform_share(Platform *, const char *, const char *);
int platform_export(Platform *, const char *, const char *, size_t);
int platform_choose_file(Platform *);
void platform_browse(Platform *, const char *);
int platform_fetch(Platform *, const char *);
char *platform_read(Platform *, const char *);
int platform_write(Platform *, const char *, const char *, size_t);
char *platform_asset(Platform *, const char *, size_t *);
int platform_load_idric(Platform *);
int platform_pitch_step(Platform *, int, int);
char *platform_accidental_symbol(Platform *, const char *);

/* Provider entry points. A future qualified Idriç implementation consumes the
 * same text/event boundary; a contingency must identify its actual runtime. */
void *reader_start(Platform *);
void reader_event(void *, const char *, const char *, const char *);
void reader_tick(void *, unsigned);
void reader_stop(void *);

#endif
