# 055 — Photos, attachments and captions tables

**Phase** 04 · Local database  |  **Depends on** [054](054-records-table.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Metadata for every piece of captured media — photos, documents, audio clips — each carrying the content hash that gives
it merge identity, plus the captions table serving both records and photos with independently editable raw and refined
text.

## Files

- `frontend/lib/core/db/tables/photos.dart` (new)
- `frontend/lib/core/db/tables/attachments.dart` (new)
- `frontend/lib/core/db/tables/captions.dart` (new)

## Steps

1. Photos: `projectId`, `recordId` nullable for unfiled captures, `captureSessionId`, `originalFilename`,
   `storedFilename`, `relativePath`, `photoType`, `sortOrder`, `width`, `height`, `fileSize`, `mimeType`, `sha256`,
   `capturedAt`, `gpsLat`, `gpsLon`.
2. Unique index on `projectId` plus `sha256`, so re-importing the same image cannot create a second row.
3. Attachments: the same identity columns — `relativePath`, `mimeType`, `fileSize`, `sha256` — plus `kind` for document
   or audio, `durationMs` for audio and `pageCount` for documents; unique on `projectId` plus `sha256`.
4. Captions: `ownerType` as record or photo, `ownerId`, `textRaw`, `textRefined`, `inputMode` as typed or spoken,
   `refinedAt`; index on `ownerType` plus `ownerId`.
5. Applying one caption to several photos writes one caption row per photo, in one transaction; no shared row.

## Constraints

- All three tables declare the shared merge columns through `MergeColumns` in the migration that creates them; merge
  matches media on `sha256` and captions on `rev` (FE-SEC-09).
- `textRaw`, `capturedAt` and `sha256` are written once at creation; refinement writes `textRefined` only (FE-SEC-08).
- `relativePath` stays relative to the project folder so the tree survives a move of the storage root.
- GPS columns are nullable and stay null unless the project has location recording enabled (FE-SEC-07).

## Definition of done

- [x] Importing the same file twice into one project is refused by the unique hash index, not by application code.
- [x] Applying one caption to thirty photos writes thirty rows and leaves each independently editable.
- [x] Refining a caption leaves `textRaw` unchanged.
- [x] Tests: `frontend/test/core/db/tables/photos_test.dart` asserts hash uniqueness per project and unfiled capture
      with a null `recordId`; `attachments_test.dart` covers the document and audio variants; `captions_test.dart`
      asserts the many-photo write and raw immutability. All against an in-memory database, covering their migration
      steps.
