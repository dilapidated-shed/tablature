# Remote songbooks (development branch)

ChordReader remains **local-first**. The canonical Unicode/Idriç-framed
songbook is the app-private library.txt; edits and reading require no network.
A remote backend may transfer the bytes, but may not reinterpret their musical
contents or bypass the checked Idriç library validator.

## GitHub, the first backend

In the reader, choose **Remote → Configure** and enter:

- Title: owner/private-songbook (an existing repository, preferably private).
- Text: line 1 is the branch, e.g. main; line 2 is the destination,
  e.g. chordreader/library.txt.

The app does **not** create the repository or change its visibility. Use
**Remote → GitHub token** to enter a fine-grained personal access token with
*Contents: Read and write* on **only that destination repository**. The token
is kept in the application's current process memory and never placed in the
source tree, private songbook, saved remote configuration or sync baseline.
The entry is masked. It must be entered again after the app process exits.
For old Android/API19 devices the initial implementation deliberately avoids
claiming to persist a token with secure platform storage.

The GitHub Contents REST API provides GET and revision-protected PUT. The app
requires the HTTPS api.github.com origin, does not follow redirects, bounds
the reply, and uses GitHub's file blob SHA to prevent blind overwrites.
GitHub must already contain the destination branch. Each transfer currently
covers a **single songbook snapshot**, including setlists and reader metadata.
No chart files are added to the Tablature *source* repository by default.

- **Upload**: create the file if absent, or update only when the last synced
  remote version still matches; a different existing remote requires resolution.
- **Download**: fetch and validate a remote snapshot; if it differs locally,
  request explicit confirmation before changing the library.
- **Sync**: compare local and remote with the last successfully synchronized
  snapshot. Push when only local changed; pull when only remote changed;
  report a conflict when both differ. Never silently merge or delete.

The baseline is stored in remote-base.txt in app-private storage; it is
bound to provider, repository, branch and path. On a restore, the preceding local
library is first written to library-recovery.txt. A later restore replaces
that one recovery copy, so keep separate exports for longer archival history.
A corrupt remote file, unknown revision, missing token, failed TLS request,
HTTP 409, authorization failure, or changed local snapshot does not overwrite
either copy.

The app's existing Android document picker and HTTPS chart import remain
independent of remote synchronization. The user can still export individual
.txt song charts and .pl setlists. The GitHub remote is a *backup and
sync of the library*, not a downloader for arbitrary pages.

## Replaceable provider boundary

contingency/remote.lua owns provider configuration, encoding, revision
comparisons, conflict policy, download validation and asynchronous request
state. Its backend contract consists of functions read(config),
decode(response) and write(config,bytes,previous_revision).

android-native/platform.c is a narrow HTTPS transport adapter; the
checked Idriç reader remains authoritative for chart and songbook semantics.
Native code never owns musical spelling, chord parsing or merge decisions.

**SDF is a future backend.** It needs a separate authenticated SFTP/SSH or
equivalent explicit storage transport, plus connection configuration. It must
not be simulated through GitHub or by hard-coding SDF access into the reader.
Future providers should preserve revision-conditional writes, bounded reads,
credential isolation, atomic local commits, and explicit conflict behavior.
A manifest or per-song file layout can be added later, using the same provider
contract, without reworking the musical engine.

## Qualification and limits

contingency/remote-test.lua uses an offline simulated transport to exercise
first upload, SHA updates, remote changes, conflict refusals, explicit restore,
the local recovery copy, encoding errors, and credential isolation. It is run
by the branch's host workflow and included in the checked core's host
comparison target. Android emulator, physical MIRO C67, SDF and live
authenticated GitHub acceptance are separate obligations and must not be
inferred from host tests.

GitHub's Contents API has practical size constraints. This initial adapter
limits individual snapshots to 8 MiB and may reject large repositories/files
that the Contents endpoint does not return as base64. Larger collections need
sharding or Git blob/tree-based transfers; they must not be silently truncated.
