# 001 — Resolve projects and capture feedback

**Feedback:** FBK0000075, FBK0000076, FBK0000077, FBK0000078, FBK0000079, FBK0000080, FBK0000081, FBK0000082, FBK0000083, FBK0000084, FBK0000085, FBK0000086, FBK0000087, FBK0000088, FBK0000089 · **Work items:** 13 · **Depends on:** none

## Goal
Make captured photos visible, let the operator caption the photos they select, and make project search, filters, home, the shipped template library, and project export readable on every platform that already renders those screens.

## Run order

| Item | Title | Feedback | Type | Priority | Effort | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| W1 | Show the captured photo | FBK0000082 | Defect | P2 | M | — |
| W2 | Show captured records on the project | FBK0000085 | Defect | P2 | M | — |
| W3 | Caption selected photos from capture | FBK0000084 | Gap | P2 | M | W1 |
| W4 | Use one add-photo sheet with icon buttons | FBK0000081 | Improvement | P3 | M | — |
| W5 | Match the add-photo control to the thumbnail | FBK0000083 | Improvement | P3 | S | W1 |
| W6 | Place the filter inside the search field | FBK0000075, FBK0000077 | Improvement | P3 | M | — |
| W7 | Open filters as a Projects page | FBK0000076 | Improvement | P3 | M | W6 |
| W8 | Compact project rows and mark archived ones | FBK0000078 | Improvement | P3 | S | — |
| W9 | Align project-home association rows | FBK0000079 | Improvement | P3 | S | — |
| W10 | Make destination cards read as buttons | FBK0000080 | Improvement | P3 | S | W9 |
| W11 | Search the shipped template library | FBK0000088 | Gap | P3 | M | — |
| W12 | Clarify the pinned-fields empty state | FBK0000089 | Gap | P3 | S | W4 |
| W13 | Expose project export | FBK0000086, FBK0000087 | Suggestion | P4 | L | W10 |

## Rules

- FE-CONS-01, FE-CONS-02, FE-CONS-05, FE-CONS-06, FE-STR-09: extend the catalogue and the shared sheet once.
- FE-RESP-03, FE-RESP-06, FE-RESP-07, FE-RESP-10, FE-A11Y-01, FE-A11Y-02, FE-A11Y-03: keep the same state across the layout matrix and test it.
- FE-L10N-01, FE-L10N-03, FE-L10N-04: route visible copy through `Copy` and format counts with the active locale.
- FE-STATE-06, FE-STATE-07, FE-SEC-08: one source of truth, durable writes, and no overwrite of raw evidence.
- FE-TEST-01, FE-TEST-02, FE-TEST-10: ship the tests with the change.
- FE-FLOW-06, FE-FLOW-08: add no package; record the work as a plan task before coding.

## Before the work items

1. Record this prompt as one task with `cd frontend && dart run tool/new_task.dart 23-hardening resolve-feedback-24092026 "Resolve projects and capture feedback"` (FE-FLOW-08). Task 063 already records the previous archive, so this archive gets the next number.
2. Run `cd frontend && dart run tool/verify.dart --fast` and save the baseline. Keep pre-existing failures distinct from regressions introduced by this prompt.

## W1 — Show the captured photo

**Feedback:** FBK0000082 · **Type:** Defect · **Priority:** P2 · **Effort:** M · **After:** —

### Evidence

- FBK0000082: the operator cannot see the photo they captured. `screenshots/FBK0000082.png` shows the capture tray with a thumbnail labelled Missing photo. `screenshots/FBK0000082-2.png` shows the viewer centred on Missing photo, with rotate, crop, draw, caption, and type controls above it. Android, compact, portrait, system dark, text scale 1.
- `frontend/lib/features/capture/presentation/capture_screen.dart:768-788` adds the photo id to `_missing` when `cachedThumbnailPath` fails. `frontend/lib/features/capture/presentation/photo_tray.dart:94-96` then passes the thumb path `missing`, so `AppPhotoThumb` draws the missing placeholder even when the session still holds the bytes.

