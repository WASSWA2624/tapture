# 001 — Resolve web capture, caption and template feedback

**Feedback:** FBK0000002, FBK0000003, FBK0000004, FBK0000005, FBK0000155 · **Work items:** 11 · **Depends on:** none

## Goal

In a browser, a photo from the webcam and from the library is kept on the device and shows in the capture tray
and the viewer. On every platform, capture's Project and Template selects are one field tall and sit side by side
with the two saves side by side from medium width up, and the empty tray's icon is itself the add action. Typing
and dictating a caption no longer writes it onto any photo; a button under the field adds it to the photos it
names. Template fields list Required, then Recommended, then Optional; every list search bar with facets carries
the same filter button; and a field's default value fills it when nothing else does.

## Run order

| Item | Title | Feedback | Type | Priority | Effort | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| W1 | Keep capture files in the browser | FBK0000005 | Defect | P2 | M | — |
| W2 | Draw tray thumbnails from bytes in the browser | FBK0000005 | Defect | P2 | S | W1 |
| W3 | Make sheet choice fields one field tall | FBK0000004 | Defect | P3 | S | — |
| W4 | Add a responsive pair | FBK0000004 | Improvement | P4 | S | — |
| W5 | Let an empty state's icon be its action | FBK0000004 | Improvement | P4 | S | — |
| W6 | Give the search field one filter button | FBK0000003 | Improvement | P4 | S | — |
| W7 | Filter templates and project records | FBK0000003 | Improvement | P5 | S | W6 |
| W8 | Lay out capture's selects, saves and empty tray | FBK0000004 | Improvement | P5 | M | W3, W4, W5 |
| W9 | Add a caption to photos only on request | FBK0000155 | Improvement | P5 | M | W8 |
| W10 | Group template fields by requiredness and filter them | FBK0000003 | Improvement | P5 | M | W6 |
| W11 | Fill empty fields from their default | FBK0000002 | Gap | P5 | M | — |

## Decisions

⛔ Stop here. Get an answer to every decision before step 1 of any work item. "Proceed" means the default.

- D1 (W1, W2): where web keeps photo files. Options: (a) in the browser's IndexedDB through the existing
  `BlobStore`, asking the browser for persistent storage on the first write, so a reload keeps them; clearing site
  data still deletes them; (b) no capture on web: the Capture page says capture needs the Android app and hides
  the add controls. Default: (a), because tasks 029 and 030 already make the database and settings work in the
  browser, and the reporter expects web capture to work.
- D2 (W10): what "required fields at the top" changes. Options: (a) the field list shows three sections, Required,
  Recommended, Optional, each in stored order, and moves stay inside a section; the stored order that capture
  and exports use does not change; (b) the stored order itself is re-sorted by requiredness, which also moves
  fields in the capture form and columns in exports. Default: (a), because it answers the screen that was
  reported without changing any output format.
- D3 (W6, W7): which search bars get the filter button. Options: (a) every list whose rows have a fixed facet:
  projects (already has one), template fields (requiredness, type), templates (kind) and a project's records
  (status); pickers inside sheets, the dataset browser and the feedback panel keep search only; (b) projects and
  template fields only. Default: (a), because it standardises every list that has something to filter, and a
  filter button with nothing behind it is a dead control.
- D4 (W11): how a default value is used. Options: (a) processing's validate stage writes the default into a field
  left empty after local and online extraction, unverified, with provenance source `default`, and it counts as
  filled for the record status; (b) as (a), but a required field filled only by its default still sends the
  record to review. Default: (a), because the reporter wants the default to stand in when nothing is determined.
  In both, defaults are not written at save time, because a stored value would stop extraction filling the field.
- D5 (W5, W8): what replaces the empty tray's Add photo button. Options: (a) the tray's large add-photo icon
  becomes the add action itself (a labelled button with focus and hover feedback), and the separate button goes;
  (b) the empty tray shows the same square add tile the tray shows once photos exist, beside the "No photos yet"
  text. Default: (a), because the reporter wants the icon and the words kept and only the button gone, and an
  empty state must still offer its next action (FE-SIMP-11).
- D6 (W9): what the button does to a photo that already has a caption. Options: (a) adds the new text on a new
  line after the existing caption; (b) replaces the existing caption, keeping the old text recoverable as
  `CaptionWrite.previousText`. Default: (a), because the reporter asks to add, and nothing typed earlier is lost
  (FE-SIMP-09).
