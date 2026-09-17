# 066 — Project folder tree, name sanitiser and photo path builder

**Phase** 05 · File storage  |  **Depends on** [052](../04-data-layer/052-projects-table.md), [065](065-storage-root.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Everything that decides where a file lives: arbitrary user text turned into a safe name, the per-project folder tree
created from it, and the photo sub-path composed from the context hierarchy in force.

## Files

- `frontend/lib/core/files/path_sanitizer.dart` (new)
- `frontend/lib/core/files/project_folders.dart` (new)
- `frontend/lib/core/files/photo_path_builder.dart` (new)

## Contract

```dart
String sanitiseSegment(String input, {int maxLength = kMaxPathSegment});

abstract interface class ProjectFolders {
  Future<Result<Directory>> create(Project project);   // idempotent
  Future<Result<Directory>> resolve(Project project);
}

enum PhotoFolderStrategy { byContext, byTemplate, byCaptureDate, flat }

String buildPhotoPath({
  required PhotoFolderStrategy strategy,
  required List<String> contextValues,
  DateTime? capturedAt,
  String? templateName,
});
```

## Steps

1. Sanitise by stripping accents, replacing whitespace with hyphens, removing reserved and non-printing characters,
   upper-casing where the specification requires it, capping length, and appending a numeric suffix on collision.
2. Reject `..`, absolute paths, drive prefixes, device names and empty results outright, as failures, never as silent
   substitutions.
3. Derive the project folder name from the sanitised project name plus a short id suffix, store it in
   `projects.folderName`, and always resolve from the stored value so a rename never moves existing files.
4. Create `photos/`, `documents/`, `audio/`, `meetings/`, `reference/`, `templates/`, `exports/`, `imports/` on project
   creation, idempotently.
5. Compose `photos/<level1>/<level2>/<level3>/` from sanitised context values, falling back to `_unfiled` for any level
   not yet set, and implement the by-template, by-capture-date and flat strategies against the same interface.

## Constraints

- Traversal is refused before a path is used, not after (FE-SEC-06).
- Length caps, the suffix length and the strategy default come from `AppConstants`, not from literals at the call site
  (FE-CODE-09).
- The builder is pure and synchronous: it composes a relative path and never touches the filesystem (FE-PERF-02).

## Definition of done

- [ ] A project named with slashes, emoji, accents or 300 characters still produces one valid folder, and two projects
      with the same name produce distinct folders.
- [ ] Renaming a project changes nothing on disk and breaks no stored `relativePath`.
- [ ] The tree produced for a fully set context matches the specification's example path exactly, and an unset level
      lands under `_unfiled`.
- [ ] Tests: `frontend/test/core/files/path_sanitizer_test.dart` runs a table of hostile inputs including traversal and
      reserved names; `project_folders_test.dart` asserts idempotent tree creation and rename safety in a temporary
      directory; `photo_path_builder_test.dart` covers all four strategies and every partially set context.