### Scope

- Reach: Android, iOS, Windows, macOS, and Linux capture, compact through expanded, both orientations, light, dark, and outdoor, at 200 percent text. Web has no durable photo files while `dev-plan/23-hardening/029-enable-app-database-on-web.md` is unfinished; on web, show the in-memory bytes in the tray and the viewer, and do not claim a stored thumbnail.
- Change: `capture_screen.dart` (`_refreshThumbs`, `_readPhoto`, the viewer `missingIds`), `photo_tray.dart`, `DriftPhotoRepository.cachedThumbnailPath` and `readBytes` in `frontend/lib/features/capture/data/drift_photo_repository.dart`.
- Do not change: original evidence bytes, derivation, rotation metadata, caption scope, and save ordering.

### Rules

- FE-PERF-04, FE-PERF-02: the tray decodes a cached thumbnail off the UI thread.
- FE-SEC-08: a failed thumbnail never deletes the source file.
- FE-A11Y-02: the missing state keeps its existing label, and only when the source file is absent.

### Steps

1. Treat a thumbnail failure as a missing thumbnail. Add the photo id to `_missing` only when `readBytes` fails.
2. When the capture session still holds bytes, write the cached thumbnail from those bytes through `ThumbnailCache` and pass that file to `AppPhotoThumb`.
3. When the session has no bytes, read the stored file from the same project-relative path `DriftPhotoRepository` used at save, then build the thumbnail. Keep the capture session usable when that read fails, and show `Copy.missingPhoto` on that photo alone.
4. Pass `missingIds` to `PhotoViewerScreen` only for photos whose `readBytes` failed. A photo with session bytes displays those bytes in the viewer.
5. Extend `frontend/test/features/capture/presentation/capture_feedback_test.dart` and `frontend/test/features/capture/data/drift_photo_repository_test.dart` so a failed thumbnail still shows the captured image, and a missing source file shows `Copy.missingPhoto`. Make `cd frontend && dart run tool/verify.dart --fast` green.

### Acceptance criteria

- [ ] After capture, the tray shows the photo image on every platform named under Reach, including after the session is restored on platforms with a database.
- [ ] The viewer shows that same image, and the editing controls remain available.
- [ ] A thumbnail failure leaves the source bytes in place and still shows the image from memory.
- [ ] A missing source file shows `Copy.missingPhoto` for that photo and leaves the other photos in the tray.
- [ ] FBK0000082 is resolved on global capture and project capture.

## W2 — Show captured records on the project

**Feedback:** FBK0000085 · **Type:** Defect · **Priority:** P2 · **Effort:** M · **After:** —

### Evidence

- FBK0000085: the operator cannot see what was captured. `screenshots/FBK0000085.png` shows the project list reporting records and unprocessed records. `screenshots/FBK0000085-2.png` shows project home with every destination at nothing. Android, compact, portrait, system dark, text scale 1.
- `frontend/lib/features/projects/data/project_repository_impl.dart:217-218` counts a record as unprocessed unless its status is `approved`, `archived`, or `deleted`. `watchHome` at lines 273-274 counts Ready to process only for `queued` and `processing`. `frontend/lib/app/router.dart:477-482` still builds the project records route as `_RoutePage(name: 'records')`.

### Scope

- Reach: the project list and project home on every platform, all three size classes, both orientations, every theme, and 200 percent text.
- Change: `watchHome` in `project_repository_impl.dart`, a new project records list screen replacing the placeholder at `router.dart:477-482`, and `Copy` messages for an empty filtered list.
- Do not change: the review count (`needsReview`), the export count (`approved`), the share count (export rows), and the list's record and unprocessed totals.

### Rules

- FE-STATE-06: the home count and the list it opens read the same query.
- FE-CONS-04, FE-CONS-06: each record row uses `AppListTile` and `AppStatusPill`.
- FE-L10N-04: counts use the active locale.

### Steps