- D7 (W9): what happens to the field after a successful add. Options: (a) the field clears and a snack says how
  many photos got the caption; (b) the field keeps the text. Default: (a), because the next caption usually goes
  to other photos, and text left in the field is also saved as the record's own caption.

## Rules

- FE-CONS-01, FE-CONS-02, FE-STR-09: reuse `core/` first; a pattern needed twice moves to `core/widgets/` with a
  gallery entry and a golden test.
- FE-STR-11: platform file access stays behind `core/files/` services with interfaces and fakes.
- FE-L10N-01, FE-L10N-02, FE-L10N-03: every new string is a `Copy` key named for its meaning; counts go through
  `Intl.plural`.
- FE-RESP-02, FE-RESP-10, FE-A11Y-01, FE-A11Y-03: size classes come from `context.sizeClass`; layouts are checked
  at compact, medium and expanded widths, both orientations, 200 percent text, and every target stays 48dp.
- FE-THEME-01, FE-THEME-02: tokens only; light, dark and outdoor render from the same tokens.
- FE-TEST-01, FE-TEST-02: tests ship with each item, at the layer FE-TEST-02 names.

## Before the work items

1. Record the work in the plan (FE-FLOW-08). The tool assigns the number. List W1 to W11 in the new task's
   Definition of done, write down the answers to D1 to D7, and note that FBK0000155 supersedes decision D2 of
   task 069 (live caption apply).

   ```bash
   cd frontend && dart run tool/new_task.dart 23-hardening resolve-web-capture-caption-template-feedback "Resolve web capture, caption and template feedback"
   ```

2. Add one more task for the web surfaces W1 and W2 leave out (FE-FLOW-04).

   ```bash
   cd frontend && dart run tool/new_task.dart 23-hardening enable-processing-export-on-web "Enable processing, export and list thumbnails on web"
   ```

## W1 — Keep capture files in the browser

**Feedback:** FBK0000005 · **Type:** Defect · **Priority:** P2 · **Effort:** M · **After:** —

### Evidence
- FBK0000005: on desktop web the camera and photo upload both fail. `screenshots/FBK0000005-2.png` and `-3.png`
  show "Tapture could not write to projects/…/photos/<id>.jpg" after each attempt, and the tray stays empty.
  Web, desktop, expanded, dark.
- Root cause: `frontend/lib/core/files/file_writer.dart:72` writes through `dart:io` `File` (`:103`), which has no
  browser implementation, and `DriftPhotoRepository.readBytes`
  (`frontend/lib/features/capture/data/drift_photo_repository.dart:184`) reads through `File` too. Only
  `BlobStore` (`frontend/lib/core/files/blob_store_web.dart`, IndexedDB) works in a browser. The photo reached the
  writer, so the webcam and the picker are not at fault.

### Scope
- Reach: web at every size class and orientation, in light, dark and outdoor. Android, iOS and desktop keep the
  current writer unchanged. Left out: processing, export and list thumbnails on web; they read `dart:io` files
  (`features/processing/data/*`, `features/exports/data/export_repository_impl.dart`,
  `core/files/thumbnail_cache.dart`) and belong to the task added before the work items.
- Change:
  - `core/files/file_writer.dart` keeps the `FileWriter` interface and chooses its implementation with the
    conditional-import pattern `blob_store.dart` uses: the current `_FileWriter` moves to `file_writer_io.dart`,
    and a new `file_writer_blobs.dart` holds `BlobFileWriter`, a writer over any `BlobStore`. On web the factory
    returns `BlobFileWriter(BlobStore.platform(AppConstants.projectFiles.storeName))`, a new constant
    `'project-files'` shaped like `AppConstants.userFeedback.storeName`.
  - `BlobFileWriter.write` reads the stream, hashes it with sha256, stores the bytes under the relative path, and
    returns the same `WrittenFile` the io writer returns; an existing path is replaced, as the io writer does. It
    uses the io writer's relative-path check, moved from `_safeRelativePath` into `path_sanitizer.dart` so both
    writers share it. `copyIn` returns a `StorageFailure` on web, because browser imports arrive as bytes.
  - Per D1, the first web write asks `navigator.storage.persist()` once, through `dart:js_interop` in
    `file_writer_web.dart`; a refusal does not stop the write.
  - New `core/files/file_reader.dart`: `FileReader` with `Future<Result<Uint8List>> read(String relativePath)`,
    an io implementation reading under `StorageRoot`, `BlobFileReader` over a `BlobStore`, and `FileReader.memory`
    for tests (FE-STATE-10). `DriftPhotoRepository.readBytes` reads through it.
