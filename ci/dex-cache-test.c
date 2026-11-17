/* SPDX-License-Identifier: GPL-3.0-or-later
 * Host regression compiles the SAME DEX-cache predicate as Android.
 */
#define _GNU_SOURCE
#include "../android-native/dex-cache.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    char directory[] = "/tmp/chordreader-idric-cache-XXXXXX";
    assert(mkdtemp(directory));
    char path[sizeof directory + 32], alias[sizeof directory + 32];
    assert(snprintf(path, sizeof path, "%s/idric-core.dex", directory) > 0);
    assert(snprintf(alias, sizeof alias, "%s/link.dex", directory) > 0);
    const char expected[] = "dex\n035\0illustrative-checked-payload";
    const char changed[] = "dex\n035\0illustrative-checked-payloaD";
    const size_t length = sizeof expected;

    assert(!cached_idric_dex_matches(path, expected, length));
    int descriptor = open(path, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0600);
    assert(descriptor >= 0);
    assert(write(descriptor, expected, length) == (ssize_t)length);
    assert(!cached_idric_dex_matches(path, expected, length)); /* writable */
    assert(fchmod(descriptor, 0400) == 0);
    assert(close(descriptor) == 0);
    assert(cached_idric_dex_matches(path, expected, length)); /* cold restart */
    assert(!cached_idric_dex_matches(path, changed, length)); /* same length, wrong bytes */
    assert(!cached_idric_dex_matches(path, expected, length - 1)); /* stale length */
    assert(symlink(path, alias) == 0);
    assert(!cached_idric_dex_matches(alias, expected, length)); /* no symlinks */
    assert(chmod(path, 0600) == 0);
    assert(!cached_idric_dex_matches(path, expected, length)); /* wrong permissions */
    assert(unlink(alias) == 0);
    assert(unlink(path) == 0);
    assert(rmdir(directory) == 0);
    puts("PASS verified read-only Idric DEX cache: miss, hit, byte/mode/length drift, symlink refusal");
    return 0;
}
