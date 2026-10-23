/* SPDX-License-Identifier: GPL-3.0-or-later
 * Android platform adapter; ordinary C is deliberately confined to this ABI.
 */
#include "platform.h"
#include <android/asset_manager.h>
#include <android/log.h>
#include <android/looper.h>
#include <android/native_activity.h>
#include <errno.h>
#include <fcntl.h>
#include <jni.h>
#include <pthread.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/timerfd.h>
#include <unistd.h>

struct Platform {
    ANativeActivity *activity;
    jobject title_entry, body_entry, scroll_view, listener;
    jclass idric_class;
    jmethodID pitch_up, pitch_down, accidental_symbol;
    unsigned core_calls[3];
    char *pending_export;
    size_t pending_export_size;
    void *reader;
    int timer, mailbox[2];
    ALooper *looper;
    atomic_int references;
    pthread_mutex_t lifetime;
    int alive;
    struct Platform *next;
};
typedef struct {
    Platform *platform;
    JavaVM *vm;
    char *url, *text, *problem;
} FetchRequest;
static Platform *activities;

static void report(JNIEnv *env, const char *operation) {
    if ((*env)->ExceptionCheck(env)) {
        __android_log_print(ANDROID_LOG_ERROR, "ChordReader", "PLATFORM_FAIL %s", operation);
        (*env)->ExceptionDescribe(env);
        (*env)->ExceptionClear(env);
    }
}
static jmethodID method(JNIEnv *env, jobject object, const char *name, const char *signature) {
    jclass type = (*env)->GetObjectClass(env, object);
    jmethodID result = (*env)->GetMethodID(env, type, name, signature);
    (*env)->DeleteLocalRef(env, type);
    return result;
}

/* JNI's NewStringUTF uses modified UTF-8. Decode ordinary UTF-8 explicitly so
 * supplementary music symbols and emoji survive the Android text boundary. */
static jstring android_text(JNIEnv *env, const char *text) {
    size_t length = strlen(text);
    jchar *units = malloc((length + 1) * sizeof *units);
    if (!units) return NULL;
    size_t output = 0;
    for (size_t index = 0; index < length;) {
        unsigned char first = (unsigned char)text[index++];
        uint32_t scalar = first;
        unsigned continuation = 0;
        uint32_t minimum = 0;
        if (first < 0x80) { }
        else if (first >= 0xc2 && first <= 0xdf) { scalar = first & 31; continuation = 1; minimum = 0x80; }
        else if (first >= 0xe0 && first <= 0xef) { scalar = first & 15; continuation = 2; minimum = 0x800; }
        else if (first >= 0xf0 && first <= 0xf4) { scalar = first & 7; continuation = 3; minimum = 0x10000; }
        else { scalar = 0xfffd; }
        unsigned consumed = 0;
        while (consumed < continuation && index < length &&
               ((unsigned char)text[index] & 0xc0) == 0x80) {
            scalar = (scalar << 6) | ((unsigned char)text[index++] & 63);
            ++consumed;
        }
        if (consumed != continuation || scalar < minimum || scalar > 0x10ffff ||
            (scalar >= 0xd800 && scalar <= 0xdfff)) scalar = 0xfffd;
        if (scalar < 0x10000) units[output++] = (jchar)scalar;
        else {
            scalar -= 0x10000;
            units[output++] = (jchar)(0xd800 + (scalar >> 10));
            units[output++] = (jchar)(0xdc00 + (scalar & 1023));
        }
    }
    jstring result = (*env)->NewString(env, units, (jsize)output);
    free(units);
    return result;
}
static char *native_text(JNIEnv *env, jstring text) {
    if (!text) return strdup("");
    jsize length = (*env)->GetStringLength(env, text);
    const jchar *units = (*env)->GetStringChars(env, text, NULL);
    if (!units) return NULL;
    char *result = malloc((size_t)length * 3 + 1);
    if (!result) { (*env)->ReleaseStringChars(env, text, units); return NULL; }
    size_t output = 0;
    for (jsize index = 0; index < length; ++index) {
        uint32_t scalar = units[index];
        if (!scalar) {
            free(result); (*env)->ReleaseStringChars(env, text, units); errno = EILSEQ; return NULL;
        }
        if (scalar >= 0xd800 && scalar <= 0xdbff && index + 1 < length &&
            units[index + 1] >= 0xdc00 && units[index + 1] <= 0xdfff)
            scalar = 0x10000 + ((scalar - 0xd800) << 10) + units[++index] - 0xdc00;
        else if (scalar >= 0xd800 && scalar <= 0xdfff) scalar = 0xfffd;
        if (scalar < 0x80) result[output++] = (char)scalar;
        else if (scalar < 0x800) {
            result[output++] = (char)(0xc0 | (scalar >> 6));
            result[output++] = (char)(0x80 | (scalar & 63));
        } else if (scalar < 0x10000) {
            result[output++] = (char)(0xe0 | (scalar >> 12));
            result[output++] = (char)(0x80 | ((scalar >> 6) & 63));
            result[output++] = (char)(0x80 | (scalar & 63));
        } else {
            result[output++] = (char)(0xf0 | (scalar >> 18));
            result[output++] = (char)(0x80 | ((scalar >> 12) & 63));
            result[output++] = (char)(0x80 | ((scalar >> 6) & 63));
            result[output++] = (char)(0x80 | (scalar & 63));
        }
    }
    result[output] = 0;
    (*env)->ReleaseStringChars(env, text, units);
    return result;
}
static jobject view(Platform *platform, const char *name) {
    JNIEnv *env = platform->activity->env;
    jclass type = (*env)->FindClass(env, name);
    jobject result = (*env)->NewObject(env, type,
        (*env)->GetMethodID(env, type, "<init>", "(Landroid/content/Context;)V"),
        platform->activity->clazz);
    (*env)->DeleteLocalRef(env, type);
    return result;
}
static void set_text(JNIEnv *env, jobject object, const char *text) {
    jstring value = android_text(env, text ? text : "");
    (*env)->CallVoidMethod(env, object, method(env, object, "setText", "(Ljava/lang/CharSequence;)V"), value);
    (*env)->DeleteLocalRef(env, value);
}
static char *entry_text(JNIEnv *env, jobject object) {
    if (!object) return strdup("");
    jobject editable = (*env)->CallObjectMethod(env, object,
        method(env, object, "getText", "()Landroid/text/Editable;"));
    jstring text = (*env)->CallObjectMethod(env, editable,
        method(env, editable, "toString", "()Ljava/lang/String;"));
    char *result = native_text(env, text);
    (*env)->DeleteLocalRef(env, text);
    (*env)->DeleteLocalRef(env, editable);
    return result;
}
static void add(JNIEnv *env, jobject parent, jobject child, int width, int height) {
    jclass type = (*env)->FindClass(env, "android/widget/LinearLayout$LayoutParams");
    jobject parameters = (*env)->NewObject(env, type,
        (*env)->GetMethodID(env, type, "<init>", "(II)V"), width, height);
    (*env)->CallVoidMethod(env, parent,
        method(env, parent, "addView", "(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V"), child, parameters);
    (*env)->DeleteLocalRef(env, parameters);
    (*env)->DeleteLocalRef(env, type);
}
static void keep(JNIEnv *env, jobject *slot, jobject value) {
    if (*slot) (*env)->DeleteGlobalRef(env, *slot);
    *slot = value ? (*env)->NewGlobalRef(env, value) : NULL;
}