- Do not change: the io writer's `.part`, rename and failure-seam behaviour; `BlobStore`'s key rules.

### Rules
- FE-SEC-08: capture writes each original once, under a new id; markup saves a derived photo. The blob writer
  keeps that: it adds no path a caller did not ask for.
- FE-STATE-07: `write` completes only after IndexedDB confirms the transaction.

### Steps
1. Split the writer and add `BlobFileWriter` and `FileReader` as above, with `AppConstants.projectFiles.storeName`.
2. Point `DriftPhotoRepository.readBytes` at `FileReader`, provided the same way the repository gets its writer.
3. Tests, on the VM with `BlobStore.memory`: `test/core/files/file_writer_blobs_test.dart` (hash and length match
   the io writer's for the same bytes, a rewrite replaces, an invalid path and a failing store return
   `StorageFailure`); `test/core/files/file_reader_test.dart` (io and blob readers return written bytes; a missing
   path is a `StorageFailure`); the photo repository reads bytes written by `BlobFileWriter`.
4. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] With `python run-tools/run-web.py`, a webcam photo and a library photo each save without an error snack.
- [ ] After a browser reload, the saved record's photos still read back through `DriftPhotoRepository.readBytes`.
- [ ] On Android the writer, the `.part` handling and every existing `file_writer` test are unchanged.
- [ ] The blob writer returns the same sha256 and length as the io writer for the same bytes.

## W2 — Draw tray thumbnails from bytes in the browser

**Feedback:** FBK0000005 · **Type:** Defect · **Priority:** P2 · **Effort:** S · **After:** W1

### Evidence
- FBK0000005: the tray is where the reporter expected the photo to appear.
- Root cause: `frontend/lib/core/widgets/app_photo_thumb.dart:72` calls `File(photo.thumbPath).existsSync()` and
  `:243-245` draws `Image.file`; both throw in a browser. The capture tray passes only paths
  (`frontend/lib/features/capture/presentation/photo_tray.dart`), and `CaptureScreen._refreshThumbs`
  (`capture_screen.dart:799`) asks for cached thumbnail files, which web cannot write.

### Scope
- Reach: the capture tray, on web at every size class, orientation and theme; the new-record and edit-record
  trays both. Native trays keep their cached thumbnail files. Left out: record-list and project-cover thumbnails
  on web, in the task added before the work items.
- Change: `PhotoAsset` (`core/widgets/photo_asset.dart`) gains `Uint8List? thumbBytes`. `AppPhotoThumb` draws
  `Image.memory(thumbBytes, cacheWidth: <size × device pixel ratio>)` when it is set, and never constructs a
  `File` on web (`kIsWeb`); a web thumb without bytes shows the existing missing-photo placeholder. `PhotoTray`
  takes `thumbBytes: Map<String, Uint8List>`. On web, `CaptureScreen` passes the bytes it holds in `_bytes`, and
  `_refreshThumbs` fills `_bytes` from `readBytes` (W1) instead of asking for thumbnail files.
- Do not change: the thumbnail's corner controls, caption badge, sizes and rotation.

### Rules
- FE-PERF-04: thumbnails decode at thumbnail size (`cacheWidth`), never the full image in the tray.

### Steps
1. Add `thumbBytes` to `PhotoAsset` and the memory branch to `AppPhotoThumb`.
2. Pass bytes through `PhotoTray` and fill them on web in `CaptureScreen`.
3. Tests: `test/core/widgets/app_photo_thumb_test.dart` draws `Image.memory` with `cacheWidth` set when
   `thumbBytes` is set and the path is empty; add the bytes thumb to the gallery and to
   `test/design_system/app_photo_thumb` goldens.
4. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] With `python run-tools/run-web.py`, a saved photo appears in the tray at once, and again after a reload.
- [ ] Tapping it opens the viewer showing the photo.
- [ ] Native tray thumbnails still come from cached thumbnail files.

## W3 — Make sheet choice fields one field tall

**Feedback:** FBK0000004 · **Type:** Defect · **Priority:** P3 · **Effort:** S · **After:** —

### Evidence
- FBK0000004: the Project and Template selects on Capture are too tall; `screenshots/FBK0000004.png` shows each
  at about 64dp, taller than the caption field's single line. Web, desktop, expanded, dark. The Android
  screenshots in the 26 September 15:50 archive show the same height.
