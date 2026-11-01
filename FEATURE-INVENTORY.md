# Original application inventory and replacement mapping

Qualified managed application source: e6c84d645ad7086a11ae2735258188a49e444d13.
Complete installed API29/API34 acceptance and independent exact-APK ART
qualification pass; [delivery ledger](candidates/QUALIFICATION.md) binds the
signed bytes, screenshots and remaining physical/IB gates.

Baseline: 2179c276d88d91ba01642dde1a6c80a65103962f. The original tree is
retained under app/src/main for comparison and attribution. No retained-branch
Kotlin implementation is merged into this architecture.

| Original responsibility | Original sources | Replacement |
| --- | --- | --- |
| Chord syntax, recognition, note spelling, source spans | chords/* and chords/regex/* | Music.idric, Chart.idric via checked managed export; actual ART checkpoints in EVIDENCE.md. The compared Lua music reference is not the candidate music asset. |
| Transposition and capo | helper/TransposeHelper.java, model/SongViewFragmentViewModel.java | WrittenInterval, distinct written note/pitch types; rendering leaves stored source intact |
| Declared major/minor keys | Completion campaign | Key.idric retains tonic/mode and derives diatonic written notes; key control and persistence retain both declarations. 394 checked host cases and 2,142 reference comparisons pass; actual declared-key controls and restart pass on API29/API34 at e6c84d64. Mode conversion refuses rather than inventing harmony. |
| Web search and extraction | ui/WebSearchFragment.java, helper/WebPageExtractionHelper.java, ChordWebpage.java | Explicit ACTION_SEARCH to IB with original unescaped query, no generic browser fallback; separate HTTPS platform request and supported preformatted/Ultimate Guitar chart import. Actual API34 managed caller/receiver/query encoding passes; Google public results and complete return navigation remain blocked/unqualified. API29 pairing is pending. |
| Song saving, reopening, export and Android sharing | helper/SaveFileHelper.java, model/DataViewModel.java | Managed Reader transitions/framing, Lua presentation records, atomic private files, Android document picker and share sheet; per-run receipts bind installed acceptance |
| Song/setlist lists, setlist editing and ordering | ui/ListFragment.java, ui/DraggableListFragment.java, adapters | Songs/Setlists screens; newline title editing preserves ordered repetitions; legacy .txt/.pl import/export. New same-name imports choose an unused copy name in checked Reader state and preserve both lists. |
| Song and setlist removal | Original songbook management | Explicit confirmation/cancellation controls; checked Idriç removes the selected identity, cleans every repeated song reference and preserves other charts and setlists. |
| Reader/editing/highlighting | ui/SongViewFragment.java, model/SongViewFragmentViewModel.java | Native platform Views; checked Idriç state transitions, chart recognition and scalar/UTF-8/UTF-16 offsets; Lua presentation/transport |
| Guitar and ukulele variations, custom fingerings | helper/ChordDictionary.java, views/ChordVisualisationView.java, ui/ChordDictionaryEditFragment.java | Original JSON dictionaries processed by actual Dictionary.idric loader into bundled indices; ART spelling/shape keys and custom-position validation; C Canvas drawing and persistent custom fingerings |
| Scrolling and speed/pause | views/AutoScrollView.java | Checked Reader elapsed-time arithmetic retains fractional remainder; native timer/viewport and explicit pause/resume. Restoration waits for layout and verifies getScrollY readback. |
| Preferences and navigation | helper/PreferenceHelper.java, ui/SettingsFragment.java, MainActivity.java | Saved text size, instrument, hand, scroll speed, selected song/interval/capo/position, screen navigation |
| About/help/resources/translations/license | ui/AboutFragment.java, ui/HelpFragment.java, res/* | Original files retained; icons, dictionaries, about text, translations and license included in development assets |

The replacement supplies the requested songbook operations through different
controls. It does not claim an identical AndroidX layout. New controls currently
use English. The original color-scheme/national note-name menus, per-song BPM
metronome, drag-and-drop setlist gestures, and SQLite migration are not ported.
Legacy plain song text is preserved, including metadata/header lines; those
lines are not interpreted as the old BPM metronome settings. Automatic copying
of another package's private SQLite state is intentionally unavailable; import
the original .txt/.pl documents without modifying that package's data.

The runtime/evidence ledger distinguishes implementation, host execution,
Android emulator behavior and physical-device acceptance. Consult EVIDENCE.md
and the executable AndroidAcceptance.idric receipt for the actual result.

Version1001→1002 replacement without uninstalling has executed successfully at
the accepted e6c84d64 candidate, including identically named legacy lists. The current candidate keeps the same development package
and public test signer. Physical TAB_P10 acceptance is blocked by unavailable
authenticated access; IB live acquisition/result navigation is a separate
pending integration. Neither is inferred from the independent songbook tests.
