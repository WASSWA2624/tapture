# 229 — Upload runner, progress and history

**Phase** 21 · Cloud upload  |  **Depends on** [024](../02-foundation/024-hashing-service.md), [060](../04-data-layer/060-exports-table.md), [228](228-upload-confirm.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Large archives transfer reliably with progress, cancel and resume, and every attempt leaves a history row showing
destination, file, size, timing and outcome. A failed transfer changes nothing locally and can be retried from that
history.

## Files

- `frontend/lib/features/cloud/domain/upload_runner.dart` (new)
- `frontend/lib/features/cloud/presentation/upload_history_screen.dart` (new)

## Contract

```dart
class UploadRunner {
  Stream<UploadProgress> start({required Destination to, required File file, required String remoteName});
  Future<Result<void>> cancel(String attemptId);
  Future<Result<void>> retry(String attemptId);
}
```

## Steps

1. Run the transfer through `runIsolate` (033), streaming byte progress to the UI and honouring the
   `CancellationToken`; a cancelled run completes with `CancelledFailure`.
2. Chunk files the backend supports chunking for, retry transient failures with exponential backoff and a cap, and
   resume from the last acknowledged offset rather than restarting.
3. Write the history row when the attempt starts and update it when it ends, into the export history (108), so a
   process killed mid-transfer leaves an interrupted row rather than no row.
4. Record destination, file path, byte size, start, end, result and failure reason; retry reuses the confirmed
   destination and file, and writes a new attempt row.
5. History screen lists attempts newest first, filterable by destination, with retry offered on failed and
   interrupted rows.

## Constraints

- Stream file bytes; never read an archive into memory to send it (FE-PERF-07).
- Retry re-enters through the confirmation sheet (425); the runner never sends unprompted.
- Failure reasons are the plain-language messages from the shared failures, not provider strings (FE-CONS-11).

## Definition of done

- [ ] A failed, cancelled or interrupted upload leaves the local file and database untouched and can be retried.
- [ ] Resume continues from the acknowledged offset, verified against a backend fake that accepts the first chunk then
      fails.
- [ ] Progress and cancel work on a file larger than available memory.
- [ ] Tests: unit tests of `upload_runner.dart` with no Flutter binding, covering backoff, resume-from-offset,
      cancellation and the interrupted-row case; widget test of `upload_history_screen.dart` over empty, populated and
      failed states.