- Root cause: `frontend/lib/core/widgets/fields/app_choice_field.dart:257` wraps the selected label in
  `ConstrainedBox(minHeight: Sizes.minTapTarget)` inside the `InputDecorator`, whose theme padding
  (`frontend/lib/app/theme/app_theme.dart:115`, `Space.x2` above and below) adds 16dp: 48 + 16 = 64.

### Scope
- Reach: every sheet-style `AppChoiceField` on every platform, size class, orientation and theme. The segmented
  choice (`app_choice_field.dart:185`) is unchanged.
- Change: in `_SheetChoice`, remove the inner `ConstrainedBox` and put `BoxConstraints(minHeight:
  Sizes.minTapTarget)` on the `InkWell` around the `InputDecorator`, so the trigger is as tall as a labelled
  single-line `AppTextField` and never under 48dp.
- Do not change: the sheet, its search, the expand icon and the label style.

### Rules
- FE-CONS-03: the gallery and goldens are the contract for the new height.

### Steps
1. Move the minimum height as above.
2. Tests: `test/core/widgets/fields/app_choice_field_test.dart` measures the sheet trigger equal in height to a
   labelled single-line `AppTextField` and at least 48dp, and unclipped at 200 percent text.
3. Regenerate only `test/design_system/app_choice_field` goldens with `--update-goldens`; list them in the task.
4. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] A sheet choice field is exactly as tall as a labelled single-line text field in light, dark and outdoor.
- [ ] Its tap target is at least 48dp at 100 and 200 percent text, and its label is not clipped.

## W4 — Add a responsive pair

**Feedback:** FBK0000004 · **Type:** Improvement · **Priority:** P4 · **Effort:** S · **After:** —

### Evidence
- FBK0000004 asks for two pairs to sit side by side on tablets and larger screens: Project and Template, and
  Save raw and Save and process. Both are stacked today at every width. Two uses make it a shared widget
  (FE-CONS-02).

### Scope
- Reach: any screen that uses it, on every platform; stacked on compact, side by side on medium and expanded, in
  both orientations.
- Change: new `frontend/lib/core/widgets/responsive/responsive_pair.dart`, `ResponsivePair({required Widget start,
  required Widget end, int startFlex = 1, int endFlex = 1, double gap = Space.x3})`. Compact: a stretched
  `Column` of `start`, a `gap`, `end`. Medium and expanded: a `Row` of `Expanded(flex: startFlex)`, a `gap`,
  `Expanded(flex: endFlex)`, top-aligned. It reads `context.sizeClass` (`breakpoints.dart:40`) and follows
  `Directionality` for start and end.
- Do not change: `ResponsiveBuilder` and the breakpoints.

### Rules
- FE-RESP-01, FE-RESP-02: one size-class definition, no width comparison outside `core/widgets/responsive/`.
- FE-L10N-05: start and end, never left and right.

### Steps
1. Add `ResponsivePair` with a documented public API (FE-CODE-12), a gallery entry, and goldens at compact,
   medium and expanded widths in light, dark and outdoor.
2. Tests: `test/core/widgets/responsive/responsive_pair_test.dart` covers stacking on compact, flex widths on
   medium and expanded, and the start-end swap under right-to-left.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] At compact width the two children stack with `start` first.
- [ ] At medium and expanded widths they share one row in the given flex ratio.
- [ ] Under right-to-left, `start` sits on the right.

## W5 — Let an empty state's icon be its action

**Feedback:** FBK0000004 · **Type:** Improvement · **Priority:** P4 · **Effort:** S · **After:** —

### Evidence
- FBK0000004: the empty tray shows an add-photo icon, "No photos yet" and an Add photo button; the reporter
  wants the button gone. `photo_tray.dart:60-66` builds this from `AppEmptyState` with `actionLabel` and
  `onAction`. Per D5(a), the icon becomes the action, which keeps FE-SIMP-11.

### Scope
- Reach: every `AppEmptyState` that opts in, on every platform, size class, orientation and theme. Existing
  callers are unchanged.
- Change: `frontend/lib/core/widgets/states/app_empty_state.dart` gains `VoidCallback? onIconTap` and
  `String? iconLabel`. With both set, the icon circle is a button: `Semantics(button: true, label: iconLabel)`,
  a tooltip of `iconLabel`, ink, focus and hover feedback from the theme, and at least a 48dp target. The
  constructor asserts that `onIconTap` and `actionLabel` are not both set.
