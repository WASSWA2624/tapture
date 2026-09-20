# 331 — Open a project's files in an external app

**Phase** 05 · File storage  |  **Depends on** [330](330-add-share-plus.md), [066](066-project-folder-service.md), [329](../08-projects/329-add-project-list-actions.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A project's more menu offers Open with (Download a copy on the web), which hands
a cache copy of the imported template workbook or the newest export to another
app. The stored original is never passed out and never modified.

## Files

- `frontend/lib/core/files/download_service.dart`
- `frontend/lib/core/files/download_service_io.dart`
- `frontend/lib/core/files/download_service_web.dart`
- `frontend/lib/core/files/download_service_stub.dart`
- `frontend/lib/features/projects/data/project_openable_file_lookup.dart`
- `frontend/lib/features/projects/presentation/project_open_externally_action.dart`
- `frontend/lib/features/projects/presentation/project_list_view.dart`
- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/lib/core/copy/copy.dart`

## Constraints

- Hand out a copy in `.cache`; never the stored original's path (FE-SEC-08).
- Catalogue widgets only. Failure is a typed `Failure` through `AppErrorState`.
- Hide the item when there is no openable file and when the platform cannot
  hand a file off. Web shows Download a copy and uses `save`.
- `share_plus` is reached only from `DownloadService`.

## Definition of done

- [x] Android and iOS open the system chooser with a copy.
- [x] Desktop opens the copy in the default handler.
- [x] The web downloads a copy and does not open a chooser.
- [x] The stored original is byte-identical after a hand-off and a cancel.
- [x] Cancelled, missing-handler and denied-permission paths show
      `AppErrorState` and leave no copy behind.
- [x] The item meets 48 dp, label and tooltip matchers.
