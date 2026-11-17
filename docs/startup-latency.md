# Chord Changes: startup and semitone latency acceptance

This branch addresses source-confirmed redundant startup DEX writes and repeated
library field scanning, and records Android main-thread timing. Neither the
improvement in real startup duration nor the cause of the reported seven-second
+semitone action on the MIRO C67 has been established by source review.

## Phase boundaries

- `DEX_LOAD cache=hit|miss stage_ms=... class_ms=...`: APK DEX extraction,
  exact read-only private-cache verification/replacement, and managed class load.
  The immutable APK asset remains the authority. Read-only mode 0400 is required
  before loading dynamically generated code on Android 14.
- `APPLICATION_STARTUP total_ms=... after_dex_ms=...`: native and Lua startup,
  including loading saved state, initial checked chart work and view construction.
  This **does not measure first visible frame**.
- `IDRIC_REQUEST code=u|v|b|c ... elapsed_ms=...`: checked reader transition,
  durable-state validation, chart render, and chord recognition respectively.
- `PRIVATE_WRITE file=library.txt ... elapsed_ms=...`: native atomic and durable
  library write (including fsync and rename). Original chart bytes are preserved.
- `VIEW_PRESENT elapsed_ms=...`: synchronous JNI view construction and
  `setContentView`, not Android's later layout/draw.
- `EVENT_LATENCY event=up|down ... elapsed_ms=...`: synchronous Lua event
  including the checked work, native save and presentation. It excludes input
  dispatch before the Lua callback and eventual display compositor latency.

Ordinary 20-ms autoscroll (`e`) requests are deliberately not logged unless
they take at least 16 ms, to limit measurement interference.

## Collect on MIRO C67

Use an authorized host ADB or an ADB-shell-equivalent session with logcat
access. Do not clear the app's stored data or uninstall the installed chart
library. Install only a qualified ARM64 development candidate with its
expected signer and package identity.

```sh
adb logcat -c
adb shell am force-stop org.isomorphisms.chordreader.dev
adb shell am start -n org.isomorphisms.chordreader.dev/org.isomorphisms.NativeViewActivity
# Once reader is visible, force-stop and reopen to exercise DEX cache reuse:
adb shell am force-stop org.isomorphisms.chordreader.dev
adb shell am start -n org.isomorphisms.chordreader.dev/org.isomorphisms.NativeViewActivity
# In the reader, press + semitone several times, then - semitone.
adb logcat -d -v threadtime -s ChordReader:I > chordreader-c67-timings.log
```

For the second launch, require `DEX_LOAD cache=hit` with a successful class
load. Distinguish `stage_ms` from `class_ms` and `after_dex_ms`. On
transposition, compare `EVENT_LATENCY` with the nested `u/v/b/c` managed
requests, `PRIVATE_WRITE`, and `VIEW_PRESENT`. Collect more than one trial;
report the exact installed APK/hash and whether the reader restored a long song.
The hosted Android API29 and API34 checks retain interaction latency logs,
but emulator timings do not substitute for physical C67 results.

## Source-level performance changes

The private DEX file is reused only on a full byte-for-byte match to the
packaged asset, regular-file identity and exact read-only mode. Mismatched,
missing, writable, or symlink paths take the existing atomic replacement route.
The checked `read_field` parser now consumes exactly the declared Unicode
scalar count and stops, rather than scanning the entire trailing library for
each short field. The existing checked Idriç ownership of musical operations
and corruption refusals is unchanged.

Remaining possible costs include full-library serialization and validation,
full chart recognition, JNI View rebuilding, synchronous persistence, and
Android layout. Use the phase records to prioritize them; do not attribute
the stall to a particular subsystem without measurements.
