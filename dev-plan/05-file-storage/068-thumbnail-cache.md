# 068 — Derived image cache: thumbnails, compressed copies and cleanup

**Phase** 05 · File storage  |  **Depends on** [024](../02-foundation/024-hashing-service.md), [067](067-file-writer.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Everything that lives under `.cache`: thumbnails generated once per hash and size so lists never decode a full image,
reduced copies for online analysis, and the cleanup that keeps the folder bounded and disposable.

## Files

- `frontend/lib/core/files/thumbnail_cache.dart` (new)
- `frontend/lib/core/files/compressed_copy.dart` (new)
- `frontend/lib/core/files/cache_cleanup.dart` (new)

## Contract

```dart
abstract interface class ThumbnailCache {
  Future<Result<File>> thumbnail(String sha256, String sourcePath, {required int edge});
}

abstract interface class CompressedCopy {
  Future<Result<WrittenFile>> reduce(String sourcePath, {int? longEdge, int? quality});
}

abstract interface class CacheCleanup {
  Future<Result<int>> prune({Duration? maxAge, int? maxBytes});   // bytes reclaimed
}
```

## Steps

1. Generate thumbnails in an isolate on first request, key them `<sha256>_<edge>` under `.cache/thumbs/`, and cap
   concurrent decodes.
2. Serve a second request from disk without decoding the original again.
3. Reduce for upload to the configured long edge and quality in an isolate, write into `.cache/upload/` through the
   atomic writer, and return the path and byte length.
4. Prune by age then by total size, oldest first, on launch and on demand from settings; never touch anything outside
   `.cache`.
5. Regenerate transparently when a cache entry is missing, so deleting the folder costs only time.

## Constraints

- Originals are opened read-only: the source file's bytes and hash are identical before and after any derivation
  (FE-SEC-08, rule 1 of the standard).
- Decode, resize and hash run through the isolate runner, never on the UI thread (FE-PERF-02, FE-PERF-04).
- Edge sizes, quality, maximum age and maximum cache bytes come from `AppConstants` (FE-CODE-09).

## Definition of done

- [x] A tray of thirty photos scrolls within the FE-PERF-01 budget on a mid-range device, decoding no full image.
- [x] A repeated thumbnail request hits the cache and performs no decode.
- [x] The original's hash is unchanged after compression, and the reduced copy is smaller.
- [x] Deleting `.cache` entirely loses nothing but speed; the next request rebuilds what it needs.
- [x] Tests: `frontend/test/core/files/thumbnail_cache_test.dart` counts decodes across two requests;
      `compressed_copy_test.dart` compares the source hash before and after and asserts the size reduction;
      `cache_cleanup_test.dart` prunes by age and by size against a fake clock and asserts nothing outside `.cache` is
      touched.
