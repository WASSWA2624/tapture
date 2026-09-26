# 069 — Resolve record, capture markup and project photo feedback

**Phase** 23 · Hardening  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Close the 26 September 2026 04:34 feedback archive (FBK0000145–FBK0000154) using the defaults of its decisions
D1–D7. Tapping a record opens its page, and its Edit opens that record on the capture page. Record rows and the
capture tray show real thumbnails. Captions typed on capture keep every keystroke and say which photos they go to.
Crop, draw and type-on each save what the screen shows. Photo corner controls read on any photo. Page content
scrolls clear of the folded feedback bar, and a project can carry a photo.

The executable prompt is `prompts/feedback-26092026-0434/001-resolve-record-capture-markup-feedback.md`.
Decisions D1–D7 use the defaults in that prompt: (a) in every case.

## Files

- `frontend/lib/app/router.dart`
- `frontend/lib/app/route_paths.dart`
- `frontend/lib/app/theme/markup_ink.dart`
- `frontend/lib/core/constants/app_constants.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/core/files/thumbnail_cache.dart`
- `frontend/lib/core/files/photo_picker.dart`
- `frontend/lib/core/widgets/app_photo_thumb.dart`
- `frontend/lib/core/widgets/app_ink_picker.dart`
- `frontend/lib/core/widgets/photo_markup.dart`
- `frontend/lib/core/widgets/markup_stroke.dart`
- `frontend/lib/core/widgets/markup_text.dart`
- `frontend/lib/features/feedback/presentation/feedback_overlay.dart`
- `frontend/lib/features/capture/domain/capture_session.dart`
- `frontend/lib/features/capture/domain/capture_session_key.dart`
- `frontend/lib/features/capture/domain/capture_persistence.dart`
- `frontend/lib/features/capture/domain/capture_record_persistence.dart`
- `frontend/lib/features/capture/data/capture_record_writer.dart`
- `frontend/lib/features/capture/data/drift_capture_persistence.dart`
- `frontend/lib/features/capture/presentation/capture_controller.dart`
- `frontend/lib/features/capture/presentation/capture_screen.dart`
- `frontend/lib/features/capture/presentation/record_caption_field.dart`
- `frontend/lib/features/capture/presentation/photo_frame.dart`
- `frontend/lib/features/capture/presentation/photo_crop_screen.dart`
- `frontend/lib/features/capture/presentation/photo_doodle_screen.dart`
- `frontend/lib/features/capture/presentation/photo_type_screen.dart`
- `frontend/lib/features/capture/presentation/photo_viewer_screen.dart`
- `frontend/lib/features/capture/presentation/photo_tray.dart`
- `frontend/lib/features/projects/domain/project_settings.dart`
- `frontend/lib/features/projects/domain/project_repository.dart`
- `frontend/lib/features/projects/data/project_repository_impl.dart`
- `frontend/lib/features/projects/presentation/captured_items.dart`
- `frontend/lib/features/projects/presentation/record_detail_screen.dart`
- `frontend/lib/features/projects/presentation/project_create_screen.dart`
- `frontend/lib/features/projects/presentation/project_edit_screen.dart`
- `frontend/lib/features/projects/presentation/project_list_view.dart`
- `frontend/lib/main.dart`

## Definition of done

- [x] Tapping a record row opens its page, with no not-found page, at every width; the page shows the record's photos, caption, field values, audio count and capture time, and its menu edits the fields and deletes the record.
- [x] Fast typing into the caption field keeps every character and the text lands on the targets; the line under the field names how many photos the caption goes to; changing the ticks shows the new targets' caption.
- [x] With the default decoder, a stored JPEG gets a cached thumbnail no larger than the requested edge; record rows and the capture tray show the photo.
- [x] The crop frame starts on the photo, resizes from its corners and moves inside it; the saved crop is the region shown; after crop, draw and type-on the preview shows the new version.
- [x] With feedback minimized, every page's last content and footer action scroll into view above the bar, also with the keyboard open; closed and expanded feedback leave pages as before.
- [x] The select and remove controls sit flush in the thumbnail's top corners and are visible on black and white photos in all three themes.
- [x] Six named inks and three sizes are tokens and appear in `AppInkPicker`.
- [x] Draw offers the inks and sizes, each stroke keeps its own, and the saved photo shows the strokes where and as they were drawn.
- [x] Type-on shows the text live in the chosen ink, size and position, with several lines, a backing switch and dragging, and saves it where placed.
- [x] A record's Edit opens capture with its photos, captions and audio; Save changes updates the same record, refining raw captions; leaving without saving changes nothing; an unsaved new capture is untouched; field values are edited from the record page.
- [x] A project can be given, changed and cleared a photo from the create and edit screens, and one with a photo shows it as its list thumbnail.
- [x] Tests: record route and page, caption typing and targets, thumbnail decoder, photo frame and crop, folded feedback insets, corner controls, ink picker, draw and type-on markup, record edit session and writer, project photo.