1. Count Ready to process as records whose status is one of `draft`, `captured`, `CAPTURED`, `queued`, and `processing`.
2. Replace the project records placeholder with a screen that lists the open project's records for the active filter. The process filter shows the statuses from step 1. Each row shows a 1-based position, the record status through `AppStatusPill`, and the photo count for that record.
3. Show `Copy` empty and failure states, with retry, for an empty filter match and for a failed query.
4. Add repository tests for the process count and widget tests that a captured record appears on the process list. Make the fast gate green.

### Acceptance criteria

- [ ] A project whose list reports unprocessed records shows a non-zero Ready to process count for those captured records.
- [ ] Opening Ready to process lists those records with status and photo count.
- [ ] Review, export, and share counts keep their current meanings.
- [ ] FBK0000085 is resolved on the list and on project home.

## W3 — Caption selected photos from capture

**Feedback:** FBK0000084 · **Type:** Gap · **Priority:** P2 · **Effort:** M · **After:** W1

### Evidence

- FBK0000084: the operator cannot caption one photo or the photos they have selected. `screenshots/FBK0000084.png` shows two selected thumbnails and a single record caption field. Android, compact, portrait, system dark, text scale 1.
- `PhotoViewerScreen` opens `PhotoCaptionSheet` from `capture_screen.dart:509`, and the capture page itself only edits the record caption through `RecordCaptionField`.

### Scope

- Reach: global and project capture on every W1 platform, all size classes, both orientations, every theme, and 200 percent text.
- Change: `capture_screen.dart`, `PhotoCaptionSheet`, and `Copy.capturePhotoCaption`.
- Do not change: record-caption persistence, caption scope values, and W1 image behaviour.

### Rules

- FE-SIMP-01: the record caption stays in place; the photo-caption action is secondary.
- FE-STATE-07: the sheet closes only after `applyCaptions` succeeds.
- FE-A11Y-02: the action names how many photos it will caption.

### Steps

1. Add a secondary action under the photo tray, labelled with `Copy.capturePhotoCaption`, enabled when the tray has at least one photo.
2. The action opens the existing `PhotoCaptionSheet`. With a selection, the default scope is the selection. With no selection, the default scope is the latest photo. All photos remains available in both cases.
3. Keep the record caption field bound to the record caption.
4. Extend `capture_feedback_test.dart` so a selection receives the caption and an empty selection captions the latest photo. Make the fast gate green.

### Acceptance criteria

- [ ] The operator can caption the latest photo, the current selection, and every photo without opening the viewer.
- [ ] The record caption remains independent of photo captions.
- [ ] A failed write leaves the previous captions in place and keeps the sheet open with the typed text.
- [ ] FBK0000084 is resolved on global and project capture.

## W4 — Use one add-photo sheet with icon buttons

**Feedback:** FBK0000081 · **Type:** Improvement · **Priority:** P3 · **Effort:** M · **After:** —

### Evidence

- FBK0000081: the add-photo surface is two nested rounded containers, and Take a photo and Choose from this device look like plain rows. `screenshots/FBK0000081.png` shows a large empty rounded sheet behind a second sheet titled Add a photo. Android, compact, portrait, system dark, text scale 1.
- `showAppSheet` in `frontend/lib/core/widgets/feedback/app_bottom_sheet.dart:150-170` caps the modal at 75 percent and wraps another `AppBottomSheet`. `capture_screen.dart:341-367` fills that sheet with borderless `AppListTile` rows.

### Scope

- Reach: every `showAppSheet` caller, on every platform, all size classes, both orientations, every theme, and 200 percent text. Expanded layouts keep the side panel.
- Change: `app_bottom_sheet.dart` and the add-photo builder in `capture_screen.dart`.
- Do not change: photo capture, gallery import, and the sheet title.

### Rules

- FE-CONS-05: one sheet chrome.
- FE-CONS-08: one icon per action, from the existing vocabulary (`Icons.photo_camera_outlined`, `Icons.photo_library_outlined`).
- FE-A11Y-01: each action is at least 48dp and labelled.

### Steps

