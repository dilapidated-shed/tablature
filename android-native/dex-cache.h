/* SPDX-License-Identifier: GPL-3.0-or-later
 * Checked Idriç DEX cache admission. Shared by Android and host regression.
 */
#ifndef CHORDREADER_DEX_CACHE_H
#define CHORDREADER_DEX_CACHE_H

#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

/* Reuse only an exact regular, read-only byte copy of the packaged DEX.
 * Never follow a symlink or treat a length/mode match as byte authority. */
static int cached_idric_dex_matches(const char *path, const char *bytes, size_t length) {
    int descriptor = open(path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
    if (descriptor < 0) return 0;
    struct stat metadata;
    int matches = !fstat(descriptor, &metadata) && S_ISREG(metadata.st_mode) &&
        (metadata.st_mode & 0777) == 0400 && metadata.st_size >= 0 &&
        (uint64_t)metadata.st_size == (uint64_t)length;
    char chunk[8192];
    size_t position = 0;
    while (matches && position < length) {
        size_t remaining = length - position;
        size_t count = remaining < sizeof chunk ? remaining : sizeof chunk;
        ssize_t received = read(descriptor, chunk, count);
        if (received < 0 && errno == EINTR) continue;
        if (received <= 0 || memcmp(chunk, bytes + position, (size_t)received)) {
            matches = 0;
            break;
        }
        position += (size_t)received;
    }
    if (close(descriptor)) matches = 0;
    return matches;
}

#endif
