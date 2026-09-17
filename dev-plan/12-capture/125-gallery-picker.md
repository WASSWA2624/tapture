# 125 — Import photos, documents and PDF pages

**Phase** 12 · Capture  |  **Depends on** [024](../02-foundation/024-hashing-service.md), [055](../04-data-layer/055-photos-table.md), [071](../05-file-storage/071-file-validation.md), [120](120-capture-session-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Three import paths into the session: multi-select of existing images copied into the project tree, attachment of PDFs
and other files as documents, and lazy rendering of each PDF page so OCR and review can treat pages like photos.

## Files

- `frontend/lib/features/capture/presentation/gallery_picker.dart` (new)
- `frontend/lib/features/capture/presentation/document_picker.dart` (new)
- `frontend/lib/core/import/pdf_pages.dart` (new)

## Steps

1. Validate extension, magic bytes, size and structure before reading anything (126); a rejected file names its reason.
2. Copy rather than reference, and keep the original filename in metadata.
3. Write documents into `documents/` with their page count where the format reports one (100).
4. Render PDF pages lazily into `.cache` at a readable resolution in the isolate runner (033); the source PDF is never
   modified.

## Constraints

- Validation precedes every read, and archives are never expanded here (FE-SEC-06).
- Copying, hashing and rendering stream in chunks; nothing loads a whole file into memory (FE-PERF-07).
- Imported filenames are data, never interpolated into a path or a command (FE-SEC-05).

## Definition of done

- [ ] Deleting the photo from the device gallery afterwards does not affect the record.
- [ ] A rejected file names the reason and leaves the session unchanged.
- [ ] A twenty-page document does not stall the interface.
- [ ] Tests: widget tests of `gallery_picker.dart` and `document_picker.dart` covering multi-select, an oversized file, a wrong extension and a mismatched magic-byte file; unit test of `pdf_pages.dart` against a multi-page fixture asserting lazy rendering and an unmodified source.

## Out of scope

- Reading the rendered pages. Page images are produced here; OCR over them belongs to phase 13 · Processing.
- Spreadsheet and bundle import, which belong to phase 20 · Data import.