1. Draw one surface for a sheet: the modal barrier, one title, one drag handle on compact and medium, and the body. Remove the second rounded surface behind a content-sized sheet.
2. Render Take a photo and Choose from this device as `AppButton` rows with those icons, stacked, full width, inside that single sheet.
3. Add a widget test at 360, 800, and 1200 dp that finds one sheet title and both labelled buttons. Make the fast gate green.

### Acceptance criteria

- [ ] Add photo shows one sheet, with no second rounded container behind it.
- [ ] Both actions show an icon and a label and meet 48dp on compact, medium, and expanded layouts.
- [ ] Other sheets keep a single chrome after this change.
- [ ] FBK0000081 is resolved on global and project capture.

## W5 — Match the add-photo control to the thumbnail

**Feedback:** FBK0000083 · **Type:** Improvement · **Priority:** P3 · **Effort:** S · **After:** W1

### Evidence

- FBK0000083: the add-photo control should be the same size as the thumbnails. `screenshots/FBK0000083.png` shows a tall narrow add control beside a square thumbnail. Android, compact, portrait, system dark, text scale 1.
- `photo_tray.dart:76-82` uses `AppIconButton`, whose target is 48dp, inside a strip whose height is `Space.x12 * 2`. `AppPhotoThumb` fills that square.

### Scope

- Reach: every capture tray, all size classes, both orientations, every theme, and 200 percent text.
- Change: the add target in `photo_tray.dart`.
- Do not change: thumbnail decoding from W1, selection, and the W4 add-photo sheet.

### Rules

- FE-CONS-06: the add target uses the same square size as `AppPhotoThumb`.
- FE-A11Y-02: it keeps the tooltip and semantic label `Copy.captureAddPhoto`.

### Steps

1. Replace the tray's add `AppIconButton` with a square control of the same edge as `AppPhotoThumb` in that strip, using `Icons.add_a_photo`, no extra outline beyond the thumbnail border, and the same padding as the thumbs.
2. Update the capture tray widget test to expect equal width and height for the thumb and the add control. Make the fast gate green.

### Acceptance criteria

- [ ] The add control has the same width and height as a photo thumbnail in the tray.
- [ ] It remains labelled Add photo and opens the W4 sheet.
- [ ] FBK0000083 is resolved on every capture tray.

## W6 — Place the filter inside the search field

**Feedback:** FBK0000075, FBK0000077 · **Type:** Improvement · **Priority:** P3 · **Effort:** M · **After:** —

### Evidence

- FBK0000075: the filter should sit in the search field immediately after the microphone, with no border, and stay recognisable. `screenshots/FBK0000075.png` shows the microphone inside the field and a separate bordered filter button after the field.
- FBK0000077: remove the close control that appears after Show archived. `screenshots/FBK0000077.png` shows a filled filter button and an X beside it.
- `project_list_toolbar.dart:36-59` places `AppIconButton` for filter and clear outside `AppSearchField`. `AppTextField._suffix` at `app_text_field.dart:312-320` draws the microphone after `trailing`.

### Scope

- Reach: the projects list and the expanded projects pane, every platform, all size classes, both orientations, every theme, RTL, and 200 percent text.
- Change: `AppTextField` suffix order, `AppSearchField`, and `ProjectListToolbar`.
- Do not change: query debounce, the Show archived menu item, and filter criteria.

### Rules

- FE-A11Y-01, FE-A11Y-02, FE-A11Y-05: the filter keeps a 48dp target, a tooltip, a semantic label with the active count, and a selected state that is not colour alone.
- FE-CONS-01: the microphone and the filter are both `AppIconButton` with `outlined: false`.

### Steps

1. Add a slot on `AppTextField` that is laid out immediately after the dictate button. Pass the project filter through `AppSearchField` into that slot.
2. Remove the filter and clear buttons that sit outside the field. Do not add a replacement clear icon.
3. The filter icon uses `Icons.filter_list`, `outlined: false`, and `selected` when `activeFilterCount` is greater than zero. Its semantic label is `Copy.projectFilters(activeFilterCount)`.
4. Extend toolbar tests for order (microphone, then filter), the hidden clear control, RTL, and 200 percent text. Make the fast gate green.

