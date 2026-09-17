# 207 — Export history, versioning and sharing

**Phase** 18 · Export  |  **Depends on** [005](../01-orchestration/005-dependency-allowlist.md), [060](../04-data-layer/060-exports-table.md), [066](../05-file-storage/066-project-folder-service.md), [205](205-zip-package.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Every export is recorded, lands in its own versioned dated folder that nothing later overwrites, and can be shared
again from history without being regenerated.

## Files

- `frontend/lib/features/exports/presentation/export_history_screen.dart` (new)
- `frontend/lib/features/exports/domain/export_versioning.dart` (new)
- `frontend/lib/features/exports/presentation/export_share_action.dart` (new)

## Contract

```dart
class ExportVersioning {
  /// Allocates the next `vN` directory for [projectId] under today's date; never reuses one.
  Future<Directory> allocate(String projectId, DateTime now);
}
```

## Steps

1. Store per export: timestamp, operator, formats, the resolved request and its filters, record count, output path and
   file hash; stamp every included record with `exportedAt`.
2. Allocate `v1`, `v2` and so on per project inside dated directories, so a repeated export never overwrites an
   earlier one.
3. Re-share from history by handing the recorded path to the system share sheet; regenerate nothing.
4. Show a missing file plainly when the recorded path has since been deleted, and offer to re-run the request instead.

## Constraints

- The share plug-in is the one allowed by 005 and is reached through a platform wrapper (FE-STR-11).

## Definition of done

- [ ] A user can explain, months later, exactly what a given file contained and who produced it.
- [ ] A new export never destroys a previous one, and folder names are stable and dated.
- [ ] Sharing from history reaches the system share sheet without rebuilding the file.
- [ ] Tests: widget tests of `export_history_screen.dart` and `export_share_action.dart` covering the four states and a missing file, plus unit tests of `export_versioning.dart` over repeated allocations on the same day, with no Flutter binding.