static void add_equal_button(JNIEnv *env, jobject row, jobject button) {
    jclass type = (*env)->FindClass(env, "android/widget/LinearLayout$LayoutParams");
    jobject parameters = (*env)->NewObject(env, type,
        (*env)->GetMethodID(env, type, "<init>", "(IIF)V"), 0, -2, (jfloat)1);
    (*env)->CallVoidMethod(env, row,
        method(env, row, "addView", "(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V"), button, parameters);
    (*env)->DeleteLocalRef(env, parameters);
    (*env)->DeleteLocalRef(env, type);
}

/* The provider supplies already selected absolute fret positions. This
 * renderer makes no chord, spelling, instrument or fingering decisions. */
static jobject diagram_image(Platform *platform, const UiScreen *screen) {
    JNIEnv *env = platform->activity->env;
    if (!screen->frets || screen->string_count < 2 || screen->string_count > 12) return NULL;
    jclass bitmap_type = (*env)->FindClass(env, "android/graphics/Bitmap");
    jclass config_type = (*env)->FindClass(env, "android/graphics/Bitmap$Config");
    jobject config = (*env)->GetStaticObjectField(env, config_type,
        (*env)->GetStaticFieldID(env, config_type, "ARGB_8888", "Landroid/graphics/Bitmap$Config;"));
    jobject bitmap = (*env)->CallStaticObjectMethod(env, bitmap_type,
        (*env)->GetStaticMethodID(env, bitmap_type, "createBitmap", "(IILandroid/graphics/Bitmap$Config;)Landroid/graphics/Bitmap;"),
        320, 230, config);
    jclass canvas_type = (*env)->FindClass(env, "android/graphics/Canvas");
    jobject canvas = (*env)->NewObject(env, canvas_type,
        (*env)->GetMethodID(env, canvas_type, "<init>", "(Landroid/graphics/Bitmap;)V"), bitmap);
    jclass paint_type = (*env)->FindClass(env, "android/graphics/Paint");
    jobject paint = (*env)->NewObject(env, paint_type, (*env)->GetMethodID(env, paint_type, "<init>", "(I)V"), 1);
    (*env)->CallVoidMethod(env, canvas, method(env, canvas, "drawColor", "(I)V"), (jint)0xfffafafa);
    (*env)->CallVoidMethod(env, paint, method(env, paint, "setColor", "(I)V"), (jint)0xff183456);
    (*env)->CallVoidMethod(env, paint, method(env, paint, "setStrokeWidth", "(F)V"), 2.0f);
    (*env)->CallVoidMethod(env, paint, method(env, paint, "setTextSize", "(F)V"), 20.0f);
    jmethodID line = method(env, canvas, "drawLine", "(FFFFLandroid/graphics/Paint;)V");
    jmethodID circle = method(env, canvas, "drawCircle", "(FFFLandroid/graphics/Paint;)V");
    jmethodID label = method(env, canvas, "drawText", "(Ljava/lang/String;FFLandroid/graphics/Paint;)V");
    for (size_t string = 0; string < screen->string_count; ++string) {
        float x = 45.0f + (float)string * 230.0f / (float)(screen->string_count - 1);
        (*env)->CallVoidMethod(env, canvas, line, x, 45.0f, x, 195.0f, paint);
        int fret = screen->frets[string];
        if (fret > 0) {
            float y = 45.0f + ((float)(fret - screen->base_fret) + 0.5f) * 30.0f;
            if (y >= 45 && y <= 195) (*env)->CallVoidMethod(env, canvas, circle, x, y, 9.0f, paint);
        } else {
            jstring symbol = android_text(env, fret < 0 ? "×" : "○");
            (*env)->CallVoidMethod(env, canvas, label, symbol, x - 7.0f, 30.0f, paint);
            (*env)->DeleteLocalRef(env, symbol);
        }
    }
    for (int fret = 0; fret <= 5; ++fret) {
        float y = 45.0f + (float)fret * 30.0f;
        (*env)->CallVoidMethod(env, canvas, line, 45.0f, y, 275.0f, y, paint);
    }
    char number[32]; snprintf(number, sizeof number, "%d", screen->base_fret);
    (*env)->CallVoidMethod(env, canvas, label, android_text(env, number), 12.0f, 66.0f, paint);
    jobject image = view(platform, "android/widget/ImageView");
    (*env)->CallVoidMethod(env, image, method(env, image, "setImageBitmap", "(Landroid/graphics/Bitmap;)V"), bitmap);
    return image;
}

