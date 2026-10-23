# ChordReader implementation and acceptance ledger

This branch replaces the application architecture from accepted master
2179c276d88d91ba01642dde1a6c80a65103962f. It does not merge the retained Kotlin
branch. The original sources/resources remain available for comparison.

## Executed host evidence

`make -f Makefile.idric test assets` passes on Ubuntu24.04 x86_64. The typed
Idriç music/chart/reader/dictionary core passes 366 checks. The separately
executing Lua musical implementation matches 1,049 live Idriç rows. Application
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
| DEX backend with application improvements | 004389155abb1650fd6687477da847eed64ffd37 |
| Android-NDK adapter/packager | 8acc92fbf1436e0951eaa15013d7b67626b00a1e |
| Native ARM starting head | ac981d6a9a61e75ad913768f74353829d0cab2e1 |
| Signing registry | d7402b34bbdd0c17bbc92bf3b7ea936f761b6a06 |
| Stable public test key source | isomorphismes/wegert 89dcfb840cec1a66ee04c7f7404954cbd6c09839 |
| Lua5.4.8 archive SHA256 | 4f18ddae154e793e46eeab727c59ef1c0c0c2b744e7b94219710d76f530629ae |
| Native compiler | NDK29.0.14206865; ARM32 API19 link stubs from NDK25.2.9519653 |
| Independent DEX oracle | baksmali/smali3.0.10, SHA256 pins in maintained backend Makefile |

## Feature and runtime ledger

| Operation | Typed Idriç host core | Candidate Android execution owner | Strongest current evidence |
| --- | --- | --- | --- |
| Written notes, qualities, degrees, slash bass | Implemented | Lua contingency | 1,049 comparisons |
| Unicode canonical printing and source positions | Implemented | Lua; accidental aliases call checked DEX | Host assertions; DEX independently decoded |
| Pitch-class up/down | Implemented | Checked Idriç DEX through ART | DEX emitted; Android pending |
| Written intervals, key context, capo | Implemented | Lua; pitch motion checked by required DEX operations | Core/context/restart tests |
| Lyrics and whitespace preservation/highlighting | Implemented | Lua spans and Android TextView | Unicode offset/source tests; Android pending |
| Guitar/ukulele/custom diagrams | Typed dictionary loader | Lua lookup and C Android Canvas | Original assets and restart tested on host |
| Songs, editing, reopen, settings | Typed state and persistence | Lua and C private storage | Byte comparison and simulated restart |
| Setlists and legacy .txt/.pl | Implemented | Lua | Multiple-song/setlist/import host tests |
| Scrolling, speed, pause/resume | Typed state | Lua timers plus C platform clock/scroll | Fractional/pause host tests |
| Search and HTTPS importing | Explicit platform boundary | Browser search intent; C HTTPS plus Lua extraction | Implemented; live service/Android pending |
| File import/export and sharing | Legacy formats | Android content/text intents and share sheet | Implemented; Android pending |
| Original translations/resources/license | Preserved | Icons/about assets retained; new controls currently English | Source/assets retained; translated UI parity pending |
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
host. Installation/launch/interaction remain pending at this checkpoint.

## History, CI and remaining acceptance

PR4 (retained head4c256620a2a48728c4c63a3311a682b08d84e458) is closed and
unmerged. PR5 merged into that branch, not master. Its tests/corrections are
comparison material, not accepted Kotlin architecture. The recording-based
Therapy investigation remains separate; no recording-backed correction is
claimed here.

The replacement workflow triggers on implementation-branch pushes, PRs to
master and manual dispatch. It builds checked source and both ARM APKs with
pinned dependencies and the central signer gate. Source presence alone does
not resolve Issue6: an actual automatic run is required. The old Gradle-only
workflow is retired with the architectural replacement. Master merge remains
blocked until automatic checks and application runtime acceptance pass.
