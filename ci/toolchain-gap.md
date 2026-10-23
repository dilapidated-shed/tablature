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
All musical decisions outside the executable DEX subset are labelled C+Lua.

Grease was not installed on this host. No new shell launcher was authored.
The fixed Make interfaces, the maintained Android-NDK packager, and an
interactive terminal for emulator/ADB checks were used. This is a task-local
tool availability boundary, not Grease qualification.
