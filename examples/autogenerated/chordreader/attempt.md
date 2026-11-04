# Program attempt: ChordReader

Status: managed host/DEX/ART and signed packaging checkpoints PASS; actual
version1001→1002 data-preserving replacement PASS at533071db. Installed UI
qualification is revision-bound; consult EVIDENCE.md and per-run receipts.
Historical fallback and failures below retain their original evidence scope.

## Purpose

Replace the inherited application with an Idriç-owned musical and application
core while preserving its resources, attribution and legacy song files.

## Intended behavior

Parse and print written chords, preserve spelling, transpose by written
intervals, recognise positioned chords without changing lyrics, and manage
songs, setlists and reader state. The pure core does not acquire Android objects.

## Type-system sketch

### Declared keys (completion campaign)

`WrittenKey` retains a written tonic and a distinct major/minor mode.
`KeyChange` retains both declarations; `interval_between_keys` returns either
a written interval or an explicit refusal to convert between modes. A uniform
transposition cannot change major into minor. `diatonic_note` requires an
explicit degree from one through seven and returns its written note, never a
pitch-class naming-table lookup. Chromatic chart notation remains source-owned.
Reader persistence adds an optional `T` record while accepting existing files.
All operations are pure; Android continues to own UTF-8 and atomic file writes.
This slice needs ordinary choices, records, lists, checked integer arithmetic
and Text parsing. Host/DEX/ART/application qualification remains separate;
executed managed checkpoints are recorded in EVIDENCE.md.

### Managed application boundary

New setlist imports use `available_setlist_name : Text → List Setlist → Text`
in checked Reader state. Existing names are preserved; an imported copy receives
an unused suffix. The search is bounded by the number of existing names, so it
does not require unbounded effects or a second UI-owned state model. Explicit
edits preserve their collection position and refuse a conflicting rename. The
managed host regression deliberately uses different repeated-song orders for
the original and imported lists so an overwrite cannot appear to pass.

Legacy libraries can contain identically named setlists. The checked
`edit_setlist_at` and `remove_setlist_at` operations select the actual occurrence
in the submitted ordered library, rather than treating its display name as a
unique identity. This preserves other legacy occurrences and collection order
without changing the persistence format. Host controls retain different song
orders in the identically named lists. Android qualification creates those
duplicates in the accepted version1001 app, verifies their replacement/reopen
preservation, and edits only the selected second occurrence.

Song and setlist deletion use explicit confirmation/cancellation screens in the
presentation layer. Checked Reader operations own the mutations. Real Android
controls require cancellation to preserve exact library bytes, song removal to
clean every repeated reference while preserving all other charts, and setlist
removal to preserve every song and other list. No exported chart file is deleted.

`application_request : Text → Text` receives a command plus scalar-counted
text fields and returns `1` followed by a result or `0` followed by a checked
error. It calls the maintained Music, Chart, Key and Reader functions; it does
not implement another parser. Musical objects and state stay managed inside
ART. Lua's replacement music module decodes transport records only. The JNI
boundary accepts ordinary UTF-8, converts to/from Android UTF-16, and invokes
the checked String export. Native failures refuse the action without retrying
the Lua musical implementation. The retained contingency supplies the regression
baseline and prior APK; the new candidate has no automatic musical fallback.

Commands cover parsing, fingering keys, chromatic intervals, chart recognition,
written rendering, declared keys, library framing and reader transitions.
Actual source generation, independent decoding, ART and installed UI execution
are separate required gates. The original AndroidCore parser probe remains an
unchanged-source control rather than being replaced by this boundary.

### Original dictionary preprocessing

`DictionaryAssets` reads the retained JSON through the actual Dictionary.idric
loaders, computes each key through Music.fingering_lookup_key, and writes a
versioned TSV index of exact string positions. This is checked host execution
over fixed application assets, not ART acceptance of the JSON/Double format
boundary. The runtime transports that index and obtains the requested chord's
lookup key from the managed musical core. It does not parse all 12,891 guitar
spellings through JNI during a diagram interaction. Original JSON remains
retained for attribution and independent comparison. Generation and UI controls
must succeed before the index is accepted.

Custom fingering input also calls the checked Dictionary.custom_diagram through
the managed boundary. Every token must denote a fret or mute and the exact
instrument string count must match; invalid tokens cannot disappear from a Lua
array and accidentally make an invalid input appear to have the right length.
Lua receives only the checked chord spelling and transport positions.

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

## Historical result or failure

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

## Historical fallback

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

The host driver also uses a typed six-byte Buffer and the maintained binary
file API to create C/NUL/bad/newline. It imports that actual document through
Android and requires refusal plus preservation of every saved song source.
This closes the C-string boundary before Lua: checking for NUL only after
lua_pushstring would be too late, because truncation has already occurred.
Import refusals survive the following lifecycle resume rather than disappearing
before the screen can show them. Host state tests exercise that ordering.

One local acceptance run overlapped rebuilding its host driver and ended in a
host invalid-memory error; that run is not acceptance evidence or an established
compiler defect. Make now stages a new immutable driver/APK/DEX bundle for each
unique nonce, refuses to overwrite an earlier run directory, and removes the
previous mutable receipt before testing. Build iteration cannot replace inputs
under an executing acceptance program.

RejectBroken.idric is an intentionally invalid negative control: its declared
Int32 answer is supplied Text. The strict build must reject it before producing
an executable. This checks the actual -Werror frontend behavior rather than
assuming a successful command means its diagnostics were empty.

## Semitone navigation completion, November 3, 2026

The regression domain keeps original chart Text, WrittenChord, PitchClass,
signed Integer chromatic displacement, WrittenInterval letter/semitone
displacements, declared key/mode, and slash-bass identity separate. The central
operations remain transpose_chromatic_chord : Integer → WrittenChord →
WrittenChord and reader_text : ReaderState → Text. Host tests compute sounding
pitch expectations modulo twelve, preserve every non-note chord field, and
exercise ReaderState serialization. Installed acceptance drives real controls,
checks octave and opposite-step restoration, opens the transposed A fingering,
and retains the existing process-death, key, capo and upgrade assertions.

The initial supplied Android acceptance source contained literal backslash-n
tokens between statements; producer run 41569015318 stopped at
AndroidAcceptance.idric before signing or emulator execution. They were
converted to real source newlines without changing string fixture bytes.

The expanded matrix at source 4372c1ea143a63028082b2548d306483b625ce6c
found fourteen failures in producer run 41747907398: A-flat with each of seven
qualities at shifts -11 and -23. Music.transpose_chromatic_chord searched only
six descending letter steps. A-flat minus eleven semitones needs the natural A
one written octave lower, requiring seven letter steps. The repair includes
both octave endpoints (-7 and +7); B-sharp and C-flat cases protect the opposite
edge. Intentional slash intervals may need double accidentals, so their bound
is two; ordinary single-root navigation has bound one in this matrix.

All attempts remain checked Idriç. No alternative musical engine or language
fallback was introduced. The separate ai-ci observer uses literal musical
expectations through the packaged application's export; its old producer
binding is historical until explicitly updated to a successful new artifact.
The required compiler operation is unchanged; current host, DEX, installed UI
and signing results must be read from the exact producer run rather than
inferred from this account. There is no newly established Idriç language gap.
