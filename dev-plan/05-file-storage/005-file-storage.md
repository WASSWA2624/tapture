# 005 — File storage: the organised folder tree and every service that writes into it

**Phase** 05 · File storage  |  **Depends on** [001](../01-orchestration/001-project-setup.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The whole of `core/files/`: one provider that resolves, creates and hands out the visible `Tapture/` root and the
disposable `Tapture/.cache` beside it under the device's documents directory, reporting an unwritable or absent
location as a recoverable failure rather than throwing; the sanitiser that turns arbitrary user text into a safe path
segment, the per-project eight-folder tree created from it under `Tapture/projects/<name>__<id>`, and the pure photo
sub-path builder that composes from the context hierarchy in force; the only two ways bytes move inside that tree — a
writer that streams to a temporary name, hashes in the same pass and renames into place, and a relocator that moves a
record's files when its context is set or corrected, in the same transaction as the path update; everything that lives
under `.cache`, being thumbnails generated once per hash and edge so lists never decode a full image, reduced copies
for online analysis, and the prune that keeps the folder bounded; a watched free-space state that warns while capture
continues and blocks new capture only once a further photo would risk losing data, always naming the next action; a
scan of one project's folder tree against its rows that reports both directions with sizes and offers adoption or an
evidence-missing flag as an explicit user choice; and the one gate every file from outside the app passes before a byte
of it is parsed. Later field-feedback work is included: `share_plus`, opening a project's files in an external app,
and showing storage volume totals with the current root.

## Files

Root and paths:

- `frontend/lib/core/files/storage_root.dart` (new)
- `frontend/lib/core/files/path_sanitizer.dart` (new)
- `frontend/lib/core/files/project_folders.dart` (new)
- `frontend/lib/core/files/photo_path_builder.dart` (new)

Writing and moving bytes:

- `frontend/lib/core/files/file_writer.dart` (new)
- `frontend/lib/core/files/file_relocation.dart` (new)

Derived artefacts under `.cache`:

- `frontend/lib/core/files/thumbnail_cache.dart` (new)
- `frontend/lib/core/files/compressed_copy.dart` (new)
- `frontend/lib/core/files/cache_cleanup.dart` (new)

Headroom, reconciliation and the import gate:

- `frontend/lib/core/files/storage_guard.dart` (new)
- `frontend/lib/core/files/orphan_scanner.dart` (new)
- `frontend/lib/core/files/file_validation.dart` (new)

Follow-up files:

- `frontend/pubspec.yaml`
- `frontend/tool/allowlist.yaml`
- `frontend/lib/core/files/download_service.dart`
- `frontend/lib/core/files/download_service_io.dart`
- `frontend/lib/core/files/download_service_web.dart`
- `frontend/lib/core/files/download_service_stub.dart`
- `frontend/lib/features/projects/data/project_openable_file_lookup.dart`
- `frontend/lib/features/projects/presentation/project_open_externally_action.dart`
- `frontend/lib/features/projects/presentation/project_list_view.dart`
- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/core/files/volume_stats.dart`
- `frontend/lib/core/files/folder_picker.dart`
- `frontend/lib/core/files/folder_picker_io.dart`
- `frontend/lib/core/files/folder_picker_web.dart`
- `frontend/lib/core/files/folder_picker_stub.dart`
- `frontend/lib/features/settings/presentation/storage_settings_screen.dart`
- `frontend/lib/features/settings/domain/setting_keys.dart`
- `frontend/android/app/src/main/kotlin/com/tapture/app/MainActivity.kt`
- `frontend/test/core/files/volume_stats_test.dart`
- `frontend/test/core/files/storage_guard_test.dart`
- `frontend/test/core/files/storage_root_test.dart`
- `frontend/test/core/files/folder_picker_test.dart`
- `frontend/test/features/settings/presentation/storage_settings_screen_test.dart`


## Contract

```dart
abstract interface class StorageRoot {
  Future<Result<Directory>> resolve();
  Future<Result<Directory>> cacheDir();   // Tapture/.cache
}

final storageRootProvider = Provider<StorageRoot>(...);

String sanitiseSegment(String input, {int maxLength = kMaxPathSegment});

abstract interface class ProjectFolders {
  Future<Result<Directory>> create(Project project);   // idempotent
  Future<Result<Directory>> resolve(Project project);
}

enum PhotoFolderStrategy { byContext, byTemplate, byCaptureDate, flat }

String buildPhotoPath({
  required PhotoFolderStrategy strategy,
  required List<String> contextValues,
  DateTime? capturedAt,
  String? templateName,
});

class WrittenFile {
  final String relativePath;
  final String sha256;
  final int byteLength;
}

abstract interface class FileWriter {
  Future<Result<WrittenFile>> write(Stream<List<int>> bytes, String relativePath);
  Future<Result<WrittenFile>> copyIn(File source, String relativePath);
}

abstract interface class FileRelocation {
  Future<Result<int>> relocateRecord(String recordId);   // returns files moved
}

abstract interface class ThumbnailCache {
  Future<Result<File>> thumbnail(String sha256, String sourcePath, {required int edge});
}

abstract interface class CompressedCopy {
  Future<Result<WrittenFile>> reduce(String sourcePath, {int? longEdge, int? quality});
}

abstract interface class CacheCleanup {
  Future<Result<int>> prune({Duration? maxAge, int? maxBytes});   // bytes reclaimed
}

enum HeadroomState { ample, low, critical }

abstract interface class StorageGuard {
  Stream<HeadroomState> watch();
  Future<Result<HeadroomState>> check();
}

class OrphanReport {
  final List<OrphanFile> filesWithoutRows;    // path, bytes, detected kind
  final List<MissingFile> rowsWithoutFiles;   // entity type, id, expected path
  final int reclaimableBytes;
}

abstract interface class OrphanScanner {
  Future<Result<OrphanReport>> scan(String projectId, {void Function(double)? onProgress});
  Future<Result<void>> adopt(OrphanFile file, {required String recordId});
  Future<Result<void>> flagMissing(MissingFile row);
}

enum ImportKind { image, document, spreadsheet, audio, bundle }

abstract interface class FileValidation {
  Future<Result<ImportKind>> validate(File file, {required Set<ImportKind> allowed});
  Future<Result<void>> validateArchive(File archive);
}
```

## Steps

1. Land `StorageRoot`. Resolve the platform documents directory through the permissions service, create `Tapture/` and
   `Tapture/.cache` when absent, memoise a successful resolve for the process, and probe writability by creating and
   removing a marker file. Expose the root only through `storageRootProvider`, so no caller composes an absolute path
   of its own. An unwritable, blocked or missing location returns a `StorageFailure` naming the path and the recovery
   action; a denied storage permission returns a `PermissionFailure` and the app stays usable.
2. Land the path layer. `sanitiseSegment` strips accents, replaces whitespace with hyphens, removes reserved and
   non-printing characters, upper-cases where the specification requires it, caps length and appends a numeric suffix
   on collision; it refuses `..`, absolute paths, drive prefixes, device names and empty results outright, as failures,
   never as silent substitutions, so a display name keeps letters, digits and hyphens and nothing else.
   `ProjectFolders` derives the folder name from the sanitised project name plus a short id suffix, `<sanitised>__<id>`,
   stores it in `projects.folderName` and always resolves from the stored value, so a rename never moves existing
   files; it creates the eight-folder tree `photos/`, `documents/`, `audio/`, `meetings/`, `reference/`, `templates/`,
   `exports/` and `imports/` under `Tapture/projects/<name>__<id>` on project creation, idempotently. `buildPhotoPath`
   composes `photos/<level1>/<level2>/<level3>/` from sanitised context values, falling back to `_unfiled` for any
   level not yet set, and implements the by-template, by-capture-date and flat strategies against the same interface.
3. Land `FileWriter` and `FileRelocation`. The writer writes to `<target>.part` in the destination directory, hashes
   while streaming, flushes, then renames, so the target either does not exist or is complete and hashed; it sweeps
   stale `.part` files on the next write to the same directory and never resumes one, and maps a full disk, a
   permission loss and a vanished parent directory to `StorageFailure` variants with recovery actions, leaving no
   partial file behind. The relocator computes the new relative path, moves each file, then updates
   `photos.relativePath` and the attachment rows inside one transaction, rolling the moves back if the transaction
   fails and the rows back if a move fails. Photos captured under `_unfiled` are promoted into the context tree when a
   context is applied after capture.
4. Land the `.cache` services. `ThumbnailCache` generates in an isolate on first request, keys entries
   `<sha256>_<edge>` under `.cache/thumbs/`, caps concurrent decodes at the `AppConstants` `concurrentDecodes` value,
   and serves a second request from disk without decoding the original again. `CompressedCopy` reduces for upload to
   the configured long edge and quality in an isolate, writes into `.cache/upload/` through the atomic writer, and
   returns the path and byte length. `CacheCleanup` prunes by age then by total size, oldest first, on launch and on
   demand from settings, and never leaves `.cache`. A missing entry regenerates transparently, so deleting the folder
   costs only time.
5. Land `StorageGuard`. Read free space on the storage root's volume, poll on app resume and at the start of a capture
   session rather than per shutter, and map free bytes to `ample`, to `low` below 500 MB and to `critical` below
   100 MB, both thresholds from `AppConstants.storage`. At `low`, warn once per session and let capture proceed; at
   `critical`, refuse a new capture with an explanation and a route to export and to cache cleanup carried on the
   `StorageFailure`. A save already under way completes even at `critical`, so a photo already taken is never
   discarded; capture drives the policy through `beginSession` and `completeSave` rather than reimplementing it.
6. Land `OrphanScanner`. Walk the project tree in pages, skipping `.cache` and `.part` files, and compare against
   `photos` and the attachment rows by relative path. Report both directions with byte sizes, reclaimable bytes and
   progress, hashing a candidate only when a path match is ambiguous. Adopt an orphan file through the normal media
   path, `upsertPhoto` or `upsertAttachment`, so it gains a hash and merge columns; flag a missing file with an audit
   entry against its row instead of deleting it. A cancelled scan returns a `CancelledFailure` and changes nothing.
7. Land `FileValidation`. Check the extension against the allow-list, then sniff a bounded 64-byte header and reject
   any file whose content contradicts its name, enforcing per-kind size ceilings from `AppConstants` before reading
   further. For archives, both spreadsheets and bundles, walk the ZIP central directory and reject any entry that
   escapes the extraction root, is absolute, is a symlink, or whose declared uncompressed total exceeds the ceiling;
   nothing is extracted to read that structure. Every refusal returns a typed `Failure` naming the file and the reason,
   quoting the basename as data.

## Constraints

- Every filesystem path in the app is derived from `storageRootProvider`, and free space is read through the same
  `core/` service with a fake behind it; a hardcoded root or a plugin call outside `core/files/` is a defect
  (FE-STR-11, FE-CODE-09).
- `.cache` is the only place derived artefacts may live, and it stays disposable (rule 1 of the standard).
- Raw evidence is never destroyed. Originals are opened read-only, so a source file's bytes and hash are identical
  before and after any derivation; relocation moves files rather than copying then deleting across the same volume, and
  an original is never rewritten (FE-SEC-08, rule 1 of the standard).
- A hard `File.delete` lives only in the purge job. The writability probe, the `.part` sweep and the cache prune remove
  only the temporary or derived file they created themselves, and the data-safety suite from 001 · Project setup and
  guardrails holds that boundary.
- The scan deletes nothing and moves nothing on its own; adoption and the evidence-missing flag are each a separate,
  confirmed user choice (rule 1 of the standard).
- Persist before confirming: every write is atomic and durable before the interface confirms it, so a caller sees
  success only after the rename and the row update are both durable (FE-STATE-07).
- Traversal is refused before a path is used, not after, and validation happens before parsing, never during it, with
  nothing partially validated reaching a parser (FE-SEC-06).
- File names, cell text and archive entry names are quoted as data — never interpolated into a query, a shell command
  or a provider instruction, and escaped where rendered (FE-SEC-05).
- Streaming, hashing, decoding, resizing, walking and pruning run in chunks through the isolate runner and never on the
  UI thread; nothing loads a whole photo or document into memory, and the scan reports progress and accepts
  cancellation (FE-PERF-02, FE-PERF-04, FE-PERF-07, FE-PERF-10).
- Sniffing reads a bounded header, not the whole file (FE-PERF-07).
- `buildPhotoPath` is pure and synchronous: it composes a relative path and never touches the filesystem (FE-PERF-02).
- Length caps, the suffix length, the strategy default, edge sizes, quality, maximum cache age and bytes, the headroom
  thresholds and the per-kind size ceilings come from `AppConstants`, not from literals at the call site (FE-CODE-09).
- Only genuine risk of loss blocks; the `low` warning is dismissible and offers *keep capturing* (FE-SIMP-08).
- A refusal names the consequence and the next action in plain language, rendered from a typed `Failure`
  (FE-SIMP-10, FE-CONS-11).

## Definition of done

- [x] The folder is visible in a file manager and over a cable, with no media-scanner exclusion applied.
- [x] A read-only or missing location yields a failure carrying a recovery action, and the app stays usable.
- [x] Resolving twice creates the tree once and returns the same directory.
- [x] A project named with slashes, emoji, accents or 300 characters still produces one valid folder, and two projects
      with the same name produce distinct folders.
- [x] Renaming a project changes nothing on disk and breaks no stored `relativePath`.
- [x] The tree produced for a fully set context matches the specification's example path exactly, and an unset level
      lands under `_unfiled`.
- [x] A simulated failure mid-write leaves the target absent and no `.part` file visible to the app.
- [x] The hash returned by the writer equals the hash of the file re-read from disk.
- [x] Correcting a facility name relocates every file of the affected records with no stored path left dangling, and a
      failure part-way leaves paths and files still agreeing.
- [x] A tray of thirty photos scrolls within the FE-PERF-01 budget on a mid-range device, decoding no full image.
- [x] A repeated thumbnail request hits the cache and performs no decode.
- [x] The original's hash is unchanged after compression, and the reduced copy is smaller.
- [x] Deleting `.cache` entirely loses nothing but speed; the next request rebuilds what it needs.
- [x] A device below 500 MB warns once and still captures; below 100 MB new capture is refused with a route to export.
- [x] A save already under way at the critical threshold completes and writes its row.
- [x] A full device never produces a truncated photo or a record without its file.
- [x] A project with one stray file and one deleted file reports exactly one entry on each side, with sizes.
- [x] A cancelled scan leaves no partial report and nothing changed on disk.
- [x] Adoption produces a normal media row with hash and merge columns; flagging leaves the row and its evidence intact.
- [x] A `.xlsx` that is really an executable, an oversized image and a zip with a `../` entry are each refused with a
      message naming the reason.
- [x] A valid file of each supported kind passes and reports its kind.
- [x] No rejected file is ever opened by a parser, and none leaves a copy behind.
- [x] Tests: `frontend/test/core/files/storage_root_test.dart` resolves into a temporary directory, asserts idempotent
      creation, asserts the failure variant for a blocked and for a not-writable location, and asserts the
      `PermissionFailure` when storage is denied.
- [x] Tests: `frontend/test/core/files/path_sanitizer_test.dart` runs a table of hostile inputs including traversal,
      absolute paths, drive prefixes, reserved device names and empty results, and asserts the length cap equals the
      `AppConstants` value.
- [x] Tests: `frontend/test/core/files/project_folders_test.dart` asserts idempotent tree creation and rename safety in
      a temporary directory.
- [x] Tests: `frontend/test/core/files/photo_path_builder_test.dart` covers all four strategies and every partially set
      context.
- [x] Tests: `frontend/test/core/files/file_writer_test.dart` covers the interrupted write, the full-disk failure and
      hash equality.
- [x] Tests: `frontend/test/core/files/file_relocation_test.dart` asserts files and rows agree after success, after a
      failed move and after a failed transaction, including the `_unfiled` promotion and the facility rename.
- [x] Tests: `frontend/test/core/files/thumbnail_cache_test.dart` counts decodes across two requests.
- [x] Tests: `frontend/test/core/files/compressed_copy_test.dart` compares the source hash before and after and asserts
      the size reduction.
- [x] Tests: `frontend/test/core/files/cache_cleanup_test.dart` prunes by age and by size against a fake clock and
      asserts nothing outside `.cache` is touched.
- [x] Tests: `frontend/test/core/files/storage_guard_test.dart` drives a fake free-space source across both thresholds,
      asserts one warning per session, the refusal at critical, completion of an in-flight save, and polling on resume
      and at session start rather than per shutter.
- [x] Tests: `frontend/test/core/files/orphan_scanner_test.dart` seeds a stray file, a row whose file was removed and a
      `.cache` entry that must be ignored, then asserts the report, the adoption path, the missing flag, the cancelled
      scan and that nothing is deleted.
- [x] Tests: `frontend/test/core/files/file_validation_test.dart` runs crafted inputs — mismatched magic bytes, empty
      file, oversized file, traversal zip, symlink entry, zip bomb declaration — and asserts one refusal each plus one
      passing case per supported kind.

### Follow-up work

#### Add share_plus for opening files externally

- [x] `share_plus` is in `pubspec.yaml` and `allowlist.yaml` at the same pin.
- [x] The dependency checker is green.

#### Open a project's files in an external app

- [x] Android and iOS open the system chooser with a copy.
- [x] Desktop opens the copy in the default handler.
- [x] The web downloads a copy and does not open a chooser.
- [x] The stored original is byte-identical after a hand-off and a cancel.
- [x] Cancelled, missing-handler and denied-permission paths show
      `AppErrorState` and leave no copy behind.
- [x] The item meets 48 dp, label and tooltip matchers.

#### Show storage volume totals and set the root

- [x] Storage shows total, used and available through `Copy.fileSize`, plus
      the ample, low or critical label.
- [x] A failed volume probe shows the error state with retry.
- [x] An empty root key still resolves through today's Documents fallback.
- [x] A saved writable folder is the path `resolve` returns after restart.
- [x] A failed write probe does not persist the path.
- [x] Web does not show the folder picker.
- [x] Tests cover the parser, the fake, the three figures and the path row.




## Follow-up absorbed from 330, 331, 335

### Add share_plus for opening files externally

`share_plus` is the one approved way to hand a file copy to the Android and iOS
system chooser. Features never import it; only `DownloadService` does.

Files:

- `frontend/pubspec.yaml`
- `frontend/tool/allowlist.yaml`

Constraints:

- One pinned version, a licence note, and a sentence on what it replaces
  (FE-FLOW-06).
- No feature calls the plugin (FE-STR-11).

### Open a project's files in an external app

A project's more menu offers Open with (Download a copy on the web), which hands
a cache copy of the imported template workbook or the newest export to another
app. The stored original is never passed out and never modified.

Files:

- `frontend/lib/core/files/download_service.dart`
- `frontend/lib/core/files/download_service_io.dart`
- `frontend/lib/core/files/download_service_web.dart`
- `frontend/lib/core/files/download_service_stub.dart`
- `frontend/lib/features/projects/data/project_openable_file_lookup.dart`
- `frontend/lib/features/projects/presentation/project_open_externally_action.dart`
- `frontend/lib/features/projects/presentation/project_list_view.dart`
- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/lib/core/copy/copy.dart`

Constraints:

- Hand out a copy in `.cache`; never the stored original's path (FE-SEC-08).
- Catalogue widgets only. Failure is a typed `Failure` through `AppErrorState`.
- Hide the item when there is no openable file and when the platform cannot
  hand a file off. Web shows Download a copy and uses `save`.
- `share_plus` is reached only from `DownloadService`.

### Show storage volume totals and set the root

Storage shows total, used and available bytes beside the headroom words, and
lets the operator choose the storage-root folder. Existing files stay where
they are.

Files:

- `frontend/lib/core/files/volume_stats.dart`
- `frontend/lib/core/files/storage_guard.dart`
- `frontend/lib/core/files/storage_root.dart`
- `frontend/lib/core/files/folder_picker.dart`
- `frontend/lib/core/files/folder_picker_io.dart`
- `frontend/lib/core/files/folder_picker_web.dart`
- `frontend/lib/core/files/folder_picker_stub.dart`
- `frontend/lib/features/settings/presentation/storage_settings_screen.dart`
- `frontend/lib/features/settings/domain/setting_keys.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/android/app/src/main/kotlin/com/tapture/app/MainActivity.kt`
- `frontend/test/core/files/volume_stats_test.dart`
- `frontend/test/core/files/storage_guard_test.dart`
- `frontend/test/core/files/storage_root_test.dart`
- `frontend/test/core/files/folder_picker_test.dart`
- `frontend/test/features/settings/presentation/storage_settings_screen_test.dart`

Constraints:

- Only `StorageGuard` and the existing files channel read the volume
  (FE-STR-11). No new package (FE-FLOW-06).
- A failed volume read is the error state, not ample (FE-STATE-11, FE-A11Y-05).
- The path is a preference, not a secret. Do not move or delete evidence
  (FE-SEC-01, FE-SEC-08).
- Tests never run `df` or PowerShell (FE-TEST-03).

## Out of scope

- Row-only integrity problems, which the database integrity check in 004 · Local database reports.
