# Feedback prompts — TAPTURE-26092026-1549.xlsx and TAPTURE-26092026-1550.xlsx

15 entries → 1 prompt, 11 work items. Generated 26 September 2026. Repository commit: 82701d7.

The two archives are merged into one prompt: both change the Capture page
(`frontend/lib/features/capture/presentation/capture_screen.dart`), so one run order keeps those edits in sequence.
Screenshots are under `prompts/TAPTURE-26092026-1549/screenshots/` (FBK0000002 to FBK0000005) and
`prompts/TAPTURE-26092026-1550/screenshots/` (FBK0000145 to FBK0000155).

## Run order

| Prompt | Item | Title | Feedback | Type | Priority | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 001 | W1 | Keep capture files in the browser | FBK0000005 | Defect | P2 | — |
| 001 | W2 | Draw tray thumbnails from bytes in the browser | FBK0000005 | Defect | P2 | W1 |
| 001 | W3 | Make sheet choice fields one field tall | FBK0000004 | Defect | P3 | — |
| 001 | W4 | Add a responsive pair | FBK0000004 | Improvement | P4 | — |
| 001 | W5 | Let an empty state's icon be its action | FBK0000004 | Improvement | P4 | — |
| 001 | W6 | Give the search field one filter button | FBK0000003 | Improvement | P4 | — |
| 001 | W7 | Filter templates and project records | FBK0000003 | Improvement | P5 | W6 |
| 001 | W8 | Lay out capture's selects, saves and empty tray | FBK0000004 | Improvement | P5 | W3, W4, W5 |
| 001 | W9 | Add a caption to photos only on request | FBK0000155 | Improvement | P5 | W8 |
| 001 | W10 | Group template fields by requiredness and filter them | FBK0000003 | Improvement | P5 | W6 |
| 001 | W11 | Fill empty fields from their default | FBK0000002 | Gap | P5 | — |

## Coverage

| Feedback ID | Category | Screen | Outcome |
| :--- | :--- | :--- | :--- |
| FBK0000002 | General feedback | Projects › Testing › Templates | 001 W11 |
| FBK0000003 | General feedback | Projects › Testing › Templates | 001 W6, 001 W7, 001 W10 |
| FBK0000004 | General feedback | Projects › Testing › Capture | 001 W3, 001 W4, 001 W5, 001 W8 |
| FBK0000005 | General feedback | Projects › Testing › Capture | 001 W1, 001 W2 |
| FBK0000145 | General feedback | Projects › Testing | Already resolved (`frontend/lib/features/feedback/presentation/feedback_overlay.dart:75`, `:148` inset the app by the folded bar; c8c652f, task 069 W5) |
| FBK0000146 | General feedback | Projects › Testing | Already resolved (`frontend/lib/core/files/thumbnail_cache.dart:161` decodes thumbnails with the `image` package in the isolate runner; c8c652f, task 069 W3) |
| FBK0000147 | General feedback | Projects › Testing › Records | Already resolved (`frontend/lib/app/router.dart:509-514` routes a project's record to `RecordDetailScreen`; c8c652f, task 069 W1) |
| FBK0000148 | General feedback | Projects › Testing › Records | Already resolved (`frontend/lib/features/capture/domain/capture_session_key.dart:10` keys a record edit `edit:<recordId>` on the capture page; c8c652f, task 069 W10) |
| FBK0000149 | General feedback | Capture | Already resolved (`frontend/lib/features/capture/presentation/capture_screen.dart:379` adds a caption to the ticked photos before saving; c8c652f, task 069 W2); 001 W9 keeps it met through a button |
| FBK0000150 | General feedback | Capture | Already resolved (`frontend/lib/core/widgets/photo_markup.dart:181` crops with `copyCrop`, and `photo_crop_screen.dart` shows the result; c8c652f, task 069 W4) |
| FBK0000151 | General feedback | Capture | Already resolved (`frontend/lib/app/theme/markup_ink.dart:5` inks and `core/widgets/app_ink_picker.dart` in `photo_doodle_screen.dart`; c8c652f, task 069 W7, W8) |
| FBK0000152 | General feedback | Capture | Already resolved (`frontend/lib/features/capture/presentation/photo_type_screen.dart:25-56` types live text with ink, size and drag; c8c652f, task 069 W9) |
| FBK0000153 | General feedback | Capture | Already resolved (`frontend/lib/core/widgets/app_photo_thumb.dart:57-62` puts the select and remove controls flush in the corners; c8c652f, task 069 W6; `screenshots/FBK0000155.png` shows them) |
| FBK0000154 | General feedback | Projects | Already resolved (`frontend/lib/features/projects/presentation/project_edit_screen.dart:140` sets a project photo and `project_list_view.dart:192` shows it; c8c652f, task 069 W11) |
| FBK0000155 | General feedback | Projects › Eficon › Capture | 001 W9 |

## Open questions

- 001 D1, default (a): web keeps photo files in IndexedDB through `BlobStore`, asking for persistent storage on the
  first write. Clearing the browser's site data still deletes them.
- 001 D2, default (a): the template field list shows Required, Recommended and Optional sections; the stored order
  used by capture and exports does not change.
- 001 D3, default (a): the filter button goes on projects, template fields, templates (kind) and a project's
  records (status); pickers in sheets, the dataset browser and the feedback panel keep search only.
- 001 D4, default (a): processing writes a field's default into a field still empty after extraction, unverified,
  with source `default`, and it counts as filled. Defaults are not written at save time.
- 001 D5, default (a): the empty tray's add-photo icon becomes the add action and the separate button goes.
- 001 D6, default (a): the caption button adds the text on a new line after a photo's existing caption.
- 001 D7, default (a): after a successful add the caption field clears and a snack says how many photos got it.
- FBK0000155 reverses task 069's D2 (captions go to the ticked photos as they are typed). It is the later
  request, made after using that behaviour, so it wins; W9 keeps FBK0000149's ask, adding a caption to several
  photos before saving, through the button.
- FBK0000005 reports the camera as not working. Both error screenshots show the photo reaching the file writer, so
  W1 treats the webcam as working. If the webcam preview itself fails to open, the reporter needs to say which
  browser.
- FBK0000003 says "a filter" without naming what to filter the template fields by. W10 filters by requiredness
  and type, the two facets each row shows.
- FBK0000152 still carries the open question from the 26 September 04:34 archive: which further text features
  matter beyond live, dragged, sized and inked text (rotation, several blocks per save, fonts, shapes). The
  reporter needs to say.
- FBK0000145 to FBK0000154 were already exported in the 04:34 archive and closed by task 069. Only FBK0000155 is
  new in the 15:50 archive.
- Noticed, not reported: on web, processing, export, record-list thumbnails and the project cover photo read
  `dart:io` files. The prompt adds a plan task for them rather than widening W1 and W2.
