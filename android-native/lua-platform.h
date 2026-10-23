/* SPDX-License-Identifier: GPL-3.0-or-later
 * Lua exposes no locale-changing API in this application. Stored numeric
 * fields use the fixed C decimal separator on all supported Android APIs.
 * localeconv itself is unavailable on Android API 19.
 */
#define lua_getlocaledecpoint() ('.')
