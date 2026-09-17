# 201 — PDF engine and shared layout

**Phase** 18 · Export  |  **Depends on** [005](../01-orchestration/005-dependency-allowlist.md), [024](../02-foundation/024-hashing-service.md), [030](../03-design-system/030-color-tokens.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One PDF foundation every report builds on: cover page, running header, footer with page numbers, and the photo block
used wherever photos appear. Rendering happens on an isolate with progress and cancellation.

## Files

- `frontend/lib/core/export/pdf/pdf_engine.dart` (new)

## Contract

```dart
class PdfEngine {
  const PdfEngine(this.tokens);
  PdfDocumentBuilder document({required PdfCover cover, required PdfRunningHeader header});
  /// Photo grid used by every report; [columns] is 1 for full-size, 2..4 for thumbnails.
  PdfBlock photoBlock(List<ExportPhoto> photos, {required int columns, bool captions = true});
  /// Renders on the isolate runner of 033; emits 0..1 progress.
  Stream<double> render(PdfDocumentBuilder builder, File target, CancellationToken token);
}
```

## Steps

1. Take every size, weight and spacing value from the type scale and spacing tokens, so reports look like the app.
2. Number pages as `n of m` in the footer, and repeat the project and report name in the header of every page.
3. Expose cover slots that a report fills with its own totals, rather than each report drawing its own cover.

## Constraints

- Styles come from tokens only; no report declares a font size or colour of its own (FE-THEME-01, FE-THEME-11).
- The PDF package is the one allowed by 005; the UI thread renders no page (FE-PERF-02).

## Definition of done

- [ ] Every report can be built from cover, header, footer and photo block without adding layout of its own.
- [ ] A cancelled render leaves no partial file.
- [ ] Tests: golden test of a rendered cover and body page through `pdf_engine.dart`, plus a unit test that cancellation deletes the target file.
