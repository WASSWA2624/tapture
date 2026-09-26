# 068 — Resolve project, record, capture and export feedback

**Phase** 23 · Hardening  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Close the 25 September 2026 21:20 feedback archive (FBK0000132–FBK0000142, FBK0000144) using the defaults of
its decisions D1–D8. An open keyboard no longer collapses shell pages and sheets. Record rows show their photo,
and template rows count their records. The project home holds only the record search and the records list. A
record opens on its own page and is edited on the capture page. On capture, photos are ticked with a checkbox,
a caption goes to the ticked photos (to all when none is ticked), each photo's caption is edited in its preview,
and Save and process waits for a network. The export page summarises the project and sends the file to other
apps. A new template takes several fields at once.

The executable prompt is `prompts/feedback-25092026-2120/001-resolve-project-record-capture-export-feedback.md`.
Decisions D1–D8 use the defaults in that prompt: (a) in every case.

## Files

- `frontend/lib/app/nav_shell.dart`
- `frontend/lib/app/router.dart`
- `frontend/lib/app/route_paths.dart`
- `frontend/lib/app/shell_title.dart`
- `frontend/lib/main.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/core/files/photo_thumbnails.dart`
- `frontend/lib/core/files/download_service.dart`
- `frontend/lib/core/files/download_service_io.dart`
- `frontend/lib/core/files/download_service_web.dart`
- `frontend/lib/core/network/offline_now.dart`
- `frontend/lib/core/widgets/app_photo_thumb.dart`
- `frontend/lib/core/widgets/fields/app_choice_field.dart`
- `frontend/lib/features/projects/domain/project_repository.dart`
- `frontend/lib/features/projects/data/project_repository_impl.dart`
- `frontend/lib/features/projects/projects.dart`
- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/lib/features/projects/presentation/captured_items.dart`
- `frontend/lib/features/projects/presentation/project_records_screen.dart`
- `frontend/lib/features/projects/presentation/record_detail_screen.dart`
- `frontend/lib/features/projects/presentation/record_edit_sheet.dart`
- `frontend/lib/features/projects/presentation/project_export_screen.dart`
- `frontend/lib/features/projects/presentation/export_summary_view.dart`
- `frontend/lib/features/exports/domain/export_repository.dart`
- `frontend/lib/features/exports/domain/export_summary.dart`
- `frontend/lib/features/exports/data/export_repository_impl.dart`
- `frontend/lib/features/templates/presentation/template_list_screen.dart`
- `frontend/lib/features/templates/presentation/template_create_screen.dart`
- `frontend/lib/features/templates/presentation/template_field_rows.dart`
- `frontend/lib/features/capture/domain/caption_apply.dart`
- `frontend/lib/features/capture/domain/capture_session.dart`
- `frontend/lib/features/capture/domain/capture_session_key.dart`
- `frontend/lib/features/capture/domain/capture_persistence.dart`
- `frontend/lib/features/capture/domain/capture_record_persistence.dart`
- `frontend/lib/features/capture/data/capture_record_writer.dart`
- `frontend/lib/features/capture/data/drift_capture_persistence.dart`
- `frontend/lib/features/capture/presentation/capture_controller.dart`
- `frontend/lib/features/capture/presentation/capture_screen.dart`
- `frontend/lib/features/capture/presentation/photo_tray.dart`
- `frontend/lib/features/capture/presentation/photo_viewer_screen.dart`

## Definition of done

- [x] With the keyboard open, a shell page shows its search field, part of its list and its footer, at every width and in both orientations, and a choice sheet keeps its options visible above the keyboard.
- [x] A record with a photo shows that photo, turned the way it was saved; a cropped photo shows its cropped version; a removed photo is never the thumbnail; a missing file shows Missing photo.
- [x] Each template row shows how many live records use it, and Delete is offered only for a template with no records.
- [x] The project home shows the search field and the records list only; no count-card symbol remains; Templates and Project contexts open from the menu.
- [x] The home search reads "Search records", and a query with no match names the query, on the home and in every choice sheet.
- [x] While offline, Save and process is disabled with a caption, and Save raw still saves.
- [x] On Android and iOS, Share opens the system share sheet with a hint; a failed share says why.
- [x] The export page summarises records, photos, audio, capture dates, status counts, templates and the file, with Export and Share in its footer.
- [x] Each tray photo has a checkbox and a remove control and no Caption button; a caption fills the one photo, all photos with none ticked, or the ticked photos.
- [x] The photo preview shows the caption with Edit caption and Delete caption; a delete asks and can be undone.
- [x] New template takes a name and several fields, and Create saves them together with unique keys.
- [x] Tapping a record opens its page, which edits its fields and deletes it.
- [x] A record's Edit opens capture with its photos and captions; Save changes updates the same record, refining raw values; an unsaved new capture is untouched.
- [x] Tests: shell insets, record thumbnails, template counts, project home, search no-match, offline capture, export share and summary, photo checkbox and captions, preview captions, template create rows, record page, record edit session and writer.
