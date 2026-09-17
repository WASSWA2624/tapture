# 205 — ZIP data package and manifest

**Phase** 18 · Export  |  **Depends on** [005](../01-orchestration/005-dependency-allowlist.md), [197](197-xlsx-writer.md), [200](200-csv-writer.md), [202](202-pdf-record-report.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One archive holding the chosen outputs, the photos, the attached documents and a manifest that maps every exported
record to its output row and photo paths, so the package explains itself years later.

## Files

- `frontend/lib/core/export/zip_package.dart` (new)
- `frontend/lib/core/export/export_manifest.dart` (new)

## Contract

```dart
class ExportManifest {
  const ExportManifest({
    required this.exportId,
    required this.createdAt,
    required this.request,
    required this.entries,
  });
  Map<String, Object?> toJson();
}

class ManifestEntry {
  const ManifestEntry(this.recordId, this.recordNumber, this.sheet, this.row, this.photoPaths);
}
```

## Steps

1. Lay the archive out exactly as the specification shows, and add each entry as a stream rather than reading files
   into memory.
2. Write the manifest last, once every output path and row index is known.
3. Match the specification's manifest example field for field, including the request that produced it.

## Constraints

- The archive package is the one allowed by 005; entries stream in and out (FE-PERF-07).

## Definition of done

- [ ] A four-hundred-megabyte package builds without memory exceeding its baseline budget.
- [ ] Extracting the archive reproduces the documented folder layout exactly.
- [ ] Every exported record appears once in the manifest with its sheet, row and photo paths.
- [ ] Tests: unit tests of `zip_package.dart` asserting archive layout after extraction with a measured memory assertion, and a schema test of the manifest produced by `export_manifest.dart`.