void platform_present(Platform *platform, const UiScreen *screen) {
    JNIEnv *env = platform->activity->env;
    (*env)->PushLocalFrame(env, 64);
    keep(env, &platform->title_entry, NULL);
    keep(env, &platform->body_entry, NULL);
    keep(env, &platform->scroll_view, NULL);
    jobject root = view(platform, "android/widget/LinearLayout");
    (*env)->CallVoidMethod(env, root, method(env, root, "setOrientation", "(I)V"), 1);
    (*env)->CallVoidMethod(env, root, method(env, root, "setPadding", "(IIII)V"), 12, 10, 12, 10);
    (*env)->CallVoidMethod(env, root, method(env, root, "setFitsSystemWindows", "(Z)V"), JNI_TRUE);
    jobject heading = view(platform, "android/widget/TextView");
    set_text(env, heading, screen->title);
    (*env)->CallVoidMethod(env, heading, method(env, heading, "setTextSize", "(F)V"), 22.0f);
    add(env, root, heading, -1, -2);
    if (screen->notice && *screen->notice) {
        jobject notice = view(platform, "android/widget/TextView");
        set_text(env, notice, screen->notice);
        add(env, root, notice, -1, -2);
    }
    jobject scroll = view(platform, "android/widget/ScrollView");
    jobject content = view(platform, "android/widget/LinearLayout");
    (*env)->CallVoidMethod(env, content, method(env, content, "setOrientation", "(I)V"), 1);
    jobject row = NULL;
    for (size_t index = 0; index < screen->action_count; ++index) {
        if (index % 3 == 0) {
            row = view(platform, "android/widget/LinearLayout");
            add(env, content, row, -1, -2);
            (*env)->DeleteLocalRef(env, row);
            row = (*env)->CallObjectMethod(env, content,
                method(env, content, "getChildAt", "(I)Landroid/view/View;"),
                (*env)->CallIntMethod(env, content, method(env, content, "getChildCount", "()I")) - 1);
        }
        jobject button = view(platform, "android/widget/Button");
        set_text(env, button, screen->actions[index].label);
        jstring tag = android_text(env, screen->actions[index].identifier);
        (*env)->CallVoidMethod(env, button, method(env, button, "setContentDescription",
            "(Ljava/lang/CharSequence;)V"), tag);
        (*env)->CallVoidMethod(env, button, method(env, button, "setTag", "(Ljava/lang/Object;)V"), tag);
        (*env)->CallVoidMethod(env, button, method(env, button, "setOnClickListener",
            "(Landroid/view/View$OnClickListener;)V"), platform->listener);
        add_equal_button(env, row, button);
        (*env)->DeleteLocalRef(env, tag);
        (*env)->DeleteLocalRef(env, button);
        if (index % 3 == 2 || index + 1 == screen->action_count) (*env)->DeleteLocalRef(env, row);
    }
    if (screen->editable) {
        jobject title = view(platform, "android/widget/EditText");
        set_text(env, title, screen->edit_title);
        (*env)->CallVoidMethod(env, title, method(env, title, "setSingleLine", "(Z)V"), JNI_TRUE);
        add(env, content, title, -1, -2);
        keep(env, &platform->title_entry, title);
    }
    if (screen->frets) {
        jobject diagram = diagram_image(platform, screen);
        if (diagram) add(env, content, diagram, -1, 230);
    }
    jobject body = view(platform, screen->editable ? "android/widget/EditText" : "android/widget/TextView");
    set_text(env, body, screen->body);
    (*env)->CallVoidMethod(env, body, method(env, body, "setTextSize", "(F)V"), (jfloat)screen->text_size);
    jclass typeface_type = (*env)->FindClass(env, "android/graphics/Typeface");
    jobject monospace = (*env)->GetStaticObjectField(env, typeface_type,
        (*env)->GetStaticFieldID(env, typeface_type, "MONOSPACE", "Landroid/graphics/Typeface;"));
    (*env)->CallVoidMethod(env, body, method(env, body, "setTypeface", "(Landroid/graphics/Typeface;)V"), monospace);
    if (screen->editable) keep(env, &platform->body_entry, body);
    else {
        (*env)->CallVoidMethod(env, body, method(env, body, "setTextIsSelectable", "(Z)V"), JNI_TRUE);
        if (screen->span_count) {
            jclass span_type = (*env)->FindClass(env, "android/text/SpannableString");
            jstring source = android_text(env, screen->body);
            jobject styled = (*env)->NewObject(env, span_type,
                (*env)->GetMethodID(env, span_type, "<init>", "(Ljava/lang/CharSequence;)V"), source);
            jclass colour_type = (*env)->FindClass(env, "android/text/style/ForegroundColorSpan");
            for (size_t index = 0; index < screen->span_count; ++index) {
                jobject colour = (*env)->NewObject(env, colour_type,
                    (*env)->GetMethodID(env, colour_type, "<init>", "(I)V"), (jint)0xff1559aa);
                (*env)->CallVoidMethod(env, styled, method(env, styled, "setSpan", "(Ljava/lang/Object;III)V"),
                    colour, screen->spans[index].beginning, screen->spans[index].ending, 33);
                (*env)->DeleteLocalRef(env, colour);
            }
            (*env)->CallVoidMethod(env, body, method(env, body, "setText", "(Ljava/lang/CharSequence;)V"), styled);
        }
    }
    add(env, content, body, -1, -2);
    (*env)->CallVoidMethod(env, scroll, method(env, scroll, "addView", "(Landroid/view/View;)V"), content);
    add(env, root, scroll, -1, -1);
    keep(env, &platform->scroll_view, scroll);
    (*env)->CallVoidMethod(env, platform->activity->clazz,
        method(env, platform->activity->clazz, "setContentView", "(Landroid/view/View;)V"), root);
    report(env, "present platform Views");
    (*env)->PopLocalFrame(env, NULL);
}

void platform_scroll(Platform *platform, int position) {
    if (!platform->scroll_view) return;
    JNIEnv *env = platform->activity->env;
    (*env)->CallVoidMethod(env, platform->scroll_view,
        method(env, platform->scroll_view, "scrollTo", "(II)V"), 0, position);
    report(env, "scroll");
}
int platform_scroll_position(Platform *platform) {
    if (!platform->scroll_view) return 0;
    JNIEnv *env = platform->activity->env;
    return (*env)->CallIntMethod(env, platform->scroll_view,
        method(env, platform->scroll_view, "getScrollY", "()I"));
}
static void clicked(JNIEnv *env, jobject listener, jobject button) {
    (void)listener;
    jobject context = (*env)->CallObjectMethod(env, button,
        method(env, button, "getContext", "()Landroid/content/Context;"));
    Platform *platform = activities;
    while (platform && !(*env)->IsSameObject(env, context, platform->activity->clazz)) platform = platform->next;
    (*env)->DeleteLocalRef(env, context);
    if (!platform || !platform->reader) return;
    jstring tag = (*env)->CallObjectMethod(env, button, method(env, button, "getTag", "()Ljava/lang/Object;"));
    char *identifier = native_text(env, tag);
    char *title = entry_text(env, platform->title_entry);
    char *body = entry_text(env, platform->body_entry);
    if (identifier && title && body) reader_event(platform->reader, identifier, title, body);
    free(identifier); free(title); free(body);
    (*env)->DeleteLocalRef(env, tag);
    report(env, "native click callback");
}

