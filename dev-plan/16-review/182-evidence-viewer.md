# 182 — Evidence viewer

**Phase** 16 · Review  |  **Depends on** [127](../12-capture/127-photo-viewer.md), [155](../13-processing/155-evidence-linking.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Tapping a value opens the photo region, document page or transcript passage that produced it, with the region
highlighted and its source named.

## Files

- `frontend/lib/features/review/presentation/evidence_viewer.dart` (new)

## Steps

1. Read the evidence rows written by 287; highlight the bounding region on the photo, or show the whole photo where
   the provider supplied no region.
2. Show the OCR snippet or transcript passage beside the image, with the source label.
3. Open through the existing photo viewer of 228 rather than building a second viewer (FE-CONS-01).

## Definition of done

- [ ] Every value carrying an evidence link is checkable in two taps from the review screen.
- [ ] A value whose evidence is a whole photo shows that photo, not an empty highlight.
- [ ] Tests: widget test of `evidence_viewer.dart` covering a bounded region, the whole-photo fallback, a transcript
      passage, and its empty and failure states.