### Acceptance criteria

- [ ] The filter is inside the search field, immediately after the microphone, with no border.
- [ ] Active filters announce the count and a selected state.
- [ ] Show archived no longer reveals an X beside the search field.
- [ ] Search text, debounce, and the Show archived menu keep their current behaviour.
- [ ] FBK0000075 and FBK0000077 are resolved on the list and the expanded pane.

## W7 — Open filters as a Projects page

**Feedback:** FBK0000076 · **Type:** Improvement · **Priority:** P3 · **Effort:** M · **After:** W6

### Evidence

- FBK0000076: the filter UI is disorganised; remove the nested rounded containers and present it as a screen with the breadcrumb Projects, then Filters. Checkbox labels sit far from the boxes, and vertical spacing is too large. `screenshots/FBK0000076.png` shows a sheet over another rounded surface, with Active and Archived labels on the left and boxes on the right. Android, compact, portrait, system dark, text scale 1.
- `project_list_toolbar.dart:71-85` opens `showAppSheet`. The form at lines 114-128 uses `CheckboxListTile`, and lines 130-131 repeat the pinned-state label.

### Scope

- Reach: every platform, all size classes, both orientations, every theme, RTL, and 200 percent text. Back from the page returns to the projects list on compact, and to the expanded pane's list on expanded.
- Change: a `project_filters_screen.dart`, `RoutePaths`, `router.dart`, `ShellTitle`, and the W6 filter button.
- Do not change: which criteria exist, their defaults, and project ordering.

### Rules

- FE-CONS-01: status and organisation use `AppCheckboxGroup`, whose checkbox is already followed by a close label.
- FE-CONS-10: the status line shows back plus the same `Parent › Child` title pattern as `ShellTitle` at `shell_title.dart:57-58`.
- FE-RESP-06: the page scrolls at 200 percent text.

### Steps

1. Add `RoutePaths.projectFilters` as `/projects/filters`, registered before `:projectId`. The W6 filter button pushes that route.
2. Title the route with `Copy` as `Projects › Filters`, using the status-line back control. Remove the sheet from the filter action.
3. Build the page with `AppCheckboxGroup` for status and for organisation, and one `AppChoiceField` for pinned state. Delete the extra pinned-state heading. Use `Space.x1` between groups.
4. Apply writes the criteria and pops back to the list. Unchecking Archived and applying hides archived projects again.
5. Add route and widget tests for the breadcrumb, leading checkbox, apply, and back. Regenerate the project-list goldens listed under Verification. Make the fast gate green.

### Acceptance criteria

- [ ] Filters is a page titled Projects › Filters, with one surface and no sheet behind it.
- [ ] Each checkbox is immediately followed by its label, and the rows use the catalogue spacing.
- [ ] Apply and Back return to the projects list with the chosen criteria.
- [ ] FBK0000076 is resolved on compact, medium, and expanded layouts.

## W8 — Compact project rows and mark archived ones

**Feedback:** FBK0000078 · **Type:** Improvement · **Priority:** P3 · **Effort:** S · **After:** —

### Evidence

- FBK0000078: the gap above the search field is too large; archived projects need a visible mark like the pin; Last worked is truncated and should go. `screenshots/FBK0000078.png` shows the search field well below the header and a subtitle that ends in a cut-off Last worked phrase. Android, compact, portrait, system dark, text scale 1.
- `project_list_screen.dart:68-70` pads the toolbar with `Space.x4` on every side. `nav_shell.dart:226-229` uses `Space.x4` above the pane toolbar. `project_list_view.dart:68-86` appends `Copy.projectLastWorked` and draws a pin only.

### Scope

- Reach: the projects list and the expanded pane, every platform, all size classes, both orientations, every theme, and 200 percent text.
- Change: those two paddings, `Copy.projectListSubtitle`, and the row trailing icons.
- Do not change: pin behaviour, archive behaviour, row order, and the record and unprocessed counts.