char *platform_asset(Platform *platform, const char *name, size_t *size) {
    AAsset *asset = AAssetManager_open(platform->activity->assetManager, name, AASSET_MODE_BUFFER);
    if (!asset) return NULL;
    off_t length = AAsset_getLength(asset);
    char *result = length < 0 ? NULL : malloc((size_t)length + 1);
    if (result) {
        int received = AAsset_read(asset, result, (size_t)length);
        if (received != length) { free(result); result = NULL; }
        else { result[length] = 0; if (size) *size = (size_t)length; }
    }
    AAsset_close(asset);
    return result;
}
static char *private_path(Platform *platform, const char *name) {
    if (!*name || strchr(name, '/') || strchr(name, '\\') || strstr(name, "..")) return NULL;
    char *result = NULL;
    if (asprintf(&result, "%s/%s", platform->activity->internalDataPath, name) < 0) return NULL;
    return result;
}
int platform_load_idric(Platform *platform) {
    size_t length = 0;
    char *bytes = platform_asset(platform, "chordreader-pitch.dex", &length);
    if (!bytes || length < 112 || memcmp(bytes, "dex\n035", 7)) { free(bytes); return 0; }
    char *path = private_path(platform, "idric-core.dex");
    char *temporary = private_path(platform, "idric-core.XXXXXX");
    char *optimized = private_path(platform, "idric-optimized");
    if (!path || !temporary || !optimized) { free(bytes); free(path); free(temporary); free(optimized); return 0; }
    int descriptor = mkstemp(temporary);
    /* Android 14 requires dynamic code files to be read-only when loaded.
     * Set that mode on the already-open descriptor before writing the bytes. */
    int passed = descriptor >= 0 && !fchmod(descriptor, 0400);
    size_t written = 0;
    while (passed && written < length) {
        ssize_t amount = write(descriptor, bytes + written, length - written);
        if (amount < 0 && errno == EINTR) continue;
        if (amount <= 0) passed = 0; else written += (size_t)amount;
    }
    if (descriptor >= 0) { if (fsync(descriptor)) passed = 0; if (close(descriptor)) passed = 0; }
    if (passed && rename(temporary, path)) passed = 0;
    if (!passed) unlink(temporary);
    free(temporary); free(bytes);
    if (mkdir(optimized, 0700) && errno != EEXIST) passed = 0;
    JNIEnv *env = platform->activity->env;
    (*env)->PushLocalFrame(env, 16);
    if (passed) {
        jobject parent = (*env)->CallObjectMethod(env, platform->activity->clazz,
            method(env, platform->activity->clazz, "getClassLoader", "()Ljava/lang/ClassLoader;"));
        jclass loader_type = (*env)->FindClass(env, "dalvik/system/DexClassLoader");
        jobject loader = (*env)->NewObject(env, loader_type,
            (*env)->GetMethodID(env, loader_type, "<init>",
              "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/ClassLoader;)V"),
            android_text(env, path), android_text(env, optimized), NULL, parent);
        jclass generated = NULL;
        if (loader && !(*env)->ExceptionCheck(env)) generated = (*env)->CallObjectMethod(env, loader,
            method(env, loader, "loadClass", "(Ljava/lang/String;)Ljava/lang/Class;"), android_text(env, "Idric.Generated"));
        if (generated && !(*env)->ExceptionCheck(env)) {
            platform->pitch_up = (*env)->GetStaticMethodID(env, generated, "pitch_up", "(I)I");
            platform->pitch_down = (*env)->GetStaticMethodID(env, generated, "pitch_down", "(I)I");
            platform->accidental_symbol = (*env)->GetStaticMethodID(env, generated, "accidental_symbol", "(Ljava/lang/String;)Ljava/lang/String;");
            if (!(*env)->ExceptionCheck(env) && platform->pitch_up && platform->pitch_down && platform->accidental_symbol)
                platform->idric_class = (*env)->NewGlobalRef(env, generated);
        }
    }
    report(env, "load checked Idriç DEX operations");
    (*env)->PopLocalFrame(env, NULL);
    free(path); free(optimized);
    return platform->idric_class != NULL;
}
int platform_pitch_step(Platform *platform, int pitch, int direction) {
    if (!platform->idric_class) return -1;
    JNIEnv *env = platform->activity->env;
    int index = direction > 0 ? 0 : 1;
    int result = (*env)->CallStaticIntMethod(env, platform->idric_class,
        direction > 0 ? platform->pitch_up : platform->pitch_down, pitch);
    if ((*env)->ExceptionCheck(env)) { report(env, "execute Idriç pitch step"); return -1; }
    if (!platform->core_calls[index]++) __android_log_print(ANDROID_LOG_INFO, "ChordReader",
        "IDRIC_CORE_EXECUTED operation=%s", direction > 0 ? "pitch_up" : "pitch_down");
    return result;
}
char *platform_accidental_symbol(Platform *platform, const char *source) {
    if (!platform->idric_class) return NULL;
    JNIEnv *env = platform->activity->env;
    jstring input = android_text(env, source);
    jstring output = (*env)->CallStaticObjectMethod(env, platform->idric_class, platform->accidental_symbol, input);
    char *result = NULL;
    if (!(*env)->ExceptionCheck(env)) result = native_text(env, output);
    report(env, "execute Idriç accidental normalisation");
    (*env)->DeleteLocalRef(env, input);
    if (output) (*env)->DeleteLocalRef(env, output);
    if (result && !platform->core_calls[2]++) __android_log_print(ANDROID_LOG_INFO, "ChordReader",
        "IDRIC_CORE_EXECUTED operation=accidental_symbol");
    return result;
}
char *platform_read(Platform *platform, const char *name) {
    errno = 0;
    char *path = private_path(platform, name);
    if (!path) { errno = EINVAL; return NULL; }
    FILE *file = fopen(path, "rb"); free(path);
    if (!file) return NULL;
    if (fseek(file, 0, SEEK_END)) { int problem = errno ? errno : EIO; fclose(file); errno = problem; return NULL; }
    long size = ftell(file);
    if (size < 0 || fseek(file, 0, SEEK_SET)) { int problem = errno ? errno : EIO; fclose(file); errno = problem; return NULL; }
    char *result = malloc((size_t)size + 1);
    if (result && fread(result, 1, (size_t)size, file) == (size_t)size) {
        if (memchr(result, 0, (size_t)size)) { free(result); result = NULL; errno = EILSEQ; }
        else result[size] = 0;
    }
    else { free(result); result = NULL; }
    int problem = result ? 0 : (errno ? errno : EIO);
    fclose(file);
    errno = problem;
    return result;
}
int platform_write(Platform *platform, const char *name, const char *text, size_t size) {
    char *path = private_path(platform, name), *temporary = NULL;
    if (!path || asprintf(&temporary, "%s.new", path) < 0) { free(path); return 0; }
    FILE *file = fopen(temporary, "wb");
    int passed = file && fwrite(text, 1, size, file) == size;
    if (file) {
        if (fflush(file) || fsync(fileno(file))) passed = 0;
        if (fclose(file)) passed = 0;
    }
    if (passed && rename(temporary, path)) passed = 0;
    if (!passed) unlink(temporary);
    free(path); free(temporary);
    return passed;
}

