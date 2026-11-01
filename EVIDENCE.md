# ChordReader implementation and acceptance ledger

Sections before "Completion campaign" retain the accepted `86dc5406` fallback
and earlier checkpoints. Their Lua ownership, version1001 and compiler refusals
are historical, not claims about the managed candidate. The completion section
defines the managed candidate and revision-bound checkpoints. The PR summary
and per-run receipts identify the latest exact-head qualification.

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
| Search and HTTPS importing | Explicit platform boundary | Explicit Android ACTION_SEARCH to IB (no generic external-browser fallback); IB/ICU Android receiver currently missing; existing C HTTPS chart import unchanged | Host query/UTF-8 escaping and extraction tests; live service/Android pending |
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
The native text boundaries reject embedded NUL before C-string transport can
truncate input. A typed Idriç Buffer supplies a real six-byte malformed document
to the same provider path as the positive import. The refusal must preserve
all saved song sources and remain visible after lifecycle resume. Host state
tests cover message ordering. Acceptance stages an immutable per-run driver,
APK and DEX bundle and removes any previous mutable receipt before execution.

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


## Physical MIRO C67 report and external-search integration (2026-10-24)

The user confirms the exact ARM64 candidate from successful workflow
`39996056494` installed via Shizuku with `/data/local/tmp` staging and
**launched** on the physical MIRO C67. This is user-reported installation and
visible launch only, not independent digest/signing or full behavior acceptance.
The same user observed that Search web opened an external browser (DDG).

On this branch the search button now hands **unescaped** terms to an explicit
Android `ACTION_SEARCH` intent scoped to the provisional IB package
`org.isomorphisms.ib.prepaint` with SearchManager's `query` extra.
No generic `ACTION_VIEW` or Startpage/DDG URL remains on the new path.
If an IB SEARCH receiver is not installed, ChordReader displays an error
without opening another browser. A failed activity start is not an ICU fetch.

The **IB-owned** Google URL construction and `IFS=+`/UTF-8 tests are under
`isomorphisms/ib` PR #163. Actual IB search receipt, ICU fetch, Arena source
admission, view and physical navigation **remain NOT_VERIFIED** because the
checked IB/ICU Android receiver and reader integration are unfinished.
The newly edited native APK needs its **own** exact-head build, signing,
replacement-install and physical acceptance; the October 23 APK does not
include this change.

## TAB_P10 IB integration — 2026-11-01

The native SEARCH handoff now uses a fresh startActivityForResult request
(4104), while preserving ACTION_SEARCH, the explicit IB package, and original
unescaped query text. Android supplies Activity.getCallingPackage to IB from
this framework relationship; a referrer extra is not an identity credential.
The existing document callback accepts only 4101/4102, so this result cannot
alter song import/export state. No external browser fallback is introduced.
Package org.isomorphisms.chordreader.dev, version1001, existing signer and
user data are unchanged. This is a narrow SDK boundary change, not a new
application implementation or a replacement of the checked Idriç core.

Exact prior head 88e5f4378ce7c5c8846dd29f0d043fb47f30ffb7 passed the maintained
host/ART/UI/package/signing workflow in run 40126424123, job 120968736438.
That does not qualify this new for-result handoff. A fresh build, independent
IB caller controls and actual Google response/result navigation are pending.

