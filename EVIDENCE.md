# ChordReader implementation and acceptance ledger

This branch replaces the application architecture from accepted master
2179c276d88d91ba01642dde1a6c80a65103962f. It does not merge the retained Kotlin
branch. The original sources/resources remain available for comparison.

## Executed host evidence

`make -f Makefile.idric test assets` passes on Ubuntu24.04 x86_64. The typed
Idriç music/chart/reader/dictionary core passes 366 checks. The separately
executing Lua musical implementation matches 1,049 live Idriç rows for both
canonical printing and enharmonic dictionary lookup. Application
tests compare Unicode-framed library bytes with live Idriç output and verify
restart, source preservation, multiple songs/setlists, original guitar/ukulele
dictionaries, custom fingerings, fractional scrolling, pause, and legacy input.

The retained checked ANF proves the full parser passed the compiler front end.
The DEX backend then rejects binders, constructors, effects or further calls
beyond its implemented binder-free leaf inlining. The native ARM Text export
is rejected by its source ABI boundary. Neither refusal is disguised as an
Android execution result. Raw diagnostics are under `evidence/chordreader/`.

## Immutable inputs

| Input | Revision or digest |
| --- | --- |
| Maintained compiler base | 0e8cfdd1106ebdeffd01b6c519880ea3afc7dc35 |
| Unicode subtraction compiler source | 28c5755d37fb868f1b9c2f5d8fab1ce2b2ada663; same source tree as local built 7accb208e94269e3d66873fcd61b0d63dfeaa51b |
| DEX backend with application improvements and interfaces | c13a6a223a24c211d090d2c88a395c134ed8d469 |
| Android-NDK adapter/packager | 84a4b44d4c87295f4c7479634552b1f6e3baa6d8 |
| Native ARM starting head | ac981d6a9a61e75ad913768f74353829d0cab2e1 |
| Native ARM compiler API repair | 11a2262cdb222b6632a91168c26ef3a96c65ec6d |
| Signing registry | d7402b34bbdd0c17bbc92bf3b7ea936f761b6a06 |
| Stable public test key source | isomorphismes/wegert 89dcfb840cec1a66ee04c7f7404954cbd6c09839 |
| Lua5.4.8 archive SHA256 | 4f18ddae154e793e46eeab727c59ef1c0c0c2b744e7b94219710d76f530629ae |
| Native compiler | NDK29.0.14206865; ARM32 API19 link stubs from NDK25.2.9519653 |
| Independent DEX oracle | baksmali/smali3.0.10, SHA256 pins in maintained backend Makefile |

## Feature and runtime ledger

| Operation | Typed Idriç host core | Candidate Android execution owner | Evidence/check |
| --- | --- | --- | --- |
| Written notes, qualities, degrees, slash bass | Implemented | Lua contingency | 1,049 comparisons |
| Unicode canonical printing and source positions | Implemented | Lua; accidental aliases call checked DEX | Host assertions; DEX independently decoded |
| Pitch-class up/down | Implemented | Checked Idriç DEX through ART | All 33 actual ART assertions pass on API29 |
| Written intervals, key context, capo | Implemented | Lua; pitch motion checked by required DEX operations | Core/context/restart tests |
| Lyrics and whitespace preservation/highlighting | Implemented | Lua spans and Android TextView | Actual Unicode/CRLF import, display and storage pass |
| Guitar/ukulele/custom diagrams | Typed dictionary loader | Lua lookup and C Android Canvas | Original assets and restart tested on host |
| Songs, editing, reopen, settings | Typed state and persistence | Lua and C private storage | Byte comparison; two actual process restarts pass; UI preference assertion |
| Setlists and legacy .txt/.pl | Implemented | Lua | Actual multiple songs and legacy setlist order/repetitions pass |
| Scrolling, speed, pause/resume | Typed state | Lua timers plus C platform clock/scroll | Fractional/pause host tests |
| Search and HTTPS importing | Explicit platform boundary | Browser search intent; C HTTPS plus Lua extraction | Implemented; live service/Android pending |
| File import/export and sharing | Legacy formats | Android content/text intents, document picker and share sheet | Real .pl export bytes verified; executable document-result/import assertions |
| Original translations/resources/license | Preserved | Icons/about/translations/license assets retained; new controls currently English | Source/assets retained; translated UI parity incomplete |
| Full parser/state on Android in Idriç | Checked source exists | Blocked; explicitly C+Lua contingency | Actual DEX and ARM diagnostics |

