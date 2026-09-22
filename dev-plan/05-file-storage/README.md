# 05 — File storage

The organised folder tree and every service that writes into it.

Task 005 (1). One prompt for the completed phase; the atomics it absorbed are listed in [RETIRED.md](../RETIRED.md).

- [x] [005 — File storage: the organised folder tree and every service that writes into it](005-file-storage.md)

## As built

The numbers below are the original atomics; they now live in task 005. Reproduce by implementing 065–071 in order. The tree that must exist at the end:

| Task | Public surface to reproduce |
| :--- | :--- |
| 065 | `StorageRoot` creates visible `Tapture/` and disposable `Tapture/.cache` under the documents directory, probes writability with a marker, memoises a successful resolve. Unwritable → `StorageFailure` with path + recovery; storage denial → `PermissionFailure`. |
| 066 | `sanitiseSegment` refuses traversal, absolute paths, drive prefixes, device names and empty results. `ProjectFolders` creates the eight-folder tree under `Tapture/projects/<name>__<id>` from stored `folderName` so a rename does not move files. `buildPhotoPath` covers byContext (plus `_unfiled` gaps), byTemplate, byCaptureDate and flat. |
| 067 | `FileWriter` streams to `<target>.part`, hashes in the same pass, flushes and renames. Stale `.part` files are swept, never resumed. `WrittenFile` lives in a `part` file. `FileRelocation` moves a record's photos then updates `relativePath` in one transaction and rolls files back on failure. |
| 068 | `ThumbnailCache` keys `<sha256>_<edge>` under `.cache/thumbs/`, caps concurrent decodes, serves a second request from disk. `CompressedCopy` writes a long-edge copy through `FileWriter` into `.cache/upload/` without changing the original hash. `CacheCleanup` prunes by age then size, oldest first, and never leaves `.cache`. |
| 069 | `StorageGuard` maps free bytes to `ample` / `low` / `critical` from `AppConstants.storage`. Polls on resume and `beginSession`, not per shutter. Warns once per low session; refuses a new capture at critical; an in-flight `completeSave` still finishes. |
| 070 | `OrphanScanner` pages a project tree, skips `.cache` and `.part`, reports files with no row and rows with no file. Adoption upserts photo/attachment with hash + merge columns; `flagMissing` audits and leaves the row. Cancel → `CancelledFailure`. `OrphanFile` / `MissingFile` / `OrphanReport` are `part` types. |
| 071 | `FileValidation` is the one import gate: extension allow-list, 64-byte magic sniff, per-kind size ceilings, ZIP central-directory walk for xlsx and bundles. Refusals quote the basename as data. |

Sources live under `frontend/lib/core/files/`. Tests use temp directories and fakes — never the real documents folder (FE-TEST-03). The status line and overflow menu (075) do not write files; they only navigate.
