# 066 — Resolve project, capture and export feedback

**Phase** 23 · Hardening  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Close the 24 September 2026 feedback archive using its defaults: export copies use `PROJECT-NAME-DDMMYY-HHMMSS.xlsx` under `Tapture/Exports`, screen titles follow the active page, capture photos and actions match the reports, and the project home lists captured items beside the existing hub.

The executable prompt is `prompts/feedback-24092026-2143/001-resolve-project-capture-feedback.md`. Decisions D1–D7 use the defaults in that prompt.

## Files

- `frontend/lib/core/files/download_service.dart`
- `frontend/lib/core/files/download_service_io.dart`
- `frontend/lib/features/exports/domain/export_file_name.dart`
- `frontend/lib/features/projects/presentation/project_export_screen.dart`
- `frontend/lib/features/capture/presentation/capture_screen.dart`
- `frontend/lib/features/capture/presentation/photo_tray.dart`
- `frontend/lib/features/context/presentation/context_hierarchy_screen.dart`
- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/lib/features/projects/presentation/captured_items.dart`
- `frontend/lib/features/templates/presentation/template_list_screen.dart`
- `frontend/lib/features/templates/presentation/field_list_screen.dart`
- `frontend/android/app/src/main/kotlin/com/tapture/app/MainActivity.kt`

## Definition of done

- [x] Export display names are `PROJECT-NAME-DDMMYY-HHMMSS.xlsx`, and a copy is written under `Tapture/Exports` without moving feedback downloads.
- [x] Create project, Capture, Project templates, and Project contexts are the active-page titles. The projects-list Show archived menu stays on that list.
- [x] Capture thumbnails open the photo, remove a draft, and caption one photo or the selection.
- [x] Save actions and the add-photo actions are stacked and full width.
- [x] Context levels can share an order, and pinned fields open from the project home.
- [x] The project home lists captured items, switches templates, and archives instead of deleting photos.
- [x] Tests: export name, download subfolder, status-line titles, photo tray, shared context level, and the project home.
