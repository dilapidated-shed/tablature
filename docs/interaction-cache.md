# Reader interaction cache

The intended result is a responsive reader that retains original chart bytes,
durable saves, and checked Idriç ownership of music, recognition and transitions.
This work addresses redundant calls on the synchronous path identified in
[issue 9](https://github.com/dilapidated-shed/tablature/issues/9). It does not
establish the cause of the physical C67 stalls or close that issue.

## Implementation

`app.lua` remembers whether its current durable library snapshot has passed
checked validation. An identical encoded state can then skip validation and
storage. Startup and externally reloaded snapshots begin unverified; changed
states still validate before writing. Failed validation or writing cannot mark
a new snapshot durable, so later saves retry. The native atomic write path is
unchanged, including its synchronization.

One chart cache per application instance holds the checked rendered text,
checked spans and chord action labels. Its dependencies are the selected song
identifier and exact source, chromatic displacement, capo, written interval
and optional display key. Text size, scroll speed, viewport and navigation
remain live presentation inputs. The cache is installed only after both
rendering and recognition finish successfully. There is no new music engine.

Library serialization and native View construction still occur on this path.
This patch does not move persistence to a worker or remove durable writes for
changed session state. It therefore makes no measured latency claim.

## Executed checks, November 15, 2026

Base: `3a575a24a05ff2744a752d7e9f6baf29a4d087b3`, the head of
[dilapidated-shed/tablature PR #12, “Offer opt-in key-aware chord-root spelling without changing saved charts”](https://github.com/dilapidated-shed/tablature/pull/12).
The interaction-cache change stacks on that head.

The available host runner was `/usr/bin/luatex --luaonly`, embedding Lua 5.3.
It is a supplementary transport check, not the pinned Lua 5.4.8 qualification
runner used by `Makefile.idric` and not ART execution.

- `contingency/latency-regression-test.lua`: PASS against the actual modified
  `app.lua` and packaged `managed-music.lua` adapter, with explicitly simulated
  managed replies and storage. One hundred successive scroll toggles add no
  `v`, `b`, `c`, or write calls after first validation. Changed state, render
  dependencies, viewport, source bytes, failed-write retry, validation/render/
  recognition refusal and corrupt startup/reload controls pass.
- The same test against the unmodified base fails with
  `Read-only toggles must not validate/write`.
- `contingency/latency-cache-controls.lua`: PASS, rejecting eight in-memory
  mutations at their expected assertions: redundant validation, trusting a
  restored snapshot before checking, omitted shift/capo/source/written-interval/
  display-key dependencies, and trusting an external snapshot before checking.
- `git diff --check`: PASS.
- `make -f Makefile.idric test`: BLOCKED at `policy`: the configured NDK
  compiler `/ndk/29.0.14206865/toolchains/llvm/prebuilt/linux-x86_64/bin/clang`
  does not exist. The pinned Idriç compiler and sibling dependency checkouts
  are also unavailable. No generic compiler was substituted.

Both Lua checks are wired into the existing `comparisons` target, which runs
inside the maintained checked-core test workflow. That wiring has not run on
the patched source in GitHub Actions.

## Remaining qualification

Run the maintained `Makefile.idric` test, asset, native, packaging and emulator
stages with the existing pins and signer. Host checks, managed DEX/ART, signed
patched APK, API29/API34 installed acceptance and physical C67 responsiveness
remain unqualified for this patch until its hosted checks execute. No release,
installation or merge is established by the supplementary host tests.

Use the actual imported Alice bytes for physical testing when available; the
synthetic load here contains no transcription of that chart. Capture action
latencies and frame evidence before making a causal or performance claim.
The older proposed native tracing changes are not included: their recovered
patch failed to apply to the actual `platform.c` checkout. That proposal needs
separate reconciliation and compilation rather than being called implemented.

## C67 semitone screenshot follow-up

The user supplied physical C67 screenshots after delivery of the ARM64
candidate. The displayed chords at -1, zero and +1 have the expected semitone
relationship. One screenshot at -1 also contains `Invalid stored reader state`.
The screenshots do not establish action duration or installed-package hashes.
They establish a visible refusal that the previous emulator assertions did not
explicitly exclude, even while checking the chord text.

Source inspection finds that the frontend reads Android's viewport offset
directly into a nonnegative persisted field. A simulated transient offset of
-12 reproduces a refused semitone transition and save. This is a demonstrated
failure path, not proof that it caused the physical screenshot. The frontend
now maps a transient negative offset to document position zero before events,
suspend or scrolling can use it. Checked persistence still rejects negative
positions; it does not silently repair stored data.

The generic decoder message now distinguishes invalid screen, semitone, capo
and viewport fields. Five checked-core controls cover the signed semitone and
each diagnostic. Installed acceptance also checks that -1/-2 transitions really
reach durable storage without a saved-state error, rather than accepting chord
text alone. Those new Idriç and Android checks require a new exact-head run.

Supplementary Lua transport checks pass with negative-offset event/suspend
inputs, and a ninth mutant removing the normalization is rejected. The test
fails before the frontend repair. No physical fix or layout-jump cause is
claimed from this host scenario.
