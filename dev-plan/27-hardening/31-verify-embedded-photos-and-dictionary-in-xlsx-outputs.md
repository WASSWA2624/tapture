# 135 — Verify embedded photos and dictionary in XLSX outputs

**Depends on** [018](../18-export.md), [132](../24-product-refinements.md)

## Implement

Complete the existing standard-workbook embedded-photo mode and data dictionary requirement (§49.2, §50.2).
Reuse the encoder's image support and captured template definitions. Filled source workbooks retain their original
sheet layout. Keep filename/relative-path modes, photo indexes, raw/refined columns and immutable originals intact.

## Files

- `frontend/lib/core/export/xlsx_writer.dart`, `frontend/lib/core/export/xlsx_sheet.dart`
- `frontend/lib/core/export/xlsx_image.dart`, `frontend/lib/core/export/xlsx_encoder.dart`
- `frontend/lib/features/exports/data/deliverable_renderer.dart`
- `frontend/test/core/export/xlsx_writer_test.dart`
- `frontend/test/features/exports/data/deliverable_renderer_test.dart`

## Definition of done

- [ ] Embedded mode produces actual image/drawing parts and row anchors for every included photo; another Office
      reader opens the workbook and resolves the images. Filename and path modes remain valid.
- [ ] When requested, the standard workbook's Data dictionary sheet describes every captured field/version,
      including types, units, options/codes and requiredness; `dictionary.json` remains consistent.
- [ ] Tests inspect real ZIP relationships/image parts and dictionary cells through an independent reader, verify
      cancellation and source immutability, and pass frontend analysis and relevant export guardrails.

## Evidence

- 2026-10-06: Task 132 integration review found that `XlsxWriter` selects the filename and increases row height
  for embedded mode but never populates `XlsxSheet.images`. The package emits `dictionary.json`, while the standard
  workbook omits its dictionary sheet. Both pre-existing format requirements remain open for final hardening.