static jobject new_intent(JNIEnv *env, const char *action) {
    jclass type = (*env)->FindClass(env, "android/content/Intent");
    jstring name = android_text(env, action);
    jobject intent = (*env)->NewObject(env, type,
        (*env)->GetMethodID(env, type, "<init>", "(Ljava/lang/String;)V"), name);
    (*env)->DeleteLocalRef(env, name); (*env)->DeleteLocalRef(env, type);
    return intent;
}
static int choose_document(Platform *platform, const char *action, const char *title, int request) {
    JNIEnv *env = platform->activity->env;
    (*env)->PushLocalFrame(env, 16);
    jobject intent = new_intent(env, action);
    size_t title_size = title ? strlen(title) : 0;
    const char *mime = request == 4102 ? "text/plain" : "*/*";
    if (request == 4102 && title_size >= 3 && !strcmp(title + title_size - 3, ".pl"))
        mime = "application/octet-stream"; /* DocumentsUI must not append .txt to legacy setlists. */
    (*env)->CallObjectMethod(env, intent, method(env, intent, "setType", "(Ljava/lang/String;)Landroid/content/Intent;"),
        android_text(env, mime));
    (*env)->CallObjectMethod(env, intent, method(env, intent, "addCategory", "(Ljava/lang/String;)Landroid/content/Intent;"),
        android_text(env, "android.intent.category.OPENABLE"));
    if (title) (*env)->CallObjectMethod(env, intent, method(env, intent, "putExtra",
        "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;"),
        android_text(env, "android.intent.extra.TITLE"), android_text(env, title));
    (*env)->CallVoidMethod(env, platform->activity->clazz,
        method(env, platform->activity->clazz, "startActivityForResult", "(Landroid/content/Intent;I)V"), intent, request);
    int passed = !(*env)->ExceptionCheck(env);
    report(env, "open Android document picker");
    (*env)->PopLocalFrame(env, NULL);
    return passed;
}
int platform_choose_file(Platform *platform) {
    return choose_document(platform, "android.intent.action.OPEN_DOCUMENT", NULL, 4101);
}
int platform_export(Platform *platform, const char *title, const char *source, size_t size) {
    if (platform->pending_export || size > INT32_MAX) return 0;
    platform->pending_export = malloc(size + 1);
    if (!platform->pending_export) return 0;
    memcpy(platform->pending_export, source, size); platform->pending_export_size = size;
    if (!platform_write(platform, "pending-export.txt", source, size)) {
        free(platform->pending_export); platform->pending_export = NULL; return 0;
    }
    if (choose_document(platform, "android.intent.action.CREATE_DOCUMENT", title, 4102)) return 1;
    free(platform->pending_export); platform->pending_export = NULL;
    return 0;
}
void platform_share(Platform *platform, const char *title, const char *source) {
    JNIEnv *env = platform->activity->env;
    (*env)->PushLocalFrame(env, 16);
    jobject intent = new_intent(env, "android.intent.action.SEND");
    jstring mime = android_text(env, "text/plain");
    (*env)->CallObjectMethod(env, intent, method(env, intent, "setType", "(Ljava/lang/String;)Landroid/content/Intent;"), mime);
    jstring key = android_text(env, "android.intent.extra.TEXT"), text = android_text(env, source);
    (*env)->CallObjectMethod(env, intent, method(env, intent, "putExtra",
        "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;"), key, text);
    jclass type = (*env)->FindClass(env, "android/content/Intent");
    jobject chooser = (*env)->CallStaticObjectMethod(env, type,
        (*env)->GetStaticMethodID(env, type, "createChooser",
            "(Landroid/content/Intent;Ljava/lang/CharSequence;)Landroid/content/Intent;"), intent, android_text(env, title));
    (*env)->CallVoidMethod(env, platform->activity->clazz,
        method(env, platform->activity->clazz, "startActivity", "(Landroid/content/Intent;)V"), chooser);
    report(env, "share source text");
    (*env)->PopLocalFrame(env, NULL);
}
void platform_browse(Platform *platform, const char *url) {
    JNIEnv *env = platform->activity->env;
    (*env)->PushLocalFrame(env, 16);
    jobject intent = new_intent(env, "android.intent.action.VIEW");
    jclass uri_type = (*env)->FindClass(env, "android/net/Uri");
    jobject uri = (*env)->CallStaticObjectMethod(env, uri_type,
        (*env)->GetStaticMethodID(env, uri_type, "parse", "(Ljava/lang/String;)Landroid/net/Uri;"), android_text(env, url));
    (*env)->CallObjectMethod(env, intent, method(env, intent, "setData", "(Landroid/net/Uri;)Landroid/content/Intent;"), uri);
    (*env)->CallVoidMethod(env, platform->activity->clazz,
        method(env, platform->activity->clazz, "startActivity", "(Landroid/content/Intent;)V"), intent);
    report(env, "open search URL");
    (*env)->PopLocalFrame(env, NULL);
}

