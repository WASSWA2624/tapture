# 021 — Cloud upload: a destination the user chooses, never a sync channel

**Phase** 21 · Cloud upload  |  **Depends on** [001](../01-orchestration/001-project-setup.md), [002](../02-foundation/002-foundation-services.md), [003](../03-design-system/003-design-system.md), [004](../04-data-layer/004-local-database.md), [005](../05-file-storage/005-file-storage.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Somewhere for a finished file to go, chosen and started by a person every time. One `CloudDestination` interface with a
registry that resolves a backend by kind, the persisted destination row carrying kind, label, folder and a credential
reference, and the repository that watches, saves and removes those rows, with the credential value itself living only
in secure storage. Six backends behind that one interface: an S3-compatible bucket with user-supplied keys and
multipart upload, a WebDAV or generic HTTPS endpoint with basic or bearer authentication, a folder on the device or an
SD card held as a persisted picker grant, and Google Drive, OneDrive and Dropbox each signed in with the user's own
account over one shared authorisation-code-with-PKCE flow rather than three. One screen listing every configured
destination with add, edit, connection test and removal, where removing takes the row and its secret together and a
configuration cannot be saved until its test upload succeeds. The confirmation sheet that stands between a file and the
network, naming the file, its size, the destination and the remote folder, with confirm and cancel as its only answers.
And the runner that moves a large archive through an isolate with progress, cancellation, chunked retry with backoff
and resume from the last acknowledged offset, writing an attempt row when the transfer starts and closing it when it
ends, beside the history screen that lists those attempts newest first and offers retry on the failed and interrupted
ones. Nothing here uploads by itself.

## Files

The abstraction and every backend, all under `core/cloud/`:

- `frontend/lib/core/cloud/cloud_destination.dart` (new)
- `frontend/lib/core/cloud/s3_destination.dart` (new)
- `frontend/lib/core/cloud/webdav_destination.dart` (new)
- `frontend/lib/core/cloud/local_destination.dart` (new)
- `frontend/lib/core/cloud/oauth_destination_client.dart` (new)
- `frontend/lib/core/cloud/google_drive_destination.dart` (new)
- `frontend/lib/core/cloud/onedrive_destination.dart` (new)
- `frontend/lib/core/cloud/dropbox_destination.dart` (new)

Persistence and domain:

- `frontend/lib/core/db/tables/destinations.dart` (new)
- `frontend/lib/features/cloud/domain/destination_repository.dart` (new)
- `frontend/lib/features/cloud/domain/upload_runner.dart` (new)

Screens and actions:

- `frontend/lib/features/cloud/presentation/destination_list_screen.dart` (new)
- `frontend/lib/features/cloud/presentation/destination_remove_action.dart` (new)
- `frontend/lib/features/cloud/presentation/upload_confirm_sheet.dart` (new)
- `frontend/lib/features/cloud/presentation/upload_history_screen.dart` (new)

## Contract

```dart
enum DestinationKind { s3, googleDrive, oneDrive, dropbox, webdav, localFolder }

class Destination {
  const Destination({required this.id, required this.kind, required this.label, required this.folder,
      required this.credentialRef});
  final String id; final DestinationKind kind; final String label; final String folder; final String credentialRef;
}

abstract interface class CloudDestination {
  DestinationKind get kind;
  Future<Result<void>> check(Destination d);
  Future<Result<Uri>> send(Destination d, File file, {required String remoteName, int offset = 0,
      void Function(int sent, int total)? onProgress, CancellationToken? cancel});
}

abstract interface class DestinationRepository {
  Stream<List<Destination>> watchAll();
  Future<Result<void>> save(Destination d);
  Future<Result<void>> remove(String id);
}

class UploadRunner {
  Stream<UploadProgress> start({required Destination to, required File file, required String remoteName});
  Future<Result<void>> cancel(String attemptId);
  Future<Result<void>> retry(String attemptId);
}
```

## Steps

1. Deliver the interface, the table and the repository first; every backend and the runner are written against them.
   Resolve backends by `kind` through one registry map, so adding a backend is one entry rather than a branch at every
   call site. Write only `credentialRef` to the destinations table; the value goes to secure storage under its
   `SecretKey` entry ([002](../02-foundation/002-foundation-services.md)). The repository takes its shape from the
   interfaces of [004](../04-data-layer/004-local-database.md). `send` reports progress, accepts a starting
   `offset` and honours cancellation, so the runner of step 6 can resume a part-sent file. `remove` deletes the row and
   its secret in one operation, leaving neither an orphan row nor an orphan credential.
2. Build the destinations screen over that repository. Each row is the `AppListTile` of
   [003](../03-design-system/003-design-system.md), showing kind, label, folder and the outcome of the last connection
   check. Add and edit collect the backend's fields, write the credential to secure storage and the row through
   `DestinationRepository`, and refuse to save until `CloudDestination.check` succeeds. Removal asks once, then deletes
   row and secret through `DestinationRepository.remove`; a partial failure reports which half remains rather than
   reporting success.
3. Write the three backends that need no OAuth. S3 fields are access key, secret, region, bucket, optional prefix and
   optional endpoint; sign requests for the configured endpoint so non-AWS stores work, and support multipart upload
   for large files. WebDAV fields are a base URL plus basic or bearer credentials; `PUT` the object, creating the
   collection when absent, and treat a redirect to a different host as a failure rather than following it. The local
   folder backend holds the picker's persisted directory grant, resolves paths through the storage root of
   [005](../05-file-storage/005-file-storage.md), and writes through a temporary name then renames, so an interruption
   leaves no partial file. Each backend's `check` writes then deletes a small probe object, so a wrong key, bucket, URL
   or revoked folder grant is caught before a real upload. Map provider errors onto the shared failures: unreachable
   and 5xx are retryable, 401/403 and a missing bucket are not.
4. Add the three consumer providers over one shared client. Write the authorisation-code-with-PKCE flow, token exchange
   and refresh once in `oauth_destination_client.dart`; Drive, OneDrive and Dropbox supply only endpoints, scope names,
   the folder picker call and the upload call. Request the narrowest scope that permits creating files in the chosen
   folder — never a read-all scope, never account-wide metadata. Store access and refresh tokens in secure storage
   under the destination's entry; on a 401, refresh once and retry, and if refresh fails, surface a re-authorisation
   prompt and leave the destination configured. Upload through each provider's resumable endpoint, reporting progress
   and accepting a starting offset so the runner can continue an interrupted transfer.
5. Put the confirmation sheet in place before any send path exists to bypass it. Show the file name, the byte size
   through the shared formatter, the destination label and the full remote folder path. Offer confirm and cancel
   only — no "remember this", no "always allow", no per-destination blanket consent. Cancel returns before any
   request is constructed and before any credential is read. Route the sheet through the dialog service of
   [003](../03-design-system/003-design-system.md) so a caller cannot bypass it by building its own dialog.
6. Finish with the runner and its history. Run the transfer through `runIsolate`
   ([002](../02-foundation/002-foundation-services.md)), streaming byte progress to the interface and honouring the
   `CancellationToken`; a cancelled run completes with `CancelledFailure`. Chunk files the backend supports chunking
   for, retry transient failures with exponential backoff and a cap, and resume from the last acknowledged offset
   rather than restarting. Write the history row when the attempt starts and update it when it ends, into the export
   history held by the exports table of [004](../04-data-layer/004-local-database.md), so a process killed mid-transfer
   leaves an interrupted row rather than no row. Record destination, file path, byte size, start, end, result and
   failure reason; a retry reuses the confirmed destination and file and writes a new attempt row. The history screen
   lists attempts newest first, filterable by destination, with retry offered on failed and interrupted rows.

## Constraints

- Upload is never automatic. There is no schedule, no background trigger and no sync channel anywhere in this phase;
  every transfer begins with a person confirming that transfer (rule 6 of the standard, FE-SIMP-07).
- Every send path calls the confirmation sheet; a caller reaching `CloudDestination.send` without a confirmation result
  is a defect (FE-SEC-03). A retry re-enters through the same sheet, so the runner never sends unprompted.
- One decision on the sheet, with the destination already chosen (FE-SIMP-07).
- Networking imports and HTTP clients stay under `core/cloud/`; nothing in `features/` holds a client (FE-SEC-03).
- No credential value reaches the database, logs, preferences, exports or bundles. Tokens never leave secure storage,
  never enter a log line and never appear in a failure message; credential fields are obscured and never echoed back
  into the form after saving (FE-SEC-01).
- Each call reads its credential from secure storage rather than caching it in a field (FE-SEC-01, FE-SEC-03).
- `destination_repository.dart` stays pure Dart with no Drift type in its signatures (FE-STR-05, FE-STATE-05).
- The destinations screen renders all four states, including a destination whose check last failed (FE-CONS-04).
- A signing, WebDAV, picker, OAuth or provider package goes through the dependency allowlist of
  [001](../01-orchestration/001-project-setup.md) before it is added. The OAuth redirect scheme is registered
  per platform, not hardcoded in Dart (FE-CODE-09).
- The folder backend makes no network call at all (FE-PERF-07).
- Stream file bytes; never read an archive into memory to send it (FE-PERF-07).
- Failure reasons are the plain-language messages from the shared failures, not provider strings (FE-CONS-11).

## Definition of done

- [ ] A destination round-trips through the repository with no credential value anywhere in the database or logs.
- [ ] A `DestinationKind` with no registered backend fails at resolution with a named failure, not a null.
- [ ] Tests: `frontend/test/core/cloud/cloud_destination_test.dart` asserts the persisted row holds only
      `credentialRef`, that the registry resolves every kind, and that `remove` clears row and secret together.
- [ ] A destination can be added, renamed, tested and removed without leaving the screen, and a configuration that
      fails its check cannot be saved.
- [ ] After removal, secure storage holds no entry for that destination and re-adding the same label starts with no
      credential; a half-completed removal says which half remains instead of reporting success.
- [ ] Tests: widget test of `destination_list_screen.dart` over empty, populated, loading and failed-check states.
- [ ] Tests: test asserting secure storage no longer holds the entry after `destination_remove_action.dart` runs.
- [ ] A test upload of a small file proves each configuration before any real upload is offered.
- [ ] The folder destination completes with the device fully offline, and works on removable storage.
- [ ] A cancelled or failed send leaves no partial object at the destination and no partial file in the folder.
- [ ] Tests: unit tests of `s3_destination.dart`, `webdav_destination.dart` and `local_destination.dart` against fakes,
      covering signature and auth headers, multipart resume from an offset, retryable versus fatal failures, and
      cancellation.
- [ ] The app never reads the user's other Drive, OneDrive or Dropbox content; only the folder it was given and the
      files it created there.
- [ ] An expired token refreshes silently without the user re-picking the folder; a revoked token asks for
      re-authorisation without losing the destination.
- [ ] Tests: unit tests of `google_drive_destination.dart`, `onedrive_destination.dart` and `dropbox_destination.dart`
      against fakes.
- [ ] Tests: a test asserting the requested scope string for each provider.
- [ ] Tests: a refresh-then-retry and a refresh-failure test on `oauth_destination_client.dart`.
- [ ] No bytes leave the device without the confirmation sheet being confirmed, including retries of a failed upload.
- [ ] No setting anywhere suppresses the sheet, and a second upload of the same file asks again.
- [ ] Tests: widget test asserting cancel performs no request and reads no credential.
- [ ] Tests: test asserting a repeat upload of the same file to the same destination prompts a second time.
- [ ] A failed, cancelled or interrupted upload leaves the local file and database untouched and can be retried.
- [ ] Resume continues from the acknowledged offset, verified against a backend fake that accepts the first chunk then
      fails.
- [ ] Progress and cancel work on a file larger than available memory.
- [ ] An attempt row exists from the moment the transfer starts, so a process killed mid-transfer leaves an interrupted
      row rather than no row.
- [ ] A history row names destination, file, byte size, start, end, outcome and failure reason, and a retry writes a
      new attempt row rather than overwriting the old one.
- [ ] History lists attempts newest first, filters by destination, and offers retry on failed and interrupted rows
      only.
- [ ] Tests: unit tests of `upload_runner.dart` with no Flutter binding, covering backoff, resume-from-offset,
      cancellation and the interrupted-row case.
- [ ] Tests: widget test of `upload_history_screen.dart` over empty, populated and failed states.

## Out of scope

- Any form of automatic, scheduled or background upload; this phase has no sync channel.
- Sending anything to the server: a destination is storage the user owns, and the optional change relay of
  24 · The minimal backend is a different channel, built there.
