/* SPDX-License-Identifier: GPL-3.0-or-later
 * Ordinary C at the Lua/Android ABI. Application decisions live in app.lua;
 * the separately qualified Idriç DEX owns the bound operations below.
 */
#include "platform.h"
#include <android/log.h>
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <stdint.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

typedef struct { Platform *platform; lua_State *lua; int application; } Reader;
static Reader *reader(lua_State *lua) { return lua_touserdata(lua, lua_upvalueindex(1)); }
static const char *text_field(lua_State *lua, int table, const char *name, const char *fallback) {
    lua_getfield(lua, table, name);
    const char *value = lua_tostring(lua, -1);
    lua_pop(lua, 1);
    return value ? value : fallback;
}
static int present(lua_State *lua) {
    Reader *instance = reader(lua);
    luaL_checktype(lua, 1, LUA_TTABLE);
    UiScreen screen = {0};
    screen.title = text_field(lua, 1, "title", "ChordReader");
    screen.notice = text_field(lua, 1, "notice", "");
    screen.body = text_field(lua, 1, "body", "");
    screen.edit_title = text_field(lua, 1, "edit_title", "");
    lua_getfield(lua, 1, "editable"); screen.editable = lua_toboolean(lua, -1); lua_pop(lua, 1);
    lua_getfield(lua, 1, "size"); screen.text_size = (int)luaL_optinteger(lua, -1, 20); lua_pop(lua, 1);
    lua_getfield(lua, 1, "actions");
    screen.action_count = lua_rawlen(lua, -1);
    UiAction *actions = calloc(screen.action_count ? screen.action_count : 1, sizeof *actions);
    if (!actions) return luaL_error(lua, "Out of memory for View actions");
    for (size_t index = 0; index < screen.action_count; ++index) {
        lua_rawgeti(lua, -1, (lua_Integer)index + 1);
        actions[index].identifier = text_field(lua, lua_gettop(lua), "id", "");
        actions[index].label = text_field(lua, lua_gettop(lua), "label", "");
        lua_pop(lua, 1);
    }
    screen.actions = actions;
    lua_pop(lua, 1);
    lua_getfield(lua, 1, "spans");
    screen.span_count = lua_istable(lua, -1) ? lua_rawlen(lua, -1) : 0;
    UiSpan *spans = calloc(screen.span_count ? screen.span_count : 1, sizeof *spans);
    if (!spans) { free(actions); return luaL_error(lua, "Out of memory for chord spans"); }
    for (size_t index = 0; index < screen.span_count; ++index) {
        lua_rawgeti(lua, -1, (lua_Integer)index + 1);
        lua_rawgeti(lua, -1, 1); spans[index].beginning = (int)luaL_checkinteger(lua, -1); lua_pop(lua, 1);
        lua_rawgeti(lua, -1, 2); spans[index].ending = (int)luaL_checkinteger(lua, -1); lua_pop(lua, 1);
        lua_pop(lua, 1);
    }
    screen.spans = spans; lua_pop(lua, 1);
    lua_getfield(lua, 1, "frets");
    screen.string_count = lua_istable(lua, -1) ? lua_rawlen(lua, -1) : 0;
    int *frets = screen.string_count ? calloc(screen.string_count, sizeof *frets) : NULL;
    if (screen.string_count && !frets) { free(actions); free(spans); return luaL_error(lua, "Out of memory for diagram"); }
    for (size_t index = 0; index < screen.string_count; ++index) {
        lua_rawgeti(lua, -1, (lua_Integer)index + 1); frets[index] = (int)luaL_checkinteger(lua, -1); lua_pop(lua, 1);
    }
    screen.frets = frets; lua_pop(lua, 1);
    lua_getfield(lua, 1, "base_fret"); screen.base_fret = (int)luaL_optinteger(lua, -1, 1); lua_pop(lua, 1);
    platform_present(instance->platform, &screen);
    free(actions); free(spans); free(frets);
    return 0;
}
static int read_private(lua_State *lua) {
    char *text = platform_read(reader(lua)->platform, luaL_checkstring(lua, 1));
    if (text) { lua_pushstring(lua, text); free(text); }
    else if (errno == ENOENT) lua_pushnil(lua);
    else return luaL_error(lua, "Stored file could not be read; existing bytes are preserved");
    return 1;
}
static int write_private(lua_State *lua) {
    size_t size = 0;
    const char *name = luaL_checkstring(lua, 1), *text = luaL_checklstring(lua, 2, &size);
    lua_pushboolean(lua, platform_write(reader(lua)->platform, name, text, size)); return 1;
}
static int read_asset(lua_State *lua) {
    size_t size = 0;
    char *text = platform_asset(reader(lua)->platform, luaL_checkstring(lua, 1), &size);
    if (text) { lua_pushlstring(lua, text, size); free(text); } else lua_pushnil(lua);
    return 1;
}
static int scroll_to(lua_State *lua) { platform_scroll(reader(lua)->platform, (int)luaL_checkinteger(lua, 1)); return 0; }
static int scroll_position(lua_State *lua) { lua_pushinteger(lua, platform_scroll_position(reader(lua)->platform)); return 1; }
static int share(lua_State *lua) { platform_share(reader(lua)->platform, luaL_checkstring(lua, 1), luaL_checkstring(lua, 2)); return 0; }
static int browse(lua_State *lua) { platform_browse(reader(lua)->platform, luaL_checkstring(lua, 1)); return 0; }
static int fetch(lua_State *lua) { lua_pushboolean(lua, platform_fetch(reader(lua)->platform, luaL_checkstring(lua, 1))); return 1; }
static int pitch_up(lua_State *lua) { lua_pushinteger(lua, platform_pitch_step(reader(lua)->platform, (int)luaL_checkinteger(lua, 1), 1)); return 1; }
static int pitch_down(lua_State *lua) { lua_pushinteger(lua, platform_pitch_step(reader(lua)->platform, (int)luaL_checkinteger(lua, 1), -1)); return 1; }
static int accidental_symbol(lua_State *lua) {
    char *result = platform_accidental_symbol(reader(lua)->platform, luaL_checkstring(lua, 1));
    if (!result) return luaL_error(lua, "Idriç DEX accidental operation failed");
    lua_pushstring(lua, result); free(result); return 1;
}
static int asset_searcher(lua_State *lua) {
    const char *name = luaL_checkstring(lua, 1);
    if (strchr(name, '/') || strchr(name, '.') || strchr(name, '\\')) return luaL_error(lua, "Invalid bundled module name");
    char path[128];
    if (snprintf(path, sizeof path, "%s.lua", name) >= (int)sizeof path) return luaL_error(lua, "Module name too long");
    size_t size = 0; char *source = platform_asset(reader(lua)->platform, path, &size);
    if (!source) { lua_pushfstring(lua, "No bundled module %s", name); return 1; }
    int status = luaL_loadbufferx(lua, source, size, path, "t"); free(source);
    if (status != LUA_OK) return lua_error(lua);
    lua_pushstring(lua, path); return 2;
}
static void bind(lua_State *lua, Reader *instance, const char *name, lua_CFunction function) {
    lua_pushlightuserdata(lua, instance); lua_pushcclosure(lua, function, 1); lua_setfield(lua, -2, name);
}
static void failed(Reader *instance, const char *action) {
    const char *message = lua_tostring(instance->lua, -1);
    __android_log_print(ANDROID_LOG_ERROR, "ChordReader", "LUA_FAIL action=%s reason=%s", action, message ? message : "unknown");
    UiScreen screen = {.title="ChordReader could not complete this action", .body=message ? message : action, .text_size=18};
    platform_present(instance->platform, &screen);
    lua_pop(instance->lua, 1);
}
void *reader_start(Platform *platform) {
    Reader *instance = calloc(1, sizeof *instance);
    if (!instance) return NULL;
    instance->platform = platform; instance->application = LUA_NOREF;
    instance->lua = luaL_newstate();
    if (!instance->lua) { free(instance); return NULL; }
    lua_State *lua = instance->lua;
    /* Platform storage/network operations are explicit capabilities. Do not
     * link the unused Lua file/process libraries (ftello requires API 24). */
    static const luaL_Reg libraries[] = {
        {LUA_GNAME, luaopen_base}, {LUA_LOADLIBNAME, luaopen_package},
        {LUA_COLIBNAME, luaopen_coroutine}, {LUA_TABLIBNAME, luaopen_table},
        {LUA_STRLIBNAME, luaopen_string}, {LUA_MATHLIBNAME, luaopen_math},
        {LUA_UTF8LIBNAME, luaopen_utf8}, {NULL, NULL}
    };
    for (const luaL_Reg *library = libraries; library->func; ++library) {
        luaL_requiref(lua, library->name, library->func, 1); lua_pop(lua, 1);
    }
    const char *removed[] = {"dofile", "loadfile", "load", "os", "io", "debug"};
    for (size_t index = 0; index < sizeof removed / sizeof *removed; ++index) { lua_pushnil(lua); lua_setglobal(lua, removed[index]); }
    lua_getglobal(lua, "package");
    lua_pushliteral(lua, ""); lua_setfield(lua, -2, "path");
    lua_pushliteral(lua, ""); lua_setfield(lua, -2, "cpath");
    lua_newtable(lua);
    lua_pushlightuserdata(lua, instance); lua_pushcclosure(lua, asset_searcher, 1); lua_rawseti(lua, -2, 1);
    lua_setfield(lua, -2, "searchers"); lua_pop(lua, 1);
    if (!platform_load_idric(platform)) {
        lua_pushliteral(lua, "The checked Idriç DEX payload could not be loaded"); failed(instance, "Idriç startup"); return instance;
    }
    lua_getglobal(lua, "require"); lua_pushliteral(lua, "app");
    if (lua_pcall(lua, 1, 1, 0) != LUA_OK) { failed(instance, "load application"); return instance; }
    lua_getfield(lua, -1, "new"); lua_newtable(lua);
    bind(lua, instance, "present", present); bind(lua, instance, "read", read_private);
    bind(lua, instance, "write", write_private); bind(lua, instance, "asset", read_asset);
    bind(lua, instance, "scroll", scroll_to); bind(lua, instance, "scroll_position", scroll_position);
    bind(lua, instance, "share", share); bind(lua, instance, "browse", browse); bind(lua, instance, "fetch", fetch);
    bind(lua, instance, "pitch_up", pitch_up); bind(lua, instance, "pitch_down", pitch_down);
    bind(lua, instance, "accidental_symbol", accidental_symbol);
    if (lua_pcall(lua, 1, 1, 0) != LUA_OK) { failed(instance, "start application"); return instance; }
    instance->application = luaL_ref(lua, LUA_REGISTRYINDEX);
    lua_settop(lua, 0);
    __android_log_print(ANDROID_LOG_INFO, "ChordReader", "APPLICATION_STARTED runtime=C+Lua checked_Idric_DEX=bound");
    return instance;
}
static int application_function(Reader *instance, const char *name) {
    if (instance->application == LUA_NOREF) return 0;
    lua_rawgeti(instance->lua, LUA_REGISTRYINDEX, instance->application);
    lua_getfield(instance->lua, -1, name); lua_remove(instance->lua, -2); return 1;
}
void reader_event(void *opaque, const char *identifier, const char *title, const char *body) {
    Reader *instance = opaque;
    if (!application_function(instance, "event")) return;
    lua_pushstring(instance->lua, identifier); lua_pushstring(instance->lua, title); lua_pushstring(instance->lua, body);
    if (lua_pcall(instance->lua, 3, 0, 0) != LUA_OK) failed(instance, identifier);
    else __android_log_print(ANDROID_LOG_INFO, "ChordReader", "APPLICATION_EVENT %s", identifier);
}
void reader_tick(void *opaque, unsigned elapsed) {
    Reader *instance = opaque;
    if (!application_function(instance, "tick")) return;
    lua_pushinteger(instance->lua, elapsed);
    if (lua_pcall(instance->lua, 1, 0, 0) != LUA_OK) failed(instance, "scroll tick");
}
void reader_stop(void *opaque) {
    Reader *instance = opaque;
    if (application_function(instance, "stop") && lua_pcall(instance->lua, 0, 0, 0) != LUA_OK) failed(instance, "save on stop");
    lua_close(instance->lua); free(instance);
}