- Do not change: the headline, message and action-button layout for existing callers.

### Rules
- FE-A11Y-01, FE-A11Y-02: 48dp and a label on the icon button.
- FE-CONS-04: the empty state stays the one empty-state widget.

### Steps
1. Add `onIconTap` and `iconLabel` as above, with a gallery entry.
2. Tests: `test/core/widgets/states/app_empty_state_test.dart` covers a tap on the icon calling `onIconTap`, the
   semantics label, the 48dp target, and a plain icon when `onIconTap` is null. Add the icon-action state to the
   `test/design_system/app_empty_state` goldens.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] An empty state with `onIconTap` announces its icon as a button named `iconLabel`, and a tap calls it.
- [ ] Every existing empty state renders exactly as before.

## W6 — Give the search field one filter button

**Feedback:** FBK0000003 · **Type:** Improvement · **Priority:** P4 · **Effort:** S · **After:** —

### Evidence
- FBK0000003 asks for a filter button in the search bar, the same on every search bar, from a reusable
  component. `frontend/lib/core/widgets/app_search_field.dart` offers only a generic `afterMic` slot; the
  projects toolbar builds its own filter button in it (`project_list_toolbar.dart:26`), and no other search bar
  has one (`screenshots/FBK0000003.png` shows the template-field search without one).

### Scope
- Reach: every `AppSearchField` given `onFilter`, on every platform, size class, orientation and theme.
- Change: `AppSearchField` gains `VoidCallback? onFilter` and `int activeFilterCount = 0`. With `onFilter` set it
  draws, after the microphone, the button the projects toolbar draws today: `AppIconButton(icon:
  AppIcons.filter, tooltip and semanticLabel: Copy.searchFilters(activeFilterCount), selected:
  activeFilterCount > 0 ? true : null, outlined: false)`. `Copy.searchFilters` replaces `Copy.projectFilters`
  with the same text. `ProjectListToolbar` moves to `onFilter` and `activeFilterCount`. `afterMic` stays for
  controls that are not filters.
- Do not change: debounce, `text` syncing, the result count and the microphone.

### Steps
1. Add the two parameters and `Copy.searchFilters`; migrate `ProjectListToolbar`; delete `Copy.projectFilters`.
2. Tests: `test/core/widgets/app_search_field_test.dart` covers the button appearing with `onFilter`, its label
   with and without active filters, and a tap calling `onFilter`. Add the filter state to the gallery and the
   `test/design_system/app_search_field` goldens. Existing projects filter tests still pass.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] The projects search shows the same filter button as before, now drawn by `AppSearchField`.
- [ ] A search field without `onFilter` shows no filter button.

## W7 — Filter templates and project records

**Feedback:** FBK0000003 · **Type:** Improvement · **Priority:** P5 · **Effort:** S · **After:** W6

### Evidence
- FBK0000003: "standardise all search bars to have a filter button". Per D3(a), the lists with a fixed facet get
  one: templates by kind (`template_list_screen.dart:91`) and a project's records by status
  (`project_home_screen.dart:161`, listed by `CapturedItems`).

### Scope
- Reach: the templates list and the project home records list, on every platform, size class, orientation and
  theme. Left out, per D3: the pickers inside sheets (`app_choice_field.dart:333`,
  `app_multi_choice_field.dart:154`, `context_picker_sheet.dart:122`, `shipped_picker_screen.dart:202`), the
  dataset browser (`dataset_browser_screen.dart:89`), the feedback panel (`feedback_filter_panel.dart:82`) and the
  shell placeholder (`router.dart:998`).
- Change:
  - New `features/templates/presentation/template_list_filter.dart`: `TemplateListFilter`, a `Notifier<Set<String>>`
    of chosen kinds, and `templateListFilterProvider`. The templates search gets `onFilter` opening one
    `showAppSheet` with an `AppMultiChoiceField` of the kinds present, and a clear action labelled
    `Copy.searchClearFilters` ('Clear filters'). The list shows templates matching the search and the kinds.
  - New `features/projects/presentation/captured_items_filter.dart`: `CapturedItemsFilter`, a
    `Notifier<Set<RecordStatus>>`, and its provider. The records search gets the same sheet over the statuses
    present, labelled with the status pill's `Copy` labels; `CapturedItems` shows records matching both.
