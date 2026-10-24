# Original application inventory and replacement mapping

Baseline: 2179c276d88d91ba01642dde1a6c80a65103962f. The original tree is
retained under app/src/main for comparison and attribution. No retained-branch
Kotlin implementation is merged into this architecture.

| Original responsibility | Original sources | Replacement |
| --- | --- | --- |
| Chord syntax, recognition, note spelling, source spans | chords/* and chords/regex/* | Music.idric, Chart.idric; compared music.lua contingency |
| Transposition and capo | helper/TransposeHelper.java, model/SongViewFragmentViewModel.java | WrittenInterval, distinct written note/pitch types; rendering leaves stored source intact |
| Web search and extraction | ui/WebSearchFragment.java, helper/WebPageExtractionHelper.java, ChordWebpage.java | Browser search intent, HTTPS platform request, reviewed plain/preformatted chart import |
| Song saving, reopening, export and Android sharing | helper/SaveFileHelper.java, model/DataViewModel.java | Typed Reader persistence contract, Lua state, atomic private files, Android document picker and share sheet |
| Song/setlist lists, setlist editing and ordering | ui/ListFragment.java, ui/DraggableListFragment.java, adapters | Songs/Setlists screens; newline title editing preserves ordered repetitions; legacy .txt/.pl import/export |
| Reader/editing/highlighting | ui/SongViewFragment.java, model/SongViewFragmentViewModel.java | Native platform Views; Lua event/state contingency; Idriç-compatible source offsets |
| Guitar and ukulele variations, custom fingerings | helper/ChordDictionary.java, views/ChordVisualisationView.java, ui/ChordDictionaryEditFragment.java | Original JSON dictionaries, typed loader and pitch/shape lookup, C Canvas drawing, custom fingering persistence |
| Scrolling and speed/pause | views/AutoScrollView.java | Fractional elapsed-time state, platform timer and scroll position, explicit pause/resume |
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