### Rules

- FE-THEME-01: the reduced gap uses `Space.x1`.
- FE-A11Y-05: the archived mark is an icon plus `Copy.projectStatusArchived`, matching the pin's icon-plus-label pattern.
- FE-L10N-03: the subtitle is one `Copy` message containing the record count and the unprocessed count.

### Steps

1. Change the toolbar's top padding to `Space.x1` on the list and in the expanded pane.
2. Remove `lastWorked` from `Copy.projectListSubtitle` and from the row. Keep `Copy.projectLastWorked` unused only if another caller still needs it; otherwise delete the symbol and its test references.
3. When `project.status` is archived, show `Icons.inventory_2_outlined` with the semantic label `Copy.projectStatusArchived` beside the existing pin slot.
4. Update list widget tests and regenerate `frontend/test/features/projects/presentation/goldens/project_list_numbered_pinned_*.png` and `frontend/test/app/goldens/nav_pane_projects_*.png`. Make the fast gate green.

### Acceptance criteria

- [ ] The search field sits one `Space.x1` below the header chrome.
- [ ] Row subtitles contain the record count and the unprocessed count, and contain no Last worked text.
- [ ] An archived row shows an archived icon and label, and a pinned row still shows the pin.
- [ ] FBK0000078 is resolved on the list and the expanded pane.

## W9 — Align project-home association rows

**Feedback:** FBK0000079 · **Type:** Improvement · **Priority:** P3 · **Effort:** S · **After:** —

### Evidence

- FBK0000079: Context levels and Templates sit further left-inset than the destination cards. `screenshots/FBK0000079.png` shows those two rows indented relative to the cards under them. Android, compact, portrait, system dark, text scale 1.
- `project_home_screen.dart:193-194` pads the whole column by `Space.x4`, and `AppListTile` adds another `Space.x4` at `app_list_tile.dart:67-69`. The cards that follow do not add that second inset.

### Scope

- Reach: project home on every platform, all size classes, both orientations, every theme, RTL, and 200 percent text.
- Change: the padding around `_HomeBody` and the destination grid.
- Do not change: the association queries, the routes those rows open, and the card contents (W10 owns those).

### Rules

- FE-RESP-10, FE-A11Y-03: the shared inset holds at 200 percent text without clipping.
- FE-THEME-01: the inset is `Space.x4` from the screen edge for both the rows and the cards.

### Steps

1. Remove the horizontal padding from the home scroll view.
2. Give the destination grid the same horizontal inset the list tiles already apply, so the tile text and the card text start on one vertical line.
3. Update `project_home_screen_test.dart` for that alignment at compact and expanded widths. Make the fast gate green.

### Acceptance criteria

- [ ] Context levels, Templates, and the destination cards share one left inset and one right inset.
- [ ] RTL mirrors that inset.
- [ ] FBK0000079 is resolved on project home.

## W10 — Make destination cards read as buttons

**Feedback:** FBK0000080 · **Type:** Improvement · **Priority:** P3 · **Effort:** S · **After:** W9

### Evidence

- FBK0000080: put the icon and the label on one row, put the short description under that row, align the block to the start, and shade the card so it looks tappable. `screenshots/FBK0000080.png` shows the icon above the label on a flat outlined card. Android, compact, portrait, system dark, text scale 1.
- `_CountCard.build` at `project_home_screen.dart:368-397` stacks the icon, the label, and the message in a column on an `AppCard` with `elevationLevel: 0`.

### Scope

- Reach: the four project-home destinations, every platform, all size classes, both orientations, every theme, RTL, and 200 percent text.
- Change: `_CountCard` only.
- Do not change: the four routes, the count queries from W2, and the W9 inset.

### Rules

- FE-THEME-01, FE-THEME-05: use `Elevation.surface` through `AppCard`, and pair the icon with the label text.
- FE-A11Y-01: the whole card stays one tap target.
- FE-CONS-08: keep the icon already assigned to each destination.

### Steps

