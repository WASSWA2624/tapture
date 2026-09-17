# 199 — Photo columns and photo index sheet

**Phase** 18 · Export  |  **Depends on** [196](196-photo-naming-service.md), [197](197-xlsx-writer.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A workbook carries its photos in the mode the project chose — filename, relative path or embedded image — and always
carries a photo index sheet listing every photo, so photos stay traceable even in filename mode.

## Files

- `frontend/lib/core/export/xlsx_photo_refs.dart` (new)
- `frontend/lib/core/export/photo_index_sheet.dart` (new)

## Steps

1. Implement filename and relative path first; both come from `PhotoNaming`, never from the stored file path.
2. Embedding adjusts row height and reports the resulting file size growth; it changes no other column.
3. Write the index sheet with one row per photo: record, photo type, caption and path. Include it in every export,
   whatever the reference mode.

## Constraints

- Embedded images are downscaled from thumbnails, not full-resolution originals, so a large project still exports
  (FE-PERF-04).

## Definition of done

- [ ] Switching reference mode changes only the photo column; every other column is byte-identical.
- [ ] Every photo of every exported record appears exactly once on the index sheet, resolvable back to its file.
- [ ] Tests: unit tests of `xlsx_photo_refs.dart` over all three modes and of `photo_index_sheet.dart` asserting one row per photo including records with none.
