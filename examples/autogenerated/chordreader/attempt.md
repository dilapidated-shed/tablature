# Program attempt: ChordReader

Status: PARTIAL — implementation in progress; no Android acceptance.

## Purpose

Replace the inherited application with an Idriç-owned musical and application
core while preserving its resources, attribution and legacy song files.

## Intended behavior

Parse and print written chords, preserve spelling, transpose by written
intervals, recognise positioned chords without changing lyrics, and manage
songs, setlists and reader state. The pure core does not acquire Android objects.

## Type-system sketch

### Values and domains

Written notes carry a letter and an integral accidental. Pitch classes are a
separate quotient modulo twelve. Written intervals retain both letter motion
and semitone motion. Chord qualities, extensions, added/altered degrees,
suspensions and slash basses have separate fields. A source span records Unicode
scalar, UTF-8 byte and UTF-16 code-unit offsets, with an exclusive end.

### Types and signatures

`parse_chord : Text → Either Text WrittenChord`

`print_chord : WrittenChord → Text`

`transpose_chord : WrittenInterval → WrittenChord → WrittenChord`

`recognise_chart : Text → List PositionedChord`

`update_reader : ReaderEvent → ReaderState → ReaderState`

### Actions and effects

Musical operations and state transitions are pure. Reading/writing bytes,
networking, clocks, clipboard/sharing, input and drawing belong to explicit
platform interfaces. Source text remains distinct from rendered transposition.

### Laws, invariants, and errors

Round-trip retains written slash-bass spelling. A supplied written interval
changes both root and bass by the same letter/semitone motion. Transposition
does not edit stored source. Invalid syntax returns an error rather than a
partially recognised prefix. Spans refer to the original source. Legacy `.txt`
songs and newline-delimited `.pl` setlists remain importable.

### Runtime and backend boundary

Needs Text/Char, records, algebraic choices, lists, recursion, calls and Integer
arithmetic. DEX and native ARM qualification are separate. The current generic
DEX ABI admits Int32/Text exports; current native ARM admits runtime-free numeric
leaves. Neither source presence nor host execution proves Android execution.

## Idriç attempt

Sources: `Music.idric`, `Chart.idric`, `Reader.idric`, `Main.idric`.

Compiler: maintained `Idriç` branch, initially resolved to
`0e8cfdd1106ebdeffd01b6c519880ea3afc7dc35`.

Executed: `make -f Makefile.idric test assets` with the maintained compiler,
the Unicode subtraction fix, and the extended checked DEX backend. The pure
core passes 366 checks; Lua matches 1,049 live Idriç musical rows. Application
tests compare the persistence bytes with live Idriç output and exercise restart,
setlists, both original dictionaries, custom fingerings and scrolling.

## Theory ownership

Consulted `walnut-burgundy/tymoczko`, `OPTIC.idric`: its quotient-policy types
describe identifications, not a written-chord parser or spelling engine. This
application does not invent an OPTIC coordinate/voice-leading implementation.
Retaining written spelling before the octave quotient is an application need.

## Result or failure

The bootstrap completed incrementally on this 8 GiB host. The monolithic
optimized compiler build exceeded the memory limit. Focused syntax fixtures,
core tests and backend fixtures were subsequently compiled and executed.

The full AndroidCore export typechecked and retained its checked ANF, then
failed DEX lowering at the real Music.parse_chord call. Adding checked leaf
calls, nested binding inference, Text branches and Unicode strings advanced
the backend, but recursive calls, constructors and collections remain blocked.
The native ARM driver was migrated to the maintained ANF API and emitted its
word kernels. NativeCore.idric is rejected for its Text ABI. See the retained
diagnostics and checked forms in evidence/chordreader.

## Fallback

The authorized C+Lua contingency supplies the blocked parser, written spelling,
chart recognition, Android state and presentation. It is compared mechanically
with the checked Idriç core. AppPitch.idric remains independently executable:
the candidate requires its actual DEX pitch steps and accidental normalization
through ART. C only supplies Android/Lua ABI operations. The fixed callback
adapter is checked host encoding, separate from generic ANF lowering.

## Idriç language work exposed

Reusable changes are in their owning repositories: the subtraction lexer fix,
DEX lowering/encoding, native compiler API migration, and declared DEX APK
packaging. Details and immutable input pins are in EVIDENCE.md.

## Evidence boundary

Host execution and signed packaging are verified. ART, installation, launch,
interaction, API19 runtime and physical-device acceptance require independent
evidence. This checkpoint does not call the contingency a full Idriç app.