1. Lay the icon and the label in one start-aligned row. Place the existing count message under that row, start aligned.
2. Set `elevationLevel` to 1 so the card uses the raised surface token, and keep the tap on the whole card.
3. Update home widget tests and regenerate `frontend/test/features/projects/presentation/goldens/project_home_open_with_menu_*.png`. Make the fast gate green.

### Acceptance criteria

- [ ] Each destination shows its icon and label on one row, with the count message underneath, aligned to the start.
- [ ] The card uses the level-1 surface and remains one control.
- [ ] Zero, singular, and plural messages stay the current `Copy.home*Pending` strings.
- [ ] FBK0000080 is resolved on project home.

## W11 — Search the shipped template library

**Feedback:** FBK0000088 · **Type:** Gap · **Priority:** P3 · **Effort:** M · **After:** —

### Evidence

- FBK0000088: the shipped library needs a search field so a template can be found, including a filter. `screenshots/FBK0000088.png` shows kind headings and template rows and no search field. Android, compact, portrait, system dark, text scale 1.
- `ShippedPickerScreen._library` in `frontend/lib/features/templates/presentation/shipped_picker_screen.dart` renders every shipped template and has no query.

### Scope

- Reach: the shipped library opened from a project and from Settings, every platform, all size classes, both orientations, every theme, and 200 percent text.
- Change: `shipped_picker_screen.dart` and `Copy` for the search hint and an empty match.
- Do not change: shipped template definitions, the Added to this project mark, and the add and custom-copy actions.

### Rules

- FE-CONS-01: reuse `AppSearchField` and `AppCheckboxGroup` for kinds.
- FE-STATE-06: filter the list already loaded by `shippedLibraryProvider`; do not fetch a second catalogue.
- FE-L10N-01: the hint and the empty match go through `Copy`.

### Steps

1. Put `AppSearchField` at the top of the library. Match the query against the visible template name and the kind title, case-insensitive.
2. Under the field, offer an `AppCheckboxGroup` of the kinds present in the library. An empty selection shows every kind. A selection shows those kinds.
3. When nothing matches, show an empty state that names the query and leaves the field editable.
4. Add widget tests for a name match, a kind filter, a combined match, and the empty match. Make the fast gate green.

### Acceptance criteria

- [ ] The library has a search field and a kind filter on both the project route and the Settings route.
- [ ] Typing narrows the rows to names and kinds that contain the query.
- [ ] A kind selection hides the other kinds, and clearing the selection shows them again.
- [ ] FBK0000088 is resolved without changing shipped definitions.

## W12 — Clarify the pinned-fields empty state

**Feedback:** FBK0000089 · **Type:** Gap · **Priority:** P3 · **Effort:** S · **After:** W4

### Evidence

- FBK0000089: the pinned-fields surface is confusing. `screenshots/FBK0000089.png` shows it inside a second rounded sheet, with the headline No pinnable context fields and a button labelled Add templates. Android, compact, portrait, system dark, text scale 1.
- `pinned_fields_sheet.dart:87-94` always offers `Copy.contextOpenTemplates` ("Add templates") when `_fields` is empty, including when the project already has templates whose fields are not stickable.

### Scope

- Reach: the pinned-fields sheet on every platform, all size classes, both orientations, and every theme. W4 has already removed the second sheet surface.
- Change: the empty branch in `pinned_fields_sheet.dart` and two `Copy` messages.
- Do not change: saving pinned values, and the Add templates path used when the project has no templates.

### Rules

- FE-SIMP-11: the empty state names the next action that matches the data.
- FE-STATE-06: template presence comes from `templateRepositoryProvider.watchByProject`.
- FE-L10N-03: each action is one complete message.

### Steps

1. When the project has no templates, keep the action Add templates and open `RoutePaths.templateLibrary` for that project.
2. When the project has templates and none of their fields are stickable, replace the action with a `Copy` message that tells the operator to mark a field as pinnable, and open `RoutePaths.projectTemplates` for that project.
3. Add widget tests for both empty branches. Make the fast gate green.

