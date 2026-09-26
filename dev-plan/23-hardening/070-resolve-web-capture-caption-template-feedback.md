# 070 — Resolve web capture, caption and template feedback

**Phase** 23 · Hardening  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Close FBK0000002–FBK0000005 from the 26 September 2026 15:49 archive and FBK0000155 from the 15:50 archive. In a
browser, a photo from the webcam or the library is kept on the device and shows in the capture tray and the viewer.
On every platform, capture's Project and Template selects are one field tall and sit side by side with the two
saves from medium width up, and the empty tray's icon is itself the add action. Typing and dictating a caption no
longer writes it onto any photo; a button under the field adds it to the photos it names. Template fields list
Required, then Recommended, then Optional; every list search bar with facets carries the same filter button; and a
field's default value fills it when nothing else does.

The executable prompt is `prompts/feedback-26092026-1550/001-resolve-web-capture-caption-template-feedback.md`.
Decisions D1–D7 use the defaults in that prompt, (a) in every case:

- D1: web keeps photo files in IndexedDB through `BlobStore` (store `AppConstants.projectFiles.storeName`), and the
  first write asks the browser once for persistent storage; a reload keeps them, clearing site data removes them.
- D2: the field list shows Required, Recommended and Optional sections, each in stored order, and moves stay
  inside a section; the stored order capture and exports read does not change.
- D3: the filter button goes on projects, template fields (requiredness, type), templates (kind) and a project's
  records (status); pickers in sheets, the dataset browser and the feedback panel keep search only.
- D4: processing's validate stage writes a field's default into a field still empty after extraction, unverified,
  with provenance source `default`, and it counts as filled for the record status. Defaults are not written at
  save time.
- D5: the empty tray's add-photo icon is the add action, a labelled button, and the separate button is gone.
- D6: the caption button adds the text on a new line after a photo's existing caption.
- D7: after a successful add the caption field clears and a snack says how many photos got it.

FBK0000155 supersedes decision D2 of task 069 (a caption goes to the ticked photos as it is typed): the later
request, made after using that behaviour, wins. FBK0000149's ask, adding a caption to several photos before
saving, stays met through the button.

Names that differ from the prompt, because the prompt's would break a guardrail: the blob writer and reader live
in `blob_file_writer.dart` and `blob_file_reader.dart`, named for the types they hold (FE-STR-06), and a project's
records filter is `ProjectRecordFilter` in `project_record_filter.dart`, since `Item` is a banned word in a type
name (FE-CODE-03). The three list filters open one shared `showAppFilterSheet` beside `showAppSheet` (FE-CONS-02,
FE-CONS-05). A drag longer than one place lays the section's fields back into the section's own stored slots; a
one-place move swaps exactly two fields.

Web surfaces W1 and W2 leave out (processing, export, record-list and project-cover thumbnails) are task
[071](071-enable-processing-export-on-web.md). Processed records missing from the project home are task
[072](072-list-processed-records-on-project-home.md).

## Files

