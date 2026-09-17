# 024 — Hashing service and isolate runner

**Phase** 02 · Foundation services  |  **Depends on** [021](021-result-and-failures.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Content hashing for file identity and duplicate detection, and the isolate wrapper that every heavy job — hashing
included — runs through with progress and cancellation.

## Files

- `frontend/lib/core/hash/hashing_service.dart` (new)
- `frontend/lib/core/concurrency/isolate_runner.dart` (new)

## Contract

```dart
Future<Result<String>> sha256OfFile(File f);  String sha256OfString(String s);
Future<Result<R>> runIsolate<M, R>(FutureOr<R> Function(M) task, M message, {void Function(double)? onProgress, CancellationToken? cancel});
```

## Steps

1. Stream the file in chunks so a large photo is never loaded whole into memory.
2. Wrap the isolate spawn, forward progress messages, honour cancellation and map a thrown error to a `Failure`.

## Constraints

- Hashing, copying and packaging read in chunks; nothing loads a 100MB file into memory (FE-PERF-07).
- No file input or output, hashing, decode or compression runs on the UI thread — it goes through `runIsolate` with progress and cancellation (FE-PERF-02).
- Cancellation and completion both release the isolate and its ports, leaving nothing behind (FE-STATE-09, FE-CODE-07).

## Definition of done

- [x] Hashing a hundred-megabyte file holds memory flat.
- [x] Cancelling mid-run completes with `CancelledFailure` and leaves no orphan isolate.
- [x] Tests: `frontend/test/core/hash/hashing_service_test.dart` uses known vectors and a large temporary file; `frontend/test/core/concurrency/isolate_runner_test.dart` covers success, progress, failure and cancellation.
