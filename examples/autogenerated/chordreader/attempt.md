# Program attempt: ChordReader

Status: checked host core PASS; genuine DEX/ART subset PASS; usable C+Lua
Android contingency with actual import/transposition/restart acceptance.

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

Host execution, signed packaging, 33 ART assertions and actual API29
installation/launch/import/transposition/setlist/process-restart behavior are
verified independently. API19 runtime and physical-device acceptance remain
unverified. The contingency is explicitly C+Lua, never called a full Idriç app.

## Executable Android acceptance driver

AndroidAcceptance.idric is a checked host program controlling only the explicitly
identified x86_64 emulator. Its Target record keeps ADB and serial together;
XML attributes yield Maybe coordinates, and the actual Android library must
decode through ReaderState. Three local cases reject missing/invisible controls.
The driver installs the real APK, invokes the separate ART oracle against the
checked DEX, clicks real controls, tests Unicode/source preservation, two songs,
legacy setlists and full process restarts. It cannot count an emulator as a
physical MIRO device. No Python/Java application helper replaces this program.
Initial split/List1 and missing projection-import source errors were corrected
in Idriç; the final source compiles without diagnostics and its local cases pass.
The base installed-app acceptance passed. The extended program also drives the
standard document picker, compares ordered .pl bytes, tests provider display-name
delivery, and opens guitar/ukulele diagrams. File-result timing is explicit:
wait for the app to resume before reading the newly created document.

An API29 software-emulator run exposed a harness defect: uiautomator can return
exit status0 with "null root" while a dictionary view is busy, retaining the
previous XML file. The corrected driver removes that file before each dump,
requires the actual dump-success message, and retries at most five times.
A later fresh snapshot confirmed the real C guitar diagram and ten variations.
Stale accessibility output cannot count as a passing interaction.
The software emulator can also hold a tap long enough for DocumentsUI to enter
its real selection mode. The driver confirms the observed SELECT control when
present; immediate-open and explicit-selection document flows are both valid.

RejectBroken.idric is an intentionally invalid negative control: its declared
Int32 answer is supplied Text. The strict build must reject it before producing
an executable. This checks the actual -Werror frontend behavior rather than
assuming a successful command means its diagnostics were empty.