- Do not change: search matching, list order and paging.

### Steps
1. Add both filters, their sheets and `Copy.searchClearFilters` plus a sheet title per list.
2. Tests: widget tests in `test/features/templates/presentation/template_list_screen_test.dart` and
   `test/features/projects/presentation/project_home_screen_test.dart`: choosing a facet narrows the list, the
   button counts active facets, clearing restores the list, and search and filter combine.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] The templates search has the filter button, and choosing a kind lists only that kind.
- [ ] A project's records search has the filter button, and choosing a status lists only records in it.
- [ ] Each filter button shows how many facets are on, and Clear filters turns them all off.

## W8 — Lay out capture's selects, saves and empty tray

**Feedback:** FBK0000004 · **Type:** Improvement · **Priority:** P5 · **Effort:** M · **After:** W3, W4, W5

### Evidence
- FBK0000004 (`screenshots/FBK0000004.png`, web, expanded, dark): Project and Template are stacked, Save raw and
  Save and process are stacked, and the empty tray shows both the add-photo icon and an Add photo button.
- Code: `capture_target_fields.dart:92` and `:106` stack the two fields; `capture_screen.dart:283` stacks the
  footer saves; `photo_tray.dart:60-66` builds the empty tray's button.

### Scope
- Reach: the Capture page on every platform. Stacked on compact; side by side on medium and expanded, in both
  orientations; light, dark and outdoor; 200 percent text. The edit-record footer, a single primary action, is
  unchanged.
- Change:
  - `CaptureTargetFields`: when both fields show, they sit in `ResponsivePair(start: project, end: template)`;
    with one field it stays full width. The gate message stays below the pair.
  - `CaptureScreen` footer, new records only: `ResponsivePair(start: Save raw, end: Save and process, startFlex: 1,
    endFlex: 2)`, so the primary action stays the largest and trailing control (FE-SIMP-01). The offline caption
    stays under Save and process. Compact keeps today's order, Save raw above.
  - `PhotoTray` empty state per D5(a): `AppEmptyState(icon: AppIcons.addPhoto, headline:
    Copy.captureNoPhotosHeadline, message: Copy.captureNoPhotosMessage, onIconTap: onAdd, iconLabel:
    Copy.captureAddPhoto)`, with no `actionLabel`. While capture is not ready, `onAdd` is null and the icon is
    not a button; the gate message says why.
- Do not change: the tray with photos, the caption field, the inline fields and save behaviour.

### Steps
1. Apply the three changes.
2. Tests: `test/features/capture/presentation/capture_widgets_test.dart` covers selects and saves side by side at
   medium and expanded, stacked at compact, the primary wider than Save raw, the empty tray with no Add photo
   button, and a tap on its icon opening the photo source sheet. Assert 48dp targets and no overflow at 200
   percent text at every width.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] At medium and expanded widths, Project and Template share a row, and so do Save raw and Save and process.
- [ ] At compact width all four stack in today's order.
- [ ] The empty tray has no Add photo button; tapping its icon opens the photo source sheet.
- [ ] Nothing overflows at 200 percent text in portrait and in landscape.

## W9 — Add a caption to photos only on request

**Feedback:** FBK0000155 · **Type:** Improvement · **Priority:** P5 · **Effort:** M · **After:** W8

### Evidence
- FBK0000155: typing and recording should not add the caption to the selected and eligible photos by
  themselves; adding should take a button tap. `screenshots/FBK0000155.png` shows two ticked photos, "Testing
  captions" in the field and the line "Goes to 2 ticked photos": the text is already on both photos. Android,
  compact, portrait, light.
- Root cause: `frontend/lib/features/capture/presentation/capture_screen.dart:354-400`. The field's `onChanged`
  writes the record caption (`setCaption(null, text)`) and then, on every keystroke, replaces the caption of
  every target photo (`applyCaptions`, `CaptionApplyMode.replace`, `:379`). Targets are the ticked photos, and all
  photos when none is ticked (`CaptionApply.targets`, `features/capture/domain/caption_apply.dart`). Dictation
  types into the same field, so it takes the same path. This is task 069's D2, which FBK0000155, reported
  after using it, reverses; its request to add a caption to several photos before saving (FBK0000149) stays met
  through the button.

### Scope
- Reach: the Capture page and the record-edit page (the same `CaptureScreen`), on every platform, size class
  and orientation, in light, dark and outdoor, at 200 percent text. No surface is left out.