- `frontend/lib/main.dart`
- `frontend/lib/core/constants/app_constants.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/core/files/path_sanitizer.dart`
- `frontend/lib/core/files/file_writer.dart`
- `frontend/lib/core/files/file_writer_io.dart`
- `frontend/lib/core/files/file_writer_web.dart`
- `frontend/lib/core/files/file_writer_stub.dart`
- `frontend/lib/core/files/blob_file_writer.dart`
- `frontend/lib/core/files/file_reader.dart`
- `frontend/lib/core/files/file_reader_io.dart`
- `frontend/lib/core/files/file_reader_web.dart`
- `frontend/lib/core/files/file_reader_stub.dart`
- `frontend/lib/core/files/blob_file_reader.dart`
- `frontend/lib/core/widgets/photo_asset.dart`
- `frontend/lib/core/widgets/app_photo_thumb.dart`
- `frontend/lib/core/widgets/fields/app_choice_field.dart`
- `frontend/lib/core/widgets/responsive/responsive_pair.dart`
- `frontend/lib/core/widgets/states/app_empty_state.dart`
- `frontend/lib/core/widgets/app_search_field.dart`
- `frontend/lib/core/widgets/feedback/app_bottom_sheet.dart`
- `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart`
- `frontend/lib/features/capture/data/drift_photo_repository.dart`
- `frontend/lib/features/capture/presentation/capture_screen.dart`
- `frontend/lib/features/capture/presentation/capture_target_fields.dart`
- `frontend/lib/features/capture/presentation/photo_tray.dart`
- `frontend/lib/features/capture/presentation/record_caption_field.dart`
- `frontend/lib/features/projects/presentation/project_list_toolbar.dart`
- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/lib/features/projects/presentation/captured_items.dart`
- `frontend/lib/features/projects/presentation/project_record_filter.dart`
- `frontend/lib/features/templates/presentation/template_list_screen.dart`
- `frontend/lib/features/templates/presentation/template_list_filter.dart`
- `frontend/lib/features/templates/presentation/field_list_screen.dart`
- `frontend/lib/features/templates/presentation/field_list_filter.dart`
- `frontend/lib/features/templates/presentation/field_reorder.dart`
- `frontend/lib/features/processing/domain/proposal_application.dart`
- `frontend/lib/features/processing/data/validate_stage.dart`

## Definition of done

- [x] W1 — In a browser, `FileWriter` keeps files in IndexedDB through `BlobFileWriter` (same sha256 and length as
      the device writer), asks once for persistent storage, and `DriftPhotoRepository.readBytes` reads them back
      through `FileReader`, also after a reload; the device writer, its `.part` handling and its tests are unchanged.
- [x] W2 — `PhotoAsset.thumbBytes` draws through `Image.memory` decoded at thumbnail size; a browser's capture tray
      (new record and edit) draws the bytes it holds or reads back, never opens a `File`, and tapping a thumb opens
      the viewer; native trays keep their cached thumbnail files.
- [x] W3 — A sheet choice field is as tall as a labelled single-line text field and at least 48dp, unclipped at 200
      percent text.
- [x] W4 — `ResponsivePair` stacks on compact and shares a row in its flex ratio from medium up, start first in
      reading order, with a gallery entry and goldens at three widths in three themes.
- [x] W5 — `AppEmptyState` with `onIconTap` and `iconLabel` makes its icon a named 48dp button; every existing
      empty state renders as before.
- [x] W6 — `AppSearchField.onFilter` and `activeFilterCount` draw the one filter button after the microphone;
      `Copy.searchFilters` replaces `Copy.projectFilters`; the projects toolbar uses it.
- [x] W7 — The templates search filters by kind and a project's records search filters by status, each with a
      count on its button and Clear filters.
- [x] W8 — On Capture, Project and Template share a row, and so do Save raw and Save and process (the primary
      twice as wide), from medium width up; compact keeps today's order; the empty tray's icon opens the photo
      source sheet and the Add photo button is gone; nothing overflows at 200 percent text in either orientation.
- [x] W9 — Typing and dictating change no photo caption; a secondary button reads "Add to all n photos" or "Add to
      n ticked photos", appends the text after existing captions, clears the field and says how many photos got it;
      a failed add keeps the text; untouched text stays the record caption; on Capture and on the record edit page.
- [x] W10 — Template fields list Required, Recommended, then Optional sections in stored order; up, down and drag
      stay inside a section and change only the fields moved; the field search filters by requiredness and type.
- [x] W11 — Processing fills a field left empty with its default, unverified, source `default`, no evidence and an
      audit row; extracted, stored, verified and hand-entered values win; a required field its default fills
      counts as filled; the field row shows "Default: value".
- [x] Tests: `blob_file_writer_test`, `file_reader_test`, `drift_photo_repository_test`, `app_photo_thumb_test`,
      `app_choice_field_test`, `responsive_pair_test`, `app_empty_state_test`, `app_search_field_test`,
      `app_bottom_sheet_test`, `template_list_screen_test`, `project_home_screen_test`,
      `project_list_screen_test`, `capture_widgets_test`, `capture_feedback_test`, `capture_edit_screen_test`,
      `field_list_screen_test`, `field_reorder_test`, `proposal_application_test`, `validate_stage_test`.
- [x] Goldens regenerated: only for the items that change a catalogue image (local baselines, not
      tracked): W2 `test/design_system/app_photo_thumb/goldens/app_photo_thumb_{light,dark,outdoor}.png`; W3
      `test/design_system/app_choice_field/goldens/app_choice_field_{light,dark,outdoor}.png`, and, because every
      sheet choice field is now one field tall,
      `test/features/settings/presentation/goldens/ai_provider_settings_{light,dark,outdoor}.png`; W4 (new)
      `test/design_system/responsive_pair/goldens/responsive_pair_{compact,medium,expanded}_{light,dark,outdoor}.png`
      and `test/design_system/goldens/responsive_pair_{light,dark,outdoor}.png`; W5
      `test/design_system/app_empty_state/goldens/app_empty_state_{light,dark,outdoor}.png`; W6
      `test/design_system/app_search_field/goldens/app_search_field_{light,dark,outdoor}.png`. Every other golden
      matches its baseline from the commit before this task.
- [x] [071 — Enable processing, export and list thumbnails on web](071-enable-processing-export-on-web.md) and
      [072 — List processed records on the project home](072-list-processed-records-on-project-home.md) are in the
      plan.

## Verification

`dart run tool/verify.dart` on this change fails the same gates, with the same findings, as on the commit
before it; these failures predate task 070 and nothing here adds to them:

- test presence: the 47 files already listed as owing a test (for example
  `lib/features/capture/domain/caption_apply.dart`, `capture_screen.dart`).
- `test/architecture/errors_test.dart`: `capture_record_writer.dart` throws `_recordGone`, and
  `ExportRepositoryImpl.scope` returns a list.
- `test/architecture/state_test.dart`: the 35 `setState` and provider placements already reported.
- `test/tool/check_naming_test.dart`: the 19 naming findings already reported (for example `CapturedItems`).
- `test/tool/check_structure_test.dart`: the canonical core directory list orders `location` before
  `logging`.
- `test/tool/check_tests_test.dart`: the same 47 missing tests.

The golden baselines are local files; with baselines generated from the commit before this task, every golden
passes after the regenerations listed above. The release web build compiles.
