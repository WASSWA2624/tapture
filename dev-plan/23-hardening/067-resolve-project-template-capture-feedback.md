# 067 — Resolve project, template and capture feedback

**Phase** 23 · Hardening  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Close the 25 September 2026 feedback archive (FBK0000117–FBK0000131) using the defaults of its decisions D1–D6.
Audio recording saves a playable WAV file. A captured item is edited field by field. The shell stops padding
the top inset twice. Full-width buttons fill their slot. The shipped library is one list under seven categories.
Sheets draw one handle and fit their content. The template list has one add action. Pinned fields and project
contexts move into the project menu. The home template list loses its frame and the home gets a page gutter.
The project search is pinned at the top. Capture offers project and template switches and spaces its blocks.

Every icon is named through one vocabulary, `AppIcons`, drawn from widely recognised glyphs, and a guardrail
rejects an `Icons.` glyph anywhere else (FE-CONS-08).

The executable prompt is `prompts/feedback-25092026-1124/001-resolve-project-template-capture-feedback.md`.
Decisions D1–D6 use the defaults in that prompt.

## Files

- `frontend/lib/core/audio/audio_recorder_plugin.dart`
- `frontend/lib/core/constants/app_constants.dart`
- `frontend/lib/app/nav_shell.dart`
- `frontend/lib/core/widgets/app_icons.dart`
- `frontend/lib/core/widgets/app_button.dart`
- `frontend/lib/core/widgets/app_page.dart`
- `frontend/lib/core/widgets/feedback/app_bottom_sheet.dart`
- `frontend/lib/core/widgets/fields/app_radio_group.dart`
- `frontend/lib/core/widgets/fields/app_choice_field.dart`
- `frontend/lib/features/templates/domain/shipped_template_category.dart`
- `frontend/lib/features/templates/presentation/shipped_picker_screen.dart`
- `frontend/lib/features/templates/presentation/template_list_screen.dart`
- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/lib/features/projects/presentation/captured_items.dart`
- `frontend/lib/features/projects/presentation/record_edit_sheet.dart`
- `frontend/lib/features/projects/presentation/record_edit_controller.dart`
- `frontend/lib/features/projects/presentation/project_template_selection.dart`
- `frontend/lib/features/capture/domain/capture_template_choice.dart`
- `frontend/lib/features/capture/presentation/capture_target_fields.dart`
- `frontend/lib/features/capture/presentation/capture_screen.dart`
- `frontend/lib/features/capture/presentation/photo_tray.dart`
- `frontend/lib/features/capture/presentation/audio_recorder.dart`
- `frontend/test/architecture/icons_test.dart`

## Definition of done

- [x] Start then stop writes a WAV file through `FileWriter.copyIn`; the staging file is removed only after the copy, and a start failure reads "Recording could not start."
- [x] Shell pages see no top inset under the header, at compact, medium and expanded widths.
- [x] Save raw, the add-photo actions, Add level and the template add action fill their slot at the primary action's height.
- [x] The shipped library shows seven category headings; a search miss sits directly under the search field; Save adds only ticked templates.
- [x] Every modal sheet draws one handle and ends at its content.
- [x] A raw-saved item lists every editable template field; a new value is stored once as typed, a stored one is refined, and a failed save keeps the text.
- [x] The template list has one add action, reading Add more templates once a template exists.
- [x] Pinned fields and Project contexts open from the project menu; the home template list is unframed and in line with its label; the home search is pinned at the top.
- [x] Capture shows Project and Template fields that open a searchable list, shares its template choice with the home, and spaces its blocks by 16dp.
- [x] Every icon is an `AppIcons` concept; `icons_test.dart` fails on a raw glyph.
- [x] Tests: audio plugin, shell inset, button expand, sheet sizing, library categories, record editor, template list, project home, capture template choice, radio and choice fields, icon guardrail.