- Change (W8 has already moved the footer saves into a `ResponsivePair` and changed the empty tray; the caption
  block it leaves untouched, so the line numbers below are those before W8):
  - `RecordCaptionField` (`capture/presentation/record_caption_field.dart`): rename `targetKey` to `resetKey`,
    documented as "changes when the caption is replaced from outside; [value] then replaces the typed text".
  - `CaptureScreen`: the field's `value` is `session.recordCaption`. Its `onChanged` only calls
    `controller.setCaption(null, text)`; the `applyCaptions` call leaves `onChanged`. `resetKey` is a count in
    the screen's UI state that goes up after each successful add.
  - The "Goes to …" line (`:406-418`) becomes an `AppButton` (secondary, full width), shown while the session
    has at least one visible photo. It reads `Copy.captionAddToTicked(n)` with photos ticked, and
    `Copy.captionAddToAll(n)` with none ticked, where `n` is the target count. It is enabled when the trimmed
    text is not empty and capture is ready.
  - A tap applies `CaptionApply.apply(photoIds: targets, text: trimmed, mode: CaptionApplyMode.append, existing:
    session.captions)` per D6. On success, per D7, it calls `setCaption(null, '')`, raises `resetKey` and shows
    `showAppSnack(context, Copy.captionAdded(n))`. On failure it shows `Copy.captureSaveFailed` with
    `SnackTone.error` and keeps the text.
  - `Copy`: remove `captionGoesToAll` and `captionGoesToTicked`; add `captionAddToAll(int n)` ('Add to the
    photo' for one, 'Add to all $n photos'), `captionAddToTicked(int n)` ('Add to 1 ticked photo', 'Add to $n
    ticked photos') and `captionAdded(int n)` ('Added to the photo', 'Added to $n photos').
- Do not change: ticking by long press and the corner control, the per-photo caption edit in the viewer
  (`capture_screen.dart:564-575`), the audio recorder, the save paths, and the record caption written on save
  (`capture_record_writer.dart:171`).

### Rules
- FE-STATE-07: the typed text persists as the record caption on every keystroke, as it does today.
- FE-SIMP-01: Save and process stays the screen's primary action; the new button is secondary.
- FE-SIMP-09: a failed add keeps the typed text.
- FE-A11Y-07: the result of an add is announced by the snack.

### Steps
1. Rename `targetKey` to `resetKey` in `RecordCaptionField` and its callers.
2. Change `CaptureScreen` and `Copy` as above.
3. Update the caption tests in `test/features/capture/presentation/capture_feedback_test.dart` (the target-line,
   200-percent, one-photo and none-ticked tests at `:230-300`) and
   `test/features/capture/presentation/capture_edit_screen_test.dart` to the new behaviour, and add cases:
   typing and dictating change no photo caption; the button label for none and for some ticked; a tap appends
   to existing captions per D6, clears the field and shows the snack per D7; a failed add keeps the text;
   untouched text is saved as the record caption; the button has a 48dp target and no clipping at 200 percent
   text at compact, medium and expanded widths in both orientations.
4. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] Typing in the caption field, and dictating into it, changes no photo's caption.
- [ ] With no photo ticked the button reads "Add to all n photos"; with some ticked it reads "Add to n ticked
      photos".
- [ ] A tap adds the text to exactly those photos, after any caption they already have, then clears the field
      and says how many photos got it.
- [ ] Text never added is saved as the record's own caption.
- [ ] A failed add keeps the typed text and shows the save-failed snack.
- [ ] The button is at least 48dp and unclipped at 200 percent text at every width, in portrait and in
      landscape, in light, dark and outdoor.
- [ ] FBK0000155 is resolved on the Capture page and the record-edit page, and FBK0000149's ask, adding a
      caption to several photos before saving, still works through the button.

## W10 — Group template fields by requiredness and filter them

**Feedback:** FBK0000003 · **Type:** Improvement · **Priority:** P5 · **Effort:** M · **After:** W6

### Evidence
- FBK0000003 (`screenshots/FBK0000003.png`, web, expanded, dark): the field list mixes Required and Optional
  fields in stored order ("Record status" sits between optional fields), and its search has no filter.
- Code: `field_list_screen.dart:171` builds one `ReorderableListView` over `loaded.fields`; the search is at `:120`.

