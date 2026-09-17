# 208 — Bundle format, manifest and writer

**Phase** 19 · Bundles and merge  |  **Depends on** [061](../04-data-layer/061-merge-tables.md), [193](../18-export/193-export-model.md), [205](../18-export/205-zip-package.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The bundle: a declared archive layout with a versioned manifest and lineage record, and the writer that produces one by
streaming every entity table and every file into it with a checksum per entry.

## Files

- `frontend/lib/core/bundle/bundle_format.dart` (new)
- `frontend/lib/core/bundle/bundle_writer.dart` (new)

## Contract

```dart
class BundleManifest {
  const BundleManifest({
    required this.formatVersion,
    required this.bundleId,
    required this.projectId,
    required this.sourceDeviceId,
    required this.createdAt,
    required this.versionVectors,
    required this.lineage,
    required this.entries,
  });
  factory BundleManifest.fromJson(Map<String, Object?> json);
  Map<String, Object?> toJson();
}

class BundleEntry {
  const BundleEntry(this.path, this.bytes, this.sha256);
}

class BundleWriter {
  Stream<double> write({
    required File target,
    required BundleScope scope,
    required CancellationToken token,
  });
}
```

## Steps

1. Declare the file list, the manifest schema, the format version and the lineage record — which devices the project
   has already passed through — in `bundle_format.dart`, so reader and writer share one definition.
2. Serialise every entity table plus the files they reference, streaming each entry and hashing it as it is written.
3. Carry the current version vectors of 110 into the manifest; a bundle without them cannot be merged.

## Constraints

- Entries stream in; no table or photo is materialised whole in memory (FE-PERF-07).
- The format version is compared, never inferred: a reader must be able to refuse a newer bundle (FE-SEC-06).

## Definition of done

- [ ] The written layout matches the specification file for file, manifest field for field.
- [ ] A bundle containing two thousand photos writes without memory exceeding its baseline budget.
- [ ] Every entry carries a checksum, and the manifest carries the version vectors and lineage.
- [ ] Tests: schema test of a written manifest, a round-trip test writing then re-reading a seeded project, and a measured memory assertion for the two-thousand-photo case.
