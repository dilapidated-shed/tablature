# Declared native toolchain boundary

This application selects Android NDK 29.0.14206865 for its ordinary C Android
ABI, foreign Lua 5.4.8 runtime and unmodified shared AI-CI host verifier.
ARM32 links the API19 sysroot from NDK 25.2.9519653 because NDK29 no longer
ships API19 link stubs. ARM64 targets API21 and 16 KiB load alignment.

The evaluated ICK reference is the shared `ick-host/Makefile` pin
fbe86e23d55cfec2000c08e61deea2a407fd7175. No ICK executable or current JNI/Lua
Android qualification receipt was available in this run. This is a missing
qualification statement, not an asserted ICK compiler defect or unsupported
target. The user explicitly authorizes C for unavoidable Android boundaries.
These files have the ordinary C ABI role; no Icky source is rewritten.

The checked Idriç compiler is a separate language stage. Its retained bootstrap,
typechecking and backend receipts are not counted as NDK musical execution.
The accepted historical pitch-only candidate labelled its remaining decisions
C+Lua. The completion candidate compiles Music, Chart, Key and Reader through
the canonical managed DEX backend. EVIDENCE.md records actual managed ART
checkpoints; per-run receipts qualify each exact-source application candidate.

Grease was absent from the original fallback host. The completion workflow now
builds and smoke-tests dilapidated-shed/grease at
f19c94c6df18cddbdc1e81463e5bd689533e3c13, including its pinned source submodule,
through the maintained isomorphisms/catfood bootstrap at
609a9628d5a52860f956bf62e0914a0cd03292ae. ANDROID_GREASE names that executable
for the canonical Grease packager. Existing fixed Make and bootstrap interfaces
remain separate from the application runtime; no alternative shell packager
is introduced.
