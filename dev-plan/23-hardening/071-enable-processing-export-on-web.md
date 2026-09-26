# 071 — Enable processing, export and list thumbnails on web

**Phase** 23 · Hardening  |  **Depends on** [070](070-resolve-web-capture-caption-template-feedback.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Task 070 keeps capture's photo files in the browser: on web, `FileWriter` writes into the IndexedDB store
`AppConstants.projectFiles.storeName` through `BlobFileWriter`, and `FileReader` reads them back. The capture tray
draws its thumbnails from those bytes. Every other surface that opens a project file still reads through
`dart:io`, which has no browser implementation, so on web it fails or shows the missing-photo placeholder.

Move those readers onto `FileReader` so a browser can process, export and list what it captured:

- Processing: the prepare, on-device and online stages and the egress summary open photos, transcripts and
  audio through `File` (`features/processing/data/prepare_stage.dart`, `on_device_stage.dart`,
  `online_transcripts.dart`, `egress_summary.dart`, `photo_paths.dart`). They read bytes through `FileReader`
  and write derived files through `FileWriter`; on-device OCR stays unavailable on web and says so.
- Export: `features/exports/data/export_repository_impl.dart` reads photos and writes the archive through `File`.
  It reads through `FileReader`, and the finished file reaches the operator through `DownloadService`.
- Thumbnails: `core/files/thumbnail_cache.dart` writes cached files that `AppPhotoThumb` opens by path. On web the
  record-list thumbnail (`features/projects/presentation/record_thumb.dart`), the record page's photos and the
  project cover (`project_list_view.dart`) draw `PhotoAsset.thumbBytes` read through `FileReader`, decoded at
  thumbnail size (FE-PERF-04).

Native platforms keep their files, cache and paths unchanged.

## Files

- `frontend/lib/core/files/thumbnail_cache.dart`
- `frontend/lib/core/files/photo_thumbnails.dart`
- `frontend/lib/features/processing/data/prepare_stage.dart`
- `frontend/lib/features/processing/data/on_device_stage.dart`
- `frontend/lib/features/processing/data/online_transcripts.dart`
- `frontend/lib/features/processing/data/egress_summary.dart`
- `frontend/lib/features/processing/data/photo_paths.dart`
- `frontend/lib/features/exports/data/export_repository_impl.dart`
- `frontend/lib/features/projects/presentation/record_thumb.dart`
- `frontend/lib/features/projects/presentation/project_list_view.dart`
- `frontend/lib/main.dart`

## Definition of done

- [ ] On web, Save and process runs a captured record through processing without a file error.
- [ ] On web, an export of a project with photos downloads a file that holds those photos.
- [ ] On web, record rows, the record page and the project list show photo thumbnails decoded at thumbnail size.
- [ ] Android keeps its files, thumbnail cache and paths; every existing processing, export and thumbnail test
      still passes.
- [ ] Tests: processing stages, export and thumbnails over `BlobFileWriter` and `FileReader` with
      `BlobStore.memory`.