Active hardware is now SVITOO TAB_P10. MIRO A1/C67 are damaged and unavailable;
the historical C67 report above remains installation/launch evidence only.
No authenticated tablet endpoint, fresh capability inventory or installed
signer observation is available. Physical replacement, SEARCH and data
retention are BLOCKED / NOT_RUN. The IB-owned maintained checked reader is
reviewable in isomorphisms/ib #167, “Integrate the checked native reader for
TAB_P10 on the merged DEX backend” (https://github.com/isomorphisms/ib/pull/167);
its exact 0592dd8e installed navigation profile passes independently on API
29/34 in ai-ci run 41292339244. Changed SEARCH source requires new evidence.
# Completion campaign — 2026-11-01

The November baseline is application head
`86dc5406fdceb593fa5062d4e67312e5a15b75fc`, accepted by runs
[41293909008](https://github.com/dilapidated-shed/tablature/actions/runs/41293909008)
and [41293904880](https://github.com/dilapidated-shed/tablature/actions/runs/41293904880).
That evidence remains scoped to its source and C+Lua runtime ownership.

Probe `b62c3b604f966bab8838c685a7b45505cc895eae` failed in
[41317096789](https://github.com/dilapidated-shed/tablature/actions/runs/41317096789)
at Unicode subtraction in Music.idric with frontend `740bbf2`. Its trailing
undefined-main message is not independently diagnosed. No DEX parser rejection
was reached. The original refusal and workflow remain in history.

The existing Unicode-subtraction PR now includes the checked compiler-driver
error-exit repair at `e7e03fdc896d3740c735c603b5fed792e6172d83`; the canonical
android-NDK DEX probe is pinned to that combined frontend. The unchanged parser
was requalified in
[41330040829](https://github.com/dilapidated-shed/tablature/actions/runs/41330040829).
It completed successfully: the unchanged parser emits a113300-byte DEX and
baksmali independently decodes it. Its SHA-256 is
`6aca097b707865cfd32a48f3a4a90039c0ea584a49f89d8f51f52486ff14ac9e`.
The trailing undefined-main diagnostic disappears with the syntax repair.
`evidence/chordreader/managed-parser-20261101.tsv` binds the exact inputs and
retained archive. ART and application execution were NOT_RUN in this probe;
it does not qualify the richer completion candidate.

At key-declaration checkpoint `0234bbfc659cf7269408c4f76a79b043fa6af859`,
[41330547712](https://github.com/dilapidated-shed/tablature/actions/runs/41330547712)
passes378 host checks, all1049 retained music comparisons,2142 declared-key
comparisons and application-state framing/restart tests. Its ARM native builds
also complete. Packaging correctly refuses versionCode1001 in the manifest
when1002 is requested. The completion source synchronizes manifest and build
version1002. Its own signed ARM32/ARM64 packaging and central signer gates pass
at `50046f7336123392790c6f0082cbc066b23312e2` in run41338214188.

The present change adds declared major/minor keys, explicitly distinct from
pitch classes and chart spelling. Key.idric derives degree spellings from the
tonic's letter and the mode's intervals. It refuses uniform mode conversion.
Reader and contingency persistence retain both declarations in optional `T`
records while reading old files. Existing `K` intervals remain supported;
inconsistent declarations refuse without overwriting the library. Explicit
chromatic chart spellings are not respelled from a key guess.

ManagedCore calls the actual Music parser, Chart recognizer and
renderer, Key contract and Reader transitions/framing. The APK's music.lua is
now a transport-only adapter; the old musical contingency remains an unbundled
host regression reference. The JNI export is required, with no retry through
Lua semantics. Runtime claims remain bound to the exact tested source and APK.
The compiler pin advances to the already qualified android-NDK
`6e1c9619a96f28494ad891a32a06edfb72f3e25b`, retaining the separate historical
fuego-ironworks encoder for callback compatibility. Managed DEX generation must
be byte-identical on repeat and independently decoded; the retained 33 ART
checks are extended by seven direct parser/chart/key/fingering checks. The installed
process must log actual managed parsing, spans, rendering, custom validation
and state calls. Ordinary UI coverage also exercises auto-scroll/pause, speed,
declared minor keys, capo, saved custom fingerings and actual viewport recovery.
Native scroll restoration waits for Android layout and records getScrollY
readback; stored position alone is not its viewport acceptance oracle.

The combined frontend's literal Unicode subtraction and independent Idris
compatibility fixtures execute and match their unchanged expected output in
[41332766597](https://github.com/dilapidated-shed/tablature/actions/runs/41332766597).
The following driver-error control stopped at a missing explicit network package
in its command line. The corrected command names both matching packages and
executes the deliberate rejecting generator at head2051c4f8 in run41336558642:
nonzero exit, exact diagnostic and no output executable all pass. The earlier
failure was a harness dependency error, not a managed musical runtime rejection.
Existing 366 checks and 1,049 comparisons remain; new key tests and 2,142 live
Idriç/Lua key comparisons are added. API29 and API34 each run the installed
application harness and retain separate staged receipts. Version code advances
to 1002; package and public test signer are unchanged.

### Executed managed application checkpoints

At `2051c4f8abcd29125dec236e66a328b9a70c2ad2`,
[41336558642](https://github.com/dilapidated-shed/tablature/actions/runs/41336558642)
passes 387 checked host cases, all 1,049 retained music comparisons, all 2,142
declared-key comparisons, deterministic managed DEX generation, independent
decoding, actual Dictionary preprocessing and all three native ABI builds.
Packaging stops at the canonical packager's new verified-Grease requirement.
The workflow now builds its exact maintained Grease source through the pinned
Cat Food bootstrap; it does not substitute a shell for the Grease packager.

At `50046f7336123392790c6f0082cbc066b23312e2`,
[41338214188](https://github.com/dilapidated-shed/tablature/actions/runs/41338214188)
also passes signed ARM32/ARM64/x86_64 packaging, central signer checks, all
40 direct ART assertions, and the unchanged observer's rejection of the real
compiled Music.transpose_note mutation. The managed DEX is SHA256
`abc2767bcabafa78da57036ed4b5f1a90450c7556474cd476cb03369cebc2515`;
the compiled mutant is
`cdac973a57fd259cc6e492e8f4ef72260484069f5e8f8bd1dcfb58b266b39444`.
Artifact13096326807 has archive SHA256
`8e2942ffd8db5aea3841578ad1e64715f06cfa7f459c6f672d64fac4a588f97d`.
Unicode import and upward/downward transposition execute in the installed app.
That run then fails requesting accessibility idle during continuous scrolling;
the later UI behavior is not accepted by this checkpoint.

At `533071db37087135c628d4675f5d18c2616cb189`,
[41339020449](https://github.com/dilapidated-shed/tablature/actions/runs/41339020449)
actually installs the checksum-pinned accepted version1001 APK, creates a song
and preferences in it, replaces it with version1002 using install -r, verifies
the unchanged private library bytes and reopens source, selection, interval
and settings. Those upgrade checks pass before the same scrolling observation
fails. The source now keeps pause/speed/navigation controls outside the moving
chart and observes the pause action without demanding accessibility idle during
motion. Subsequent per-run receipts own acceptance of that repair and the rest
of the installed UI; earlier failures remain preserved.

At `990b1f7e2d8058dbd82233752b4159c3c303b1c5`,
[41339356948](https://github.com/dilapidated-shed/tablature/actions/runs/41339356948)
passes actual auto-scroll advancement, pause, speed changes and stored-position
recovery. The native viewport readback after restart fails separately. The
following repair waits for both parent/content layout, clamps to the real
content range, retries unsuccessful scroll application and gives the reader
root initial touch focus so Android does not reveal the selectable chart child
in place of the saved viewport. The harness also backgrounds the restored app
and checks the position read from the actual native View on suspend. This source
repair requires its own per-run execution; stored bytes alone never qualify it.

At `2ae6b3b7b077c9422acee1ec00c11d3d52c4f234`,
[41341591349](https://github.com/dilapidated-shed/tablature/actions/runs/41341591349)
waits for a fresh actual application View before querying restoration. Native
readback reports desired52/actual52; background/resume reads the same actual
position. Both pass, as do real major/minor key controls, key restart, capo,
ordered repeated setlists, candidate replacement/installed-byte identity and
exact .pl document export. Re-import then fails the preserved count assertion:
the checked save operation replaced the existing identically named setlist.
New imports now choose an unused name in Reader.idric, retaining the existing
list and both repeated-song orders. The original failing import assertion remains unchanged; host
controls additionally exercise the actual managed transition, occupied copy
names and refusal of unusable blank names. Later receipts qualify this repair.

Completion also exposes explicit song/setlist deletion with cancel/confirm
controls. Those mutations execute in checked Reader state. Existing libraries
may have identically named setlists; edits/removals now select the actual
occurrence in the submitted ordered library and preserve the other occurrence,
its song order and every unrelated chart. No persistence format migration or
silent renaming of old lists is introduced. The Android harness creates real
duplicates in the accepted version1001 package and verifies data-preserving
replacement and an edit of only the selected second list. Host and installed
controls qualify removal, cancellation and repeated-reference cleanup. Actual
pass claims remain attached to the source-specific workflow receipts.

Independent exact-APK observation is maintained in
[isomorphisms/ai-ci PR #334 — Independently qualify ChordReader managed music from signed APK assets on ART](https://github.com/isomorphisms/ai-ci/pull/334).
Its nineteen independent literal assertions execute the DEX extracted from the
signed APK on API29/34; the same oracle must reject the compiled musical mutant
with the exact exit and diagnostic. Its receipts remain separate from producer
UI and physical acceptance.

The bounded written-note contract is documented in
[walnut-burgundy/tymoczko PR #5 — Define the bounded written-note and key-spelling contract for ChordReader](https://github.com/walnut-burgundy/tymoczko/pull/5).
Music/Key remain the one executable application spelling model. No automatic
harmonic inference, general OPTIC completion or recording-derived correction
is claimed. Unknown function retains explicit source spelling.

Physical target is SVITOO TAB_P10, Android15. No authenticated device endpoint
or current package/signer inventory is available in this workspace:
`PHYSICAL_ACCEPTANCE_BLOCKED`. Historical MIRO results do not satisfy it.