## Package, platform and physical boundaries

The development package is org.isomorphisms.chordreader.dev, version1001,
label ChordReader Dev. It leaves the original package and data separate.
The finished ARM development APKs are signed with certificate SHA256
de9b1d47c5a65e6d46a204b79dd9ee566b9d3c9832ba81ebc4213d3392e92ff9.
The maintained packager verifies identity, native ABI, declared DEX bytes,
alignment and finished signature; receipts accompany the artifacts.

ARM32 links against API19; ARM64 targets API21. This does not prove API19
runtime behavior. The API29 software emulator and the Android14 MIRO A1/C67
are separate acceptance targets. No physical MIRO device is attached to this
host. The x86_64/API29 candidate installed and launched. Ordinary Android Views
render after returning NativeActivity's surface/input ownership to the framework.
An incoming Unicode chart reached the editable form without corruption; real
Save, upward/downward transposition, negative wrap, repeated intent delivery,
legacy setlists and process-restart persistence passed the checked
AndroidAcceptance.idric driver. The independent ART oracle executes the genuine
checked DEX against 24 pitch steps, four invalid inputs and five Unicode/alias
cases. The oracle is a separate handwritten test runner, never a replacement
for the compiler-produced candidate DEX.

The document picker needs the actual provider display name for legacy .pl
recognition. Setlist exports use application/octet-stream so DocumentsUI does
not append .txt. Acceptance waits for the result callback/app resume before
reading bytes; document creation alone is not write completion. Long song
titles receive equal-width wrapping buttons so no later action is clipped.
The expanded CI driver also exercises file callbacks, both diagram dictionaries
and a persistent text-size change. Each run writes its own emulator receipt
with the actual APK digest and Android fingerprint.

The development app is usable as a songbook; it is not claimed as full Idriç
Android execution. See FEATURE-INVENTORY.md for old presentation/preferences
not ported. Live third-party website extraction, API19 runtime, and physical
MIRO behavior remain separate qualification limits.

## History, CI and remaining acceptance

PR4 (retained head4c256620a2a48728c4c63a3311a682b08d84e458) is closed and
unmerged. PR5 merged into that branch, not master. Its tests/corrections are
comparison material, not accepted Kotlin architecture. The recording-based
Therapy investigation remains separate; no recording-backed correction is
claimed here.

The replacement workflow triggers on implementation-branch pushes, PRs to
master and manual dispatch. It builds checked source, both ARM APKs and the
x86_64 emulator APK with pinned dependencies and the central signer gate, then
executes the installed Android acceptance driver. A separate successful
--check -Werror step precedes host code generation; an intentionally invalid
Int32/Text source must fail the actual compiler negative control.
Source presence alone does not resolve Issue6. The first PR-head run
39975872797 executed the compiler bootstrap, 366 core checks, 1,049 comparisons
and application-state tests, then failed because compiler API objects and the
backend launcher used different Chez versions. CHEZ is now pinned explicitly
to the same bootstrapped10.4.1 runtime. The subsequent actual automatic run
39979360841 at head055cf23bfe36a09d1b0420118debcc42d652136b passed all host,
backend, signed ARM packaging and central signer steps. The expanded workflow
adds mandatory ART/UI/document/persistence execution. A later head must earn
its own result; the earlier green run is not reused as its acceptance.
The old Gradle-only workflow is retired with the architectural replacement.
Current exact-head logs, artifact IDs and acceptance receipts are attached to
the replacement PR and its automatic workflow run before merge.
