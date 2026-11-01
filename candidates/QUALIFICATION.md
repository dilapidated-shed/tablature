# ChordReader 2 managed development candidate

Source: e6c84d645ad7086a11ae2735258188a49e444d13, existing [dilapidated-shed/tablature PR #7, “Run ChordReader music, charts and reader state in checked managed Idriç”](https://github.com/dilapidated-shed/tablature/pull/7). This delivery commit contains the unchanged signed producer bytes and receipts. It is not a release or merge.

## Identity

Package org.isomorphisms.chordreader.dev, versionCode1002, versionName0.2-dev, label ChordReader Dev. Public test certificate SHA256 de9b1d47c5a65e6d46a204b79dd9ee566b9d3c9832ba81ebc4213d3392e92ff9. ARM64 is the candidate for SVITOO TAB_P10 Android15. ARM32 remains constructed and signed; API19 runtime and physical ARM execution are not inferred from x86_64 emulator results.

## Execution and ownership

The actual maintained Music parser/formatting/written transposition, Chart recognition/offset/render operations, Key major/minor written-key contract, Reader song/setlist transitions, persistence framing and fractional scrolling arithmetic execute through ManagedCore.application_request as checked Idriç on ART. Native C supplies lifecycle, Views, Canvas, UTF-8/UTF-16 boundary, storage and intents. Lua supplies presentation, editable drafts and transport; the musical reference is unbundled and not a runtime fallback. Original JSON dictionaries are preprocessed by the checked host Dictionary loader into bundled indices; managed code owns lookup spelling and custom-fingering validation. General JSON/Double execution on ART is not claimed.

Original Music.idric SHA256 067c8cfe5e282e6d17846047a18f56bafc153397b7ab95f63df1e3e3e4b47522 and AndroidCore.idric SHA256 c3075881c28a11ff2e876f1eabda232dfdd0d8a16f9136c41598b0216db07480 remain unchanged. Written notes, sounding pitch, written intervals, declared key/mode, display spelling and original source are kept distinct. Unknown harmonic function preserves explicit spelling. A uniform transposition between different modes refuses instead of inventing harmony.

## Exact evidence

| Gate | Exact evidence and result |
| --- | --- |
| Application PR workflow | [41347983217](https://github.com/dilapidated-shed/tablature/actions/runs/41347983217), job 124971814022: PASS |
| Application push workflow | [41347978719](https://github.com/dilapidated-shed/tablature/actions/runs/41347978719), job 124971799878: PASS |
| Original parser / canonical current backend | [41347978741](https://github.com/dilapidated-shed/tablature/actions/runs/41347978741), job 124971799983: unchanged AndroidCore → Music.parse_chord DEX emission and independent decode PASS; isolated probe ART NOT_RUN |
| Checked host regressions | 394 cases including all retained 366; 1049 original live music comparisons and 2142 declared-key comparisons PASS |
| Compiler controls | Unicode-minus positive fixtures, deliberate generator failure with nonzero exit/exact diagnostic/absent executable, and genuine type error PASS |
| Compiler output | Managed DEX generated twice identically; independent decoding PASS; 478,232 bytes, SHA256 66f9dcf41ee7684ce2299187eb9ce9487e43cc850af9fe2e77b3f24bd377722e |
| API29 full application | [Receipt](acceptance/api29.receipt.tsv): 40 direct ART assertions, compiled music mutant REJECTED, installed compiled parsing/state/custom calls PASS, complete UI/persistence/upgrade/removal PASS |
| API34 full application | [Receipt](acceptance/api34.receipt.tsv): same signed x86_64 APK and same gates PASS |
| Independent signed-APK oracle | [ai-ci run 41349486078](https://github.com/isomorphisms/ai-ci/actions/runs/41349486078), observer c1e2d611672998f38495f5a901007d5a081ae047: API29 job 124976372199 and API34 job 124976372318 PASS; 19 literal assertions each; actual compiled mutant exit 93 with exact diagnostic |
| Independent archive/API29 | Artifact 13100956992,599,299 bytes, SHA256 9016c9fbf10b2970e7abdbce22604cc67fcbf89804620ead64c4df381219b28f |
| Independent archive/API34 | Artifact 13100986736,599,298 bytes, SHA256 93d2ec97ec98d2d4262e3eff4840ee19a47e6fc6e8d787cfc8f7ac852f27f93c |
| Selected producer archive | Artifact 13100269370,4,285,589 bytes, SHA256 8bb0f7798d9ba8cdfc7a27d5cbda26d2d3f1b0e9fc35816ac2ae3430c4daee02 |
| Finished packages | Independent apksigner/aapt2 checks for all three ABIs PASS; managed asset and transport-only music.lua identical to the qualified source; native ELF machine/digest rechecked after download |
| Physical tablet | PHYSICAL_ACCEPTANCE_BLOCKED / NOT_RUN |

The [independent input receipt](independent/receipt.tsv), [API29 oracle receipt](independent/api29-receipt.tsv) and [API34 oracle receipt](independent/api34-receipt.tsv) preserve scope. Positive exit 0 and mutant exit 93 are retained separately. The independent oracle DEX SHA256 is b93ebde3b45409c736bf0386f1744770bc7bc3a896f60489a202bf58128b52b3. The compiled application mutant SHA256 is cf8f86c694667a64d4d298c82136129268379dc52baaf305cae696dd926d0775.

Actual screenshots: [API29 reader](acceptance/api29-reader.png), [guitar](acceptance/api29-guitar.png), [ukulele](acceptance/api29-ukulele.png), [custom](acceptance/api29-custom.png); [API34 reader](acceptance/api34-reader.png), [guitar](acceptance/api34-guitar.png), [ukulele](acceptance/api34-ukulele.png), [custom](acceptance/api34-custom.png). These are captured application Views/Canvas output.

| Delivered material | SHA256 |
| --- | --- |
| [ARM64 APK](chordreader-arm64-v8a.apk), 1,217,169 bytes | 12c1b228866f98e4eafa3be5b6f1f2a5136d0ac4def8e3751e986bff8aa3b2a3 |
| [ARM32 APK](chordreader-armeabi-v7a.apk), 1,217,171 bytes | 9f3d4985f60f9faa4937ccf775218da3f4b9a38c385b34e679041306b566fc95 |
| ARM64 native libchordreader.so | c486de6c5e8245dcccf13fbdea0ba6e1df0bc3e71290eb042ab2affd94f0db30 |
| ARM32 native libchordreader.so | 2ab9e0c8fa5e9d2c75d448feea5b1efe07c673ed25e077a22a26893861286094 |
| Managed application DEX asset | 66f9dcf41ee7684ce2299187eb9ce9487e43cc850af9fe2e77b3f24bd377722e |
| Native callback classes.dex | 33fc1d8612d216a48d46aad72c5c863fa96f00b9de5e4d662ab8aaf26bd237b8 |

The selected x86_64 test APK SHA256 is 808786b3783a769c1692783efdac14e0d97bb4c3bb71970fee3677c5e247853b; its native library SHA256 is bae28e12e2d47ca358328a52a29fb914a8d9c8a6bab27b1d37f8f67a4aa19066. It remains available in the immutable producer artifact. APK reproducibility is not asserted: packager receipts retain their actual timestamp/signature policy and exact selected identities.


The original740bbf frontend Unicode-subtraction refusal and cascading undefined-main diagnostic remain recorded. Compatible frontend reconciliation removes that error without rewriting Unicode syntax. The old binder/constructor limitations describe the historical backend, not the current managed application's result. Earlier failed scrolling observations, same-name import loss, Google DocumentsUI assumption and keyboard-covered chart assertions remain preserved in source/run history.

## Feature inventory

| Function | Candidate status and limits |
| --- | --- |
| Plain text, Unicode/CRLF import, edit/save/reopen, source-preserving export | Installed emulator acceptance; original source bytes retained |
| Legacy .txt/.pl and document-picker callbacks | Installed emulator byte-for-byte round trips |
| Highlighting, qualities/extensions/slash bass, written transposition and capo | Checked/compared core, actual ART and installed controls; explicit enharmonic spellings retained |
| Major/minor key declarations and restart | Installed controls and persistence; no automatic harmonic-function inference |
| Ordered setlists with repeated songs | Installed acceptance, including legacy duplicate-name occurrences and collision-safe new copies |
| Song/list deletion | Installed confirm/cancel and repeated-reference cleanup; unrelated original sources/lists preserved |
| Guitar/ukulele variations and custom diagrams | Actual native Canvas screenshots, original dictionary indices, checked custom validation and restart |
| Auto-scroll, speed, pause, reading position | Actual motion and native getScrollY readback after process death and background/resume |
| Settings, selection, installation replacement | Real1001→1002 install-r and later replacement; no uninstall; exact private bytes and installed APK identity checked |
| Android sharing/navigation | Real chooser opened/dismissed without sending; native application navigation |
| Supported online chart-format extraction | Checked source/host regression; live third-party availability and IB results remain separate gates |
| IB ACTION_SEARCH | Explicit for-result caller with original raw query; API34 actual caller/button/receiver/once-encoded query PASS; full search remains BLOCKED at Google's JavaScript continuation, result/return workflow unqualified; API29 pairing pending; no generic browser fallback |
| Physical TAB_P10 | PHYSICAL_ACCEPTANCE_BLOCKED: no authenticated endpoint, live capability/package/signer inventory or installed-byte observation |
| Historical extras | Original translations/resources/license retained as assets; new controls English. Color/national-note menus, BPM metronome, drag/drop gesture parity and migration from another package's private SQLite data are deferred. |

## Pinned owners

| Owner | Exact input / remaining obligation |
| --- | --- |
| isomorphisms/Idric | e7e03fdc896d3740c735c603b5fed792e6172d83 combines Unicode subtraction and driver error-exit repair; [isomorphisms/Idric PR #142, “Accept Unicode subtraction in checked Idriç sources”](https://github.com/isomorphisms/Idric/pull/142) remains unmerged |
| isomorphisms/android-NDK | 6e1c9619a96f28494ad891a32a06edfb72f3e25b canonical managed DEX/JNI/packager; no unresolved managed operation rejection remains for the integrated reachable application core |
| fuego-ironworks/idric-arm-thumb | c13a6a223a24c211d090d2c88a395c134ed8d469 callback/oracle input; native driver repair11a2262cdb222b6632a91168c26ef3a96c65ec6d is qualified separately in [fuego-ironworks/idric-arm-thumb PR #119, “Restore native driver against the maintained Idriç ANF API”](https://github.com/fuego-ironworks/idric-arm-thumb/pull/119). NativeCore Text source ABI remains a genuine separate native-backend gap; it does not block the managed application |
| isomorphisms/ai-ci | c1e2d611672998f38495f5a901007d5a081ae047, [isomorphisms/ai-ci PR #334, “Independently qualify ChordReader managed music from signed APK assets on ART”](https://github.com/isomorphisms/ai-ci/pull/334), independent API29/API34 PASS against the selected signed artifact |
| walnut-burgundy/tymoczko | 618ccba16d3e2d204e82a595925add768fd49651, [walnut-burgundy/tymoczko PR #5, “Define the bounded written-note and key-spelling contract for ChordReader”](https://github.com/walnut-burgundy/tymoczko/pull/5); one executable Music/Key model, no general OPTIC prerequisite |
| isomorphisms/ib | Current observer 8f77915d8551ade26b931c3ebe11837345ce82b8 preserves the exact managed caller pin and pairs IB 57e0352175ee2dc6254ea5b722540e94e0d6d50a, source producer 41347346657 / artifact 13100274582/archive SHA256 091a4dd9e08a8294fe23220916a8577490ef8efe3525bc1d6797935ed5bf8f8a. Decoder/search replay 41350061080, API34 job 124978187318: actual e6 caller, authenticated for-result receiver, spoofed/warm caller refusals, exact-once Google encoding and independent committed-range/digest controls PASS. Actual native Google continuation touch is observed, but public results/clicked result remain NOT_RUN; the required full search gate FAILS at the JavaScript-enabling page. API29 remains in progress; no API34 result is projected onto it. The earlier attempted caller replay 41349544024 was cancelled by that owner continuation before emulator acceptance; it is not a pass. Historical FB9/86dc caller/query/original-byte acceptance remains separate; its actual Google continuation yielded JavaScript-enabling instructions, public results FAIL and clicked result NOT_RUN |
| isomorphisms/catfood | 609a9628d5a52860f956bf62e0914a0cd03292ae bootstrap input; physical discovery/install/acceptance pending authenticated TAB_P10 transport |
| dilapidated-shed/grease | f19c94c6df18cddbdc1e81463e5bd689533e3c13 maintained packaging/observation runtime |

No physical install, physical signer check, tablet UI acceptance, complete IB results workflow, API19 ART acceptance or authorization to release is implied. Required physical/search gates remain open. No release or merge is performed.

## Current IB boundary observation

[API34 handoff receipt](ib/api34-handoff.receipt.tsv) and [continuation receipt](ib/api34-continuation.receipt.tsv) bind the actual managed caller e6c84d64 to IB 57e03521. The new caller input identity is [retained](ib/chordreader-input-identity.tsv), along with the [exact IB input](ib/ib-input-identity.tsv). Observer 8f77915d8551ade26b931c3ebe11837345ce82b8 / run 41350061080 / job 124978187318 produced artifact 13100679530, 20,852,056 bytes, SHA256 d726ee90115c702815f20465c2b2617074268c8eff8e3d21b67ad3df25221976. Its archive was downloaded and its digest verified. The complete search job remains failed; a passing handoff is not a working public search-results feature. Result navigation and return to ChordReader are not accepted. These pending functions remain assigned to isomorphisms/ib and its ai-ci observer, while independent songbook imports remain usable.
