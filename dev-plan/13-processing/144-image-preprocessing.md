# 144 — Image preprocessing and on-device OCR

**Phase** 13 · Processing  |  **Depends on** [005](../01-orchestration/005-dependency-allowlist.md), [024](../02-foundation/024-hashing-service.md), [068](../05-file-storage/068-thumbnail-cache.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Derived copies prepared for extraction — resized, orientation-corrected, deskewed, contrast-improved, document
boundaries detected — and text read from them on the device, returning text, blocks and bounding boxes with the radio
off.

## Files

- `frontend/lib/features/processing/domain/image_preprocess.dart` (new)
- `frontend/lib/core/ai/ocr_service.dart` (new)

## Contract

```dart
class OcrBlock {
  const OcrBlock({required this.text, required this.bounds, required this.confidence});
  final String text;
  final Rect bounds;
  final double confidence;
}

abstract interface class OcrService {
  Future<OcrResult> recognise(String imagePath);
}
```

## Steps

1. Write preprocessed output beside the compressed copy of task 068 as a new derived file; never rewrite an original.
2. Run preprocessing and recognition through the isolate runner.
3. Add the recognition package to the dependency allowlist (task 005) before using it.

## Constraints

- Raw photos are append-only: preprocessing produces new files and leaves originals byte-identical (FE-SEC-08).
- Recognition makes no outbound call and works with the radio off (FE-SEC-03, FE-SEC-04).

## Definition of done

- [ ] Originals are byte-identical after preprocessing.
- [ ] A rating-plate photo yields readable text, blocks and bounding boxes offline.
- [ ] Tests: unit tests hashing an original before and after preprocessing; recognition test against a fixture image
      with known text, with the network disabled.