static void release_platform(Platform *platform) {
    if (atomic_fetch_sub(&platform->references, 1) == 1) {
        close(platform->mailbox[0]); close(platform->mailbox[1]);
        pthread_mutex_destroy(&platform->lifetime);
        free(platform->pending_export);
        free(platform);
    }
}
static void discard_request(FetchRequest *request) {
    Platform *platform = request->platform;
    free(request->url); free(request->text); free(request->problem); free(request);
    release_platform(platform);
}
static int fetch_finished(int descriptor, int events, void *data) {
    (void)events;
    Platform *platform = data;
    FetchRequest *request;
    while (read(descriptor, &request, sizeof request) == sizeof request) {
        if (platform->reader) reader_event(platform->reader,
            request->problem ? "download_failed" : "downloaded", request->url,
            request->problem ? request->problem : request->text);
        discard_request(request);
    }
    return 1;
}
static char *read_stream(JNIEnv *env, jobject stream) {
    /* Bound one remote import, not the number of songs in a library. */
    const size_t maximum_import_bytes = 16 * 1024 * 1024;
    size_t used = 0, capacity = 8192;
    char *result = malloc(capacity);
    if (!result) return NULL;
    jbyteArray block = (*env)->NewByteArray(env, 8192);
    jmethodID read_method = method(env, stream, "read", "([B)I");
    for (;;) {
        jint received = (*env)->CallIntMethod(env, stream, read_method, block);
        if ((*env)->ExceptionCheck(env)) { free(result); result = NULL; break; }
        if (received < 0) break;
        if (!received) continue;
        if (used + (size_t)received >= maximum_import_bytes) { free(result); result = NULL; break; }
        if (used + (size_t)received + 1 > capacity) {
            capacity = (used + (size_t)received + 1) * 2;
            char *grown = realloc(result, capacity);
            if (!grown) { free(result); result = NULL; break; }
            result = grown;
        }
        (*env)->GetByteArrayRegion(env, block, 0, received, (jbyte *)(result + used));
        used += (size_t)received;
    }
    (*env)->DeleteLocalRef(env, block);
    if (result && memchr(result, 0, used)) { free(result); result = NULL; }
    if (result) result[used] = 0;
    return result;
}
static void *fetch_worker(void *data) {
    FetchRequest *request = data;
    Platform *platform = request->platform;
    JavaVM *vm = request->vm;
    JNIEnv *env = NULL;
    if ((*vm)->AttachCurrentThread(vm, &env, NULL) != JNI_OK) {
        request->problem = strdup("Could not attach the network worker");
    } else {
        (*env)->PushLocalFrame(env, 24);
        jclass url_type = (*env)->FindClass(env, "java/net/URL");
        jobject url = (*env)->NewObject(env, url_type,
            (*env)->GetMethodID(env, url_type, "<init>", "(Ljava/lang/String;)V"), android_text(env, request->url));
        jobject connection = NULL;
        if (url && !(*env)->ExceptionCheck(env)) connection = (*env)->CallObjectMethod(env, url,
            method(env, url, "openConnection", "()Ljava/net/URLConnection;"));
        if (connection && !(*env)->ExceptionCheck(env)) {
            (*env)->CallVoidMethod(env, connection, method(env, connection, "setConnectTimeout", "(I)V"), 12000);
            (*env)->CallVoidMethod(env, connection, method(env, connection, "setReadTimeout", "(I)V"), 12000);
            (*env)->CallVoidMethod(env, connection, method(env, connection, "setRequestProperty",
                "(Ljava/lang/String;Ljava/lang/String;)V"), android_text(env, "User-Agent"),
                android_text(env, "ChordReader/Idric-development"));
            jobject stream = (*env)->CallObjectMethod(env, connection,
                method(env, connection, "getInputStream", "()Ljava/io/InputStream;"));
            if (stream && !(*env)->ExceptionCheck(env)) {
                request->text = read_stream(env, stream);
                if (!(*env)->ExceptionCheck(env)) (*env)->CallVoidMethod(env, stream, method(env, stream, "close", "()V"));
            }
            report(env, "download chord source");
            (*env)->CallVoidMethod(env, connection, method(env, connection, "disconnect", "()V"));
        }
        report(env, "HTTP platform interface");
        if (!request->text) request->problem = strdup("Download failed, timed out, or exceeded 16 MiB");
        (*env)->PopLocalFrame(env, NULL);
        (*vm)->DetachCurrentThread(vm);
    }
    pthread_mutex_lock(&platform->lifetime);
    int delivered = platform->alive &&
        write(platform->mailbox[1], &request, sizeof request) == sizeof request;
    pthread_mutex_unlock(&platform->lifetime);
    if (!delivered) discard_request(request);
    return NULL;
}
int platform_fetch(Platform *platform, const char *url) {
    if (strncmp(url, "https://", 8) || platform->mailbox[0] < 0) return 0;
    FetchRequest *request = calloc(1, sizeof *request);
    if (!request) return 0;
    request->platform = platform; request->vm = platform->activity->vm; request->url = strdup(url);
    if (!request->url) { free(request); return 0; }
    atomic_fetch_add(&platform->references, 1);
    pthread_t worker;
    if (pthread_create(&worker, NULL, fetch_worker, request)) { discard_request(request); return 0; }
    pthread_detach(worker);
    return 1;
}