### Scope
- Reach: the template field list on every platform, size class, orientation and theme.
- Change, per D2(a):
  - The unfiltered list shows sections in the order Required, Recommended, Optional, each under an
    `AppSectionHeader` titled with `Copy.fieldRequired`, `Copy.fieldRecommended` and `Copy.fieldOptional`; an
    empty section is omitted. Within a section, fields keep their stored order.
  - Up, down and drag move a field only within its section, by swapping the stored positions of the two fields
    concerned in `_fieldListProvider.reorder`. Up is disabled on a section's first row, down on its last.
  - New `features/templates/presentation/field_list_filter.dart`: `FieldListFilter`, a `Notifier` of the chosen
    requiredness values and field types, and its provider. The search's `onFilter` opens one `showAppSheet` with
    two `AppMultiChoiceField`s, requiredness and the types present, and a `Copy.searchClearFilters` action.
    Search and filter combine. While a search is typed and while a filter is on, the list is flat without drag,
    as search makes it today.
- Do not change: the stored order capture and exports read, the add-field action and the row menu.

### Steps
1. Add the sections, the section-bound moves and the filter.
2. Tests: `test/features/templates/presentation/field_list_screen_test.dart` covers the section order, a move
   staying inside a section, the disabled edge arrows, a filter narrowing by requiredness and by type, the
   filter count, and the stored order after a move changing only the two swapped fields.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] Required fields list first, then Recommended, then Optional.
- [ ] A move never crosses a section, and the stored order changes only for the two fields swapped.
- [ ] The field search has the filter button, and requiredness and type filters narrow the list.

## W11 — Fill empty fields from their default

**Feedback:** FBK0000002 · **Type:** Gap · **Priority:** P5 · **Effort:** M · **After:** —

### Evidence
- FBK0000002: a default value should be used when nothing is entered and when the value cannot be determined.
- Code: `FieldDef.defaultValue` exists (`features/templates/domain/field_def.dart:42`) and the field sheet edits
  it under Advanced (`field_add_sheet.dart:220-232`), but nothing applies it: `defaultValue` is read only inside
  `features/templates`. The reporter did not find the input, and the field row does not show a default.

### Scope
- Reach: processing on every platform, and the template field row everywhere it renders.
- Change, per D4(a):
  - `ProposalApplication.apply` (`features/processing/domain/proposal_application.dart`) takes
    `Map<String, String> defaults`. A field with a default that has no stored value, no verified value, no
    hand-entered value and no write in the plan gets a write with the default, confidence 1.0, provenance
    source `default`, method `template-default`, provider `template`, and no evidence row. It counts as filled
    for the status.
  - `ValidateStage.run` (`features/processing/data/validate_stage.dart:69`) passes each field's non-empty
    `defaultValue` from `bundle.fields`; the write goes through `insertProcessingProposal` with the provenance
    audit, like any proposal.
  - `_FieldRow` (`field_list_screen.dart:208`) appends `Copy.fieldRowDefault(value)`, 'Default: <value>', to the
    subtitle when a default is set. The input stays under Advanced (FE-SIMP-06).
- Do not change: extraction and the guard. A default never replaces a stored value: extracted, verified and
  hand-entered values all stay.

### Rules
- FE-SEC-09: every default written carries its provenance in the audit trail.
- FE-STR-05: `ProposalApplication` stays pure Dart.

### Steps
1. Extend `ProposalApplication` and pass defaults from the validate stage.
2. Add `Copy.fieldRowDefault` and show it on the field row.
3. Tests: `test/features/processing/domain/proposal_application_test.dart` (a default fills an empty field; an
   extracted, verified and hand-entered value each win; a required field filled by its default leaves the status
   `EXTRACTED`); `test/features/processing/data/validate_stage_test.dart` (the default is stored with source
   `default`, no evidence row, and its audit); a field-row widget test showing the default.
4. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] After processing, a field left empty that has a default holds the default, unverified, with source `default`.
- [ ] Extracted, verified and hand-entered values all stay; the default fills only an empty field.
- [ ] The field list shows "Default: <value>" under a field that has one.

## Verification

- After the last item, the full `cd frontend && dart run tool/verify.dart` is green except for failures that
  predate this prompt, which the task records by name.
- Regenerate goldens with `--update-goldens` only for `app_choice_field` (W3), `responsive_pair` (W4),
  `app_empty_state` (W5), `app_search_field` (W6) and `app_photo_thumb` (W2), and list the files under each item.
  W9 changes no golden: its button is the catalogue `AppButton`.
