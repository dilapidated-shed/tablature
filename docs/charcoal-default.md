# Charcoal default

Keeps the checked managed music/runtime and existing packager pins. Imports only the shared charcoal tokens/resources. Changes the native launch theme, reader root, fingering canvas and chord foreground. The original Kotlin comparison tree is not part of the native candidate.

Shared presentation source: `isomorphisms/android-NDK@3e682fb1175beef5625dbd2418730220e49fc9bd`.
Package ID, version code, signer and storage formats are unchanged.

This is an implementation candidate. Exact-source signed packaging, API29/API34
functional and visual acceptance, system night mode on/off, launch/rotation
frames and physical MIRO C67 acceptance must be recorded separately. Source
edits and an earlier green run do not satisfy those obligations. No installed
application is replaced by this work.

Packaging also exposed an inherited unreadable launcher PNG at the starting
45f32c2 source: FFmpeg refused it with `chunk too big`, while aapt2 crashed
during resource compilation. Regenerated the 256px PNG directly from the
unchanged branding/chord-changes-icon.svg with Inkscape. SVG SHA256:
72a758986ac92a58a6a4a663b8faaf48e48330ae067b201e14edbffbf97390e0.
New PNG SHA256: a6a224d6036f40901a90f3e8d9d523766393c0c02936d83c6513759c4c31e814.
FFmpeg now decodes it successfully; the two anonymous fretboard shapes and
transition arrow were inspected. This changes encoding, not the approved
vector artwork. Per-file resource diagnostics precede APK packaging and are
retained in CI. All three ABI packages now pass resource compilation and signing.

The 797c5bf run reached real song/setlist deletion and exposed Android's
automatic capitalization of an application-authored setlist label. Its fresh
accessibility tree contained `DELETION ...` instead of the retained `Deletion ...`
spelling. Native buttons now disable this transformation, matching the shared
presentation controls and preserving authored case in chord names as well.
The original case-sensitive interaction test is retained; complete current
API29/API34 acceptance remains pending.