static int timer_tick(int descriptor, int events, void *data) {
    (void)events;
    Platform *platform = data;
    uint64_t ticks;
    if (read(descriptor, &ticks, sizeof ticks) == sizeof ticks && platform->reader)
        reader_tick(platform->reader, (unsigned)(ticks * 20));
    return 1;
}
static void resume_activity(ANativeActivity *activity) {
    Platform *platform = activity->instance;
    if (platform->reader) reader_event(platform->reader, "resume", "", "");
}
static void pause_activity(ANativeActivity *activity) {
    Platform *platform = activity->instance;
    char *title = entry_text(activity->env, platform->title_entry);
    char *body = entry_text(activity->env, platform->body_entry);
    if (platform->reader) reader_event(platform->reader, "suspend", title ? title : "", body ? body : "");
    free(title); free(body);
}
static void destroy_activity(ANativeActivity *activity) {
    Platform *platform = activity->instance;
    if (platform->reader) { reader_stop(platform->reader); platform->reader = NULL; }
    if (platform->timer >= 0) {
        if (platform->looper) ALooper_removeFd(platform->looper, platform->timer);
        close(platform->timer);
    }
    JNIEnv *env = activity->env;
    keep(env, &platform->title_entry, NULL); keep(env, &platform->body_entry, NULL);
    keep(env, &platform->scroll_view, NULL); keep(env, &platform->listener, NULL);
    if (platform->idric_class) (*env)->DeleteGlobalRef(env, platform->idric_class);
    Platform **link = &activities;
    while (*link && *link != platform) link = &(*link)->next;
    if (*link) *link = platform->next;
    pthread_mutex_lock(&platform->lifetime);
    platform->alive = 0;
    if (platform->mailbox[0] >= 0) {
        ALooper_removeFd(platform->looper, platform->mailbox[0]);
        FetchRequest *request;
        while (read(platform->mailbox[0], &request, sizeof request) == sizeof request) discard_request(request);
    }
    pthread_mutex_unlock(&platform->lifetime);
    release_platform(platform);
}
static char *document_name(JNIEnv *env, jobject resolver, jobject uri) {
    (*env)->PushLocalFrame(env, 16);
    jobjectArray columns = (*env)->NewObjectArray(env, 1, (*env)->FindClass(env, "java/lang/String"), NULL);
    (*env)->SetObjectArrayElement(env, columns, 0, android_text(env, "_display_name"));
    jobject cursor = (*env)->CallObjectMethod(env, resolver, method(env, resolver, "query",
        "(Landroid/net/Uri;[Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;)Landroid/database/Cursor;"),
        uri, columns, NULL, NULL, NULL);
    char *name = NULL;
    if (!(*env)->ExceptionCheck(env) && cursor) {
        jboolean found = (*env)->CallBooleanMethod(env, cursor, method(env, cursor, "moveToFirst", "()Z"));
        if (!(*env)->ExceptionCheck(env) && found) {
            jstring value = (*env)->CallObjectMethod(env, cursor, method(env, cursor, "getString", "(I)Ljava/lang/String;"), 0);
            if (!(*env)->ExceptionCheck(env)) name = native_text(env, value);
        }
        report(env, "read document display name");
        (*env)->CallVoidMethod(env, cursor, method(env, cursor, "close", "()V"));
    }
    report(env, "query document metadata");
    if (!name) {
        jstring segment = (*env)->CallObjectMethod(env, uri, method(env, uri, "getLastPathSegment", "()Ljava/lang/String;"));
        name = native_text(env, segment);
    }
    (*env)->PopLocalFrame(env, NULL);
    return name;
}
static void receive_intent(Platform *platform) {
    if (!platform->reader) return;
    JNIEnv *env = platform->activity->env;
    (*env)->PushLocalFrame(env, 24);
    int attempted = 0, received = 0;
    jobject intent = (*env)->CallObjectMethod(env, platform->activity->clazz,
        method(env, platform->activity->clazz, "getIntent", "()Landroid/content/Intent;"));
    jstring text = (*env)->CallObjectMethod(env, intent, method(env, intent, "getStringExtra",
        "(Ljava/lang/String;)Ljava/lang/String;"), android_text(env, "android.intent.extra.TEXT"));
    if (text) {
        attempted = 1;
        char *source = native_text(env, text);
        jstring supplied_title = (*env)->CallObjectMethod(env, intent, method(env, intent, "getStringExtra",
            "(Ljava/lang/String;)Ljava/lang/String;"), android_text(env, "android.intent.extra.TITLE"));
        char *title = native_text(env, supplied_title);
        if (source) { received = 1; reader_event(platform->reader, "incoming", title && *title ? title : "Imported song", source); }
        free(source); free(title);
    } else {
        jobject uri = (*env)->CallObjectMethod(env, intent, method(env, intent, "getData", "()Landroid/net/Uri;"));
        if (uri) {
            attempted = 1;
            jobject resolver = (*env)->CallObjectMethod(env, platform->activity->clazz,
                method(env, platform->activity->clazz, "getContentResolver", "()Landroid/content/ContentResolver;"));
            jobject stream = (*env)->CallObjectMethod(env, resolver, method(env, resolver, "openInputStream",
                "(Landroid/net/Uri;)Ljava/io/InputStream;"), uri);
            if (stream && !(*env)->ExceptionCheck(env)) {
                char *source = read_stream(env, stream);
                report(env, "read imported document");
                (*env)->CallVoidMethod(env, stream, method(env, stream, "close", "()V"));
                report(env, "close imported document");
                char *name = document_name(env, resolver, uri);
                if (source) { received = 1; reader_event(platform->reader, "incoming", name ? name : "Imported song", source); }
                free(source); free(name);
            }
        }
    }
    report(env, "import shared song or document URI");
    if (attempted && !received) reader_event(platform->reader, "import_failed", "", "");
    (*env)->PopLocalFrame(env, NULL);
}
static Platform *platform_for_activity(JNIEnv *env, jobject activity) {
    for (Platform *platform = activities; platform; platform = platform->next)
        if ((*env)->IsSameObject(env, activity, platform->activity->clazz)) return platform;
    return NULL;
}
static void activity_new_intent(JNIEnv *env, jobject activity, jobject intent) {
    Platform *platform = platform_for_activity(env, activity);
    if (!platform) return;
    jclass parent = (*env)->FindClass(env, "android/app/NativeActivity");
    (*env)->CallNonvirtualVoidMethod(env, activity, parent,
        (*env)->GetMethodID(env, parent, "onNewIntent", "(Landroid/content/Intent;)V"), intent);
    (*env)->DeleteLocalRef(env, parent);
    (*env)->CallVoidMethod(env, activity, method(env, activity, "setIntent", "(Landroid/content/Intent;)V"), intent);
    if (!(*env)->ExceptionCheck(env)) receive_intent(platform);
    report(env, "receive Android intent callback");
}
static void activity_result(JNIEnv *env, jobject activity, jint request, jint result, jobject intent) {
    Platform *platform = platform_for_activity(env, activity);
    if (!platform || (request != 4101 && request != 4102)) return;
    (*env)->PushLocalFrame(env, 24);
    jclass parent = (*env)->FindClass(env, "android/app/NativeActivity");
    (*env)->CallNonvirtualVoidMethod(env, activity, parent,
        (*env)->GetMethodID(env, parent, "onActivityResult", "(IILandroid/content/Intent;)V"), request, result, intent);
    if (request == 4102 && !platform->pending_export) {
        platform->pending_export = platform_read(platform, "pending-export.txt");
        if (platform->pending_export) platform->pending_export_size = strlen(platform->pending_export);
    }
    if (result == -1 && intent) {
        jobject uri = (*env)->CallObjectMethod(env, intent, method(env, intent, "getData", "()Landroid/net/Uri;"));
        if (request == 4101 && uri) {
            (*env)->CallVoidMethod(env, activity, method(env, activity, "setIntent", "(Landroid/content/Intent;)V"), intent);
            receive_intent(platform);
        } else if (request == 4102 && uri && platform->pending_export) {
            jobject resolver = (*env)->CallObjectMethod(env, activity,
                method(env, activity, "getContentResolver", "()Landroid/content/ContentResolver;"));
            jobject stream = (*env)->CallObjectMethod(env, resolver, method(env, resolver, "openOutputStream",
                "(Landroid/net/Uri;)Ljava/io/OutputStream;"), uri);
            if (stream && !(*env)->ExceptionCheck(env)) {
                jbyteArray bytes = (*env)->NewByteArray(env, (jsize)platform->pending_export_size);
                if (bytes) {
                    (*env)->SetByteArrayRegion(env, bytes, 0, (jsize)platform->pending_export_size,
                        (const jbyte *)platform->pending_export);
                    (*env)->CallVoidMethod(env, stream, method(env, stream, "write", "([B)V"), bytes);
                }
                int passed = bytes && !(*env)->ExceptionCheck(env);
                report(env, "write exported document");
                (*env)->CallVoidMethod(env, stream, method(env, stream, "close", "()V"));
                passed = passed && !(*env)->ExceptionCheck(env);
                report(env, "close exported document");
                reader_event(platform->reader, passed ? "exported" : "export_failed", "", "");
            } else {
                report(env, "open export document");
                reader_event(platform->reader, "export_failed", "", "");
            }
        }
    }
    if (request == 4102) {
        free(platform->pending_export); platform->pending_export = NULL;
        char *spool = private_path(platform, "pending-export.txt");
        if (spool) { unlink(spool); free(spool); }
    }
    report(env, "Android document callback");
    (*env)->PopLocalFrame(env, NULL);
}
void ANativeActivity_onCreate(ANativeActivity *activity, void *saved, size_t saved_size) {
    (void)saved; (void)saved_size;
    Platform *platform = calloc(1, sizeof *platform);
    if (!platform) return;
    platform->activity = activity; platform->timer = -1;
    platform->mailbox[0] = -1; platform->mailbox[1] = -1;
    atomic_init(&platform->references, 1);
    platform->alive = 1;
    platform->next = activities; activities = platform;
    activity->instance = platform;
    activity->callbacks->onPause = pause_activity;
    activity->callbacks->onResume = resume_activity;
    activity->callbacks->onDestroy = destroy_activity;
    pthread_mutex_init(&platform->lifetime, NULL);
    JNIEnv *env = activity->env;
    (*env)->PushLocalFrame(env, 16);
    /* NativeActivity takes the surface and input queue before this callback.
     * This application uses ordinary platform Views, so return both to the
     * framework before the window is attached. Otherwise Views neither draw
     * nor receive touch events despite successful application startup. */
    jobject window = (*env)->CallObjectMethod(env, activity->clazz,
        method(env, activity->clazz, "getWindow", "()Landroid/view/Window;"));
    (*env)->CallVoidMethod(env, window, method(env, window, "takeSurface",
        "(Landroid/view/SurfaceHolder$Callback2;)V"), NULL);
    (*env)->CallVoidMethod(env, window, method(env, window, "takeInputQueue",
        "(Landroid/view/InputQueue$Callback;)V"), NULL);
    report(env, "return surface and input to platform Views");
    jclass activity_type = (*env)->GetObjectClass(env, activity->clazz);
    JNINativeMethod document_callbacks[] = {
        { "onActivityResult", "(IILandroid/content/Intent;)V", (void *)activity_result },
        { "onNewIntent", "(Landroid/content/Intent;)V", (void *)activity_new_intent }
    };
    if ((*env)->RegisterNatives(env, activity_type, document_callbacks, 2) != JNI_OK) {
        report(env, "register document and intent callbacks"); (*env)->PopLocalFrame(env, NULL); return;
    }
    jobject loader = (*env)->CallObjectMethod(env, activity->clazz,
        method(env, activity->clazz, "getClassLoader", "()Ljava/lang/ClassLoader;"));
    jclass type = (*env)->CallObjectMethod(env, loader,
        method(env, loader, "loadClass", "(Ljava/lang/String;)Ljava/lang/Class;"),
        android_text(env, "org.isomorphisms.NativeClickListener"));
    if (!type || (*env)->ExceptionCheck(env)) { report(env, "load direct DEX listener"); (*env)->PopLocalFrame(env, NULL); return; }
    JNINativeMethod callback = { "onClick", "(Landroid/view/View;)V", (void *)clicked };
    if ((*env)->RegisterNatives(env, type, &callback, 1) != JNI_OK) {
        report(env, "register native View callback"); (*env)->PopLocalFrame(env, NULL); return;
    }
    jobject listener = (*env)->NewObject(env, type, (*env)->GetMethodID(env, type, "<init>", "()V"));
    keep(env, &platform->listener, listener);
    (*env)->PopLocalFrame(env, NULL);
    platform->reader = reader_start(platform);
    platform->looper = ALooper_forThread();
    if (platform->looper && !pipe2(platform->mailbox, O_NONBLOCK | O_CLOEXEC))
        ALooper_addFd(platform->looper, platform->mailbox[0], ALOOPER_POLL_CALLBACK,
            ALOOPER_EVENT_INPUT, fetch_finished, platform);
    platform->timer = timerfd_create(CLOCK_MONOTONIC, TFD_NONBLOCK | TFD_CLOEXEC);
    if (platform->timer >= 0 && platform->looper) {
        struct itimerspec interval = { .it_interval = {0, 20000000}, .it_value = {0, 20000000} };
        if (!timerfd_settime(platform->timer, 0, &interval, NULL))
            ALooper_addFd(platform->looper, platform->timer, ALOOPER_POLL_CALLBACK,
                ALOOPER_EVENT_INPUT, timer_tick, platform);
    }
    receive_intent(platform);
    __android_log_print(ANDROID_LOG_INFO, "ChordReader", "PLATFORM_CREATED package=org.isomorphisms.chordreader.dev");
}
