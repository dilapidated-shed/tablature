# Chord Changes

Chord Changes is the development name of the native Android chord-chart reader.
Its icon depicts two anonymous six-string fingering patterns separated by a
change arrow, without chord names, notes, a staff, or a page motif. Finger
markers sit in the spaces between fret wires. The development package ID and signer are unchanged,
so existing development installs retain their data when upgraded.

The development candidate moves music, chart processing and reader transitions
to checked Idriç executing through the canonical managed DEX runtime. Native C
owns Android/JNI, storage, Views and intents; Lua retains presentation and
transport records. The earlier C+Lua implementation remains a regression
reference and an accepted historical fallback. It is not bundled as an
automatic musical fallback in the new candidate. See EVIDENCE.md for the
revision-bound compiler, ART and installed-application results.
No Java/Kotlin application logic is added.

The development package `org.isomorphisms.chordreader.dev` keeps the original
application and its data separate. Signed ARM32/API19 and ARM64/API21 APKs,
their signer/source receipts, and Android emulator acceptance evidence are
produced by `.github/workflows/idric-chordreader.yml`. See [EVIDENCE.md](EVIDENCE.md)
for language ownership, exact toolchain revisions and physical-device limits.
Search sends original query text to IB with an authenticated fresh Android
for-result handoff. The same IB/ICU/Arena reader path owns acquisition and
search rendering; real search results remain independently unqualified.

The existing Java/Kotlin tree below remains comparison material; the retained
Kotlin branch is not part of this replacement.

ChordReader 2 is an enhanced version of ChordReader, developed by Nolan Lawson. It's intended to keep compatibility to old devices, as old tablets still serves well as book of music. ;)

It's an app that:
- fetches chord charts and tabulatures for your favorite songs from the Internet,
- saves them to a local file,
- displays them in an easy-to-read format with the chords highlighted in an autoscroll view,
- transposes the identified chords up or down, or you can add a capo,
- provides common chord variations.


[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
     alt="Get it on F-Droid"
     height="80">](https://f-droid.org/packages/org.hollowbamboo.chordreader2/)

## Status
This is a fork of the abandoned ChordReader app by Nolan Lawson, and Marcel Klehr respectively.
> It's my first project at all. Every comment or support is welcomed.

## License
[GNU GPLv3+][1]

[1]: https://opensource.org/licenses/GPL-3.0

## Donation
If you would like to donate, visit 
[paypal.me/hollowbamboo][2]. 

[2]:  https://paypal.me/hollowbamboo

