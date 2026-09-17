# 145 — OCR cache and perceptual image hashing

**Phase** 13 · Processing  |  **Depends on** [024](../02-foundation/024-hashing-service.md), [057](../04-data-layer/057-jobs-table.md), [144](144-image-preprocessing.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

OCR output cached by image hash so no photo is ever recognised or uploaded twice, and a perceptual hash with a
distance function so a resized or recompressed copy of a photo counts as the same photo.

## Files

- `frontend/lib/features/processing/data/ocr_cache.dart` (new)
- `frontend/lib/core/hash/perceptual_hash.dart` (new)

## Steps

1. Key the cache on the content hash from task 024; store text, blocks and bounding boxes against it.
2. Compute a difference hash and expose a distance function with the threshold read from `AppConstants`.
3. Treat a perceptual match inside the threshold as a cache hit, so a re-encoded photo reuses the stored result.
4. Hash and look up off the UI thread through the isolate runner (FE-PERF-02).

## Definition of done

- [ ] Reprocessing a record reuses stored OCR text and performs no recognition and no upload.
- [ ] A resized or recompressed copy of a photo matches; an unrelated photo does not.
- [ ] Tests: repository tests for `ocr_cache.dart` against an in-memory database, plus the fake later tests use; unit
      tests of the distance function over resized, recompressed and unrelated images.