### Acceptance criteria

- [ ] A project with templates and no stickable fields does not show Add templates.
- [ ] A project with no templates still offers Add templates and opens the project library.
- [ ] The sheet uses the single chrome from W4.
- [ ] FBK0000089 is resolved on the pinned-fields sheet.

## W13 — Expose project export

**Feedback:** FBK0000086, FBK0000087 · **Type:** Suggestion · **Priority:** P4 · **Effort:** L · **After:** W10

### Evidence

- FBK0000086: the operator cannot see how to export a project. `screenshots/FBK0000086.png` shows the row menu with Rename, Unpin, Unarchive, and Delete project.
- FBK0000087: export should be easy to find. `screenshots/FBK0000087.png` shows that same menu. `screenshots/FBK0000087-2.png` shows project home, whose Ready to export card is a count of approved records, not an export command. Android, compact, portrait, system dark, text scale 1.
- `project_list_view.dart:141-167` and `project_home_screen.dart:314-340` omit an export command. `router.dart:493-498` still returns `_RoutePage(name: 'exports')`.

### Scope

- Reach: the project-row menu and the project-home menu on every platform and size class. The export file is written on device into that project's `exports/` folder. Web uses the same screen and refuses the write with the existing storage failure while project files are unavailable. No network upload.
- Change: both overflow builders, `RoutePaths.projectExport`, the project `exports` route, a new export screen, and `ExportRepository`.
- Do not change: raw evidence, the Ready to export count, and the template and reference-data exporters.

### Rules

- FE-SEC-03, FE-SEC-04: the write is local; sharing happens only from a separate action.
- FE-SEC-08, FE-STATE-07: the export reads records and writes a new file. It does not modify photos or records. The `Exports` row is inserted only after the file is in place.
- FE-CONS-08: one `Copy` label and `Icons.ios_share_outlined` for the command.
- FE-PERF-02: encode the workbook away from the UI thread, with a visible progress state and cancellation that leaves no file and no row.

### Steps

1. Add Export to the project-row overflow and the project-home overflow. Both push `RoutePaths.projectExports(projectId)` for the row that was opened.
2. Replace the exports placeholder with a screen fixed to that project. It lists the project's records, writes one `.xlsx` through `XlsxBook` and `XlsxEncoder`, and stores it under the project `exports/` folder with a new version number. A second export adds a new file and a new `Exports` row. It never replaces an earlier file.
3. After the row is saved, show the file name and a Share action. Share calls `DownloadService.openExternally` for that file. The write button does not share.
4. Render loading, empty (no records), failure, and offline states with `Copy`. Cancellation deletes a partial file and writes no row.
5. Add repository tests for a second version, a corrupt write that leaves the project unchanged, and widget tests that both menus open this project. Make the fast gate green.

### Acceptance criteria

- [ ] Export is visible in the project-row menu and the project-home menu and opens that project.
- [ ] The export writes a new `.xlsx` and a new `Exports` row, and a later export keeps the earlier file.
- [ ] Share runs only after the operator taps Share.
- [ ] Cancelling and a failed write leave records, photos, and earlier exports unchanged.
- [ ] FBK0000086 and FBK0000087 are resolved on the list and on project home.

## Verification

- Run the focused tests named under every work item, plus the project, capture, template, and route suites those files already have.
- Test compact, medium, and expanded widths in portrait and landscape, light, dark, and outdoor themes, and 200 percent text. Test RTL on W6, W7, W9, and W10.
- Regenerate goldens with `--update-goldens` only for the files named in W7, W8, and W10:
  - `frontend/test/features/projects/presentation/goldens/project_list_numbered_pinned_*.png`
  - `frontend/test/features/projects/presentation/goldens/project_list_open_with_menu_*.png`
  - `frontend/test/features/projects/presentation/goldens/project_home_open_with_menu_*.png`
  - `frontend/test/app/goldens/nav_pane_projects_*.png`
- After the last item, the full `cd frontend && dart run tool/verify.dart` is green.
