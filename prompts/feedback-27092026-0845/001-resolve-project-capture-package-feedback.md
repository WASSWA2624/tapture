# 001 — Resolve project, capture, template and package feedback

**Feedback:** FBK0000006, FBK0000007, FBK0000156, FBK0000157, FBK0000158, FBK0000159, FBK0000160, FBK0000161,
FBK0000162 · **Chat requests:** R1, R2, R3 · **Work items:** 22 · **Depends on:** none

The chat requests come from the operator's instruction that commissioned this prompt (27 September 2026), not from
a feedback row:

- **R1** — The project export produces one ZIP holding every file, setting and table another Tapture app needs to
  open the project on another device.
- **R2** — Another Tapture app can import that ZIP, and can merge it into a project built from the same,
  compatible templates, after a compatibility check.
- **R3** — The import offers a check for possible duplicates that the operator can switch off, and a person
  decides each pair, because similar content is not always the same thing.

Screenshots are under `prompts/TAPTURE-27092026-0843/screenshots/` (FBK0000002 to FBK0000007) and
`prompts/TAPTURE-27092026-0845/screenshots/` (FBK0000156 to FBK0000162).

## Goal

Saving a project's details confirms the save, a read-only details page precedes the edit form, the expanded
projects pane keeps its border and marks the open project, and the Project contexts page is padded and uncrowded.
On Capture, the two saves share one equal row at every width, context values can be seen and set in place, and a
guide built from the template says what the photos and caption should cover. On the record page, a tap on a field
edits it with a typed input. The template library groups its catalogue into collapsible categories and ranks a
typed description by relevance. The project export writes one ZIP package that another Tapture app imports as a
new project or merges into a compatible one after a compatibility check, with possible duplicates settled by a
person. All of this lands on Android, iOS, web, Windows, macOS and Linux, at compact, medium and expanded widths,
in both orientations, in light, dark and outdoor themes, at 200 percent text. The only exceptions are the web size
ceiling in D6 and the surfaces each item names.

## Run order

| Item | Title | Feedback | Type | Priority | Effort | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| W1 | Confirm a saved project and release the unsaved guard | FBK0000156 | Defect | P3 | S | — |
| W2 | Keep the pane border and mark the open project | FBK0000007 | Defect | P3 | S | — |
| W3 | Lay out the Project contexts page | FBK0000006 | Defect | P3 | M | — |
| W4 | Let a responsive pair share one row on compact | FBK0000158 | Improvement | P4 | S | — |
| W5 | Share search folding and word matching in core | FBK0000161, R3 | Improvement | P4 | S | — |
| W6 | Let a section header collapse its section | FBK0000161 | Improvement | P4 | S | — |
| W7 | Pick a document on every platform | R2 | Gap | P4 | M | — |
| W8 | Save and share a stored package without loading it whole | R1 | Gap | P4 | M | — |
| W9 | Write the project package | R1 | Gap | P4 | L | — |
| W10 | Read and verify a project package | R2 | Gap | P4 | M | W9 |
| W11 | Add a read-only project details page | FBK0000156 | Gap | P5 | M | W1 |
| W12 | Put Save raw and Save and process in one equal row | FBK0000158 | Improvement | P5 | S | W4 |
| W13 | Fill a record's fields by hand from the record page | FBK0000162 | Improvement | P5 | M | — |
| W14 | See and change context from Capture | FBK0000160 | Gap | P5 | M | — |
| W15 | Group the template library into collapsible categories | FBK0000161 | Improvement | P5 | M | W6 |
| W16 | Rank library search and accept a description | FBK0000161 | Improvement | P5 | M | W5, W15 |
| W17 | Export the whole project as one package | R1 | Gap | P5 | M | W8, W9 |
| W18 | Show a capture guide built from the template | FBK0000157, FBK0000159 | Suggestion | P6 | M | W12 |
| W19 | Import a package as a new project | R2 | Suggestion | P6 | M | W7, W10 |
| W20 | Check template compatibility before a merge | R2 | Suggestion | P6 | M | W19 |
| W21 | Merge a package into a project | R2 | Suggestion | P6 | L | W20 |
| W22 | Check incoming records for possible duplicates | R3 | Suggestion | P6 | M | W5, W21 |

## Decisions

⛔ Stop here. Get an answer to every decision before step 1 of any work item. "Proceed" means the default.

- D1 (W1): how a form learns that its save worked. Options: (a) `AppForm.onSubmit` becomes
  `Future<bool> Function()`, where `true` clears the form's unsaved mark; all nine callers return their result;
  (b) `AppForm` gains a separate `onSaved` notifier and keeps `Future<void>`. Default: (a), because one callback
  that reports its outcome cannot drift from the save it describes.
- D2 (W2): what marks the open project in the list. Options: (a) the `surfaceVariant` fill, a 4dp `primary` bar on
  the start edge, the title in `primary` and the row announced as selected; the multi-select tick stays separate;
  (b) the fill alone, plus the announcement. Default: (a), because colour is never the only signal (FE-A11Y-05),
  and the bar keeps the open row distinct from a ticked one.
- D3 (W3): how the Project contexts rows are tidied. Options: (a) remove the plain level-name diagram, which
  repeats the list below it, and give each row one overflow menu holding Edit and Remove at every width; (b) keep
  the diagram inside a padded card, and keep the two buttons with an 8dp gap. Default: (a), because it removes the
  duplicate list and matches the project rows' menu (FE-CONS-01).
- D4 (W4, W12): width of the two capture saves, against FE-SIMP-01 ("It is the largest control"). Options:
  (a) equal widths in one row at every width, as FBK0000158 asks. FE-SIMP-01 then reads "No other control is
  larger, it sits in the lower third, and it is reachable with one thumb", and the primary stays marked by its fill
  and its end position. No test enforces FE-SIMP-01, so only the rule file changes (FE-FLOW-07). (b) One row at
  every width with Save and process wider, 3 to 2, and the rule untouched. Default: (a), because the reporter
  asked for the same width in words, and the change to the rule is one sentence.
- D5 (W7): how a document is picked. Options: (a) in-house, mirroring `FolderPicker`: native channel methods on
  Android and iOS, the desktop commands `FolderPicker` already runs, and a file input on web, with no new
  dependency; (b) add the `file_picker` package, which needs an allowlist entry, a licence check and a task of its
  own (FE-FLOW-06). Default: (a), because the pattern and its channels exist, and a new plugin brings build-tool
  upgrades this repository has already had to hold back.
- D6 (W8, W9, W10): package size and delivery. Options: (a) on native platforms the package streams to the
  project's `exports/` folder and is saved or shared from there by a streamed copy. Both the export and the import
  ceilings rise to `AppConstants.bundles.nativeMaxBytes` = 4,000,000,000 bytes, which stays under the ZIP32
  limit, so no ZIP64 is needed. The uncompressed ceiling becomes that value plus 10 percent. On web the package is
  built in memory and capped at the existing 200 MiB `bundleMaxBytes`. (b) Every platform builds the package in
  memory under 200 MiB. Default: (a), because a project with its photos passes 200 MiB within a day of field
  work.
- D7 (W9): what the package carries. Options: (a) every project-owned table and every file a row references. That
  covers the project row and its settings, context levels and presets, templates with their fields, rows and
  version history, the project's reference datasets and the global datasets its fields or levels look up, records,
  field values (raw, refined, final and provenance), field evidence, captions, photos, attachments with their
  owners, meetings, attendees, actions, variances, processing results, duplicate pairs, audit rows and tombstones,
  plus the cover photo. It leaves out capture drafts, the processing queue, the OCR cache, thumbnails and `.cache`,
  export history and old export files, device settings, the operator profile, and anything in secure storage.
  (b) As (a), plus capture drafts. Default: (a), because a draft belongs to the device that is capturing it, and
  the export screen says so.
- D8 (W11): the project's read and update pages. Options: (a) a new read-only page at `/projects/<id>/details`,
  which the "Project details" menu items open. Its primary action, Edit details, opens today's form at
  `/projects/<id>/edit`, now titled "Edit project", and a save returns to the details page. (b) Keep one page that
  opens read-only, with an Edit switch. Default: (a), because the reporter asked for proper CRUD pages, and create,
  update and delete already have their own.
- D9 (W13): where the all-fields editor lives. Options: (a) the Fields heading on the record page gets an "Edit
  fields" button, and the overflow item with the same name goes; (b) keep the overflow item as well. Default: (a),
  because one visible way in is simpler than two, one of them hidden.
- D10 (W14): where Capture shows context. Options: (a) the shell's context bar, on the Capture tab only, shows
  every level of the open project, set or not, plus a Manage chip; other tabs keep today's bar; (b) a Context
  section inside the Capture page body. Default: (a), because the bar, its chips and its picker sheet already exist,
  and a second context control would repeat them.
- D11 (W15): how the catalogue is grouped. Options: (a) area headings stay; the 72 categories under them become
  collapsible headings with a count, collapsed by default; a category holding a ticked template opens expanded;
  (b) a flat list with a jump-to-area index. Default: (a), because 2,349 rows become 17 areas and 72 named groups
  on one screen.
- D12 (W16): AI search. Options: (a) now, ranked on-device search that accepts a plain description and works
  offline. AI-ranked suggestions become a plan task, because production has no AI provider
  (`ProviderRegistry.keyless()`, `frontend/lib/main.dart:127`), `AiService` has no ranking call, and the backend's
  AI endpoints (spec §74.2) include no search; (b) also add a "Suggest with AI" action now, through
  `extractFields` with a choice field over the top local matches, as `TemplateAssist` does. It stays hidden while
  AI is unavailable, which is every current build, and it opens a new egress purpose (FE-SEC-03). Default: (a),
  because it makes search work everywhere today without an egress change nobody can run yet.
- D13 (W17): the export's output. Options: (a) Export writes one ZIP, the project package, which also carries the
  workbook today's export writes, as `records.xlsx`; the separate XLSX-only export goes; (b) Export offers two
  outputs, the workbook and the package, with the package chosen by default. Default: (a), because R1 asks that
  the project export produce one ZIP, and nothing the workbook held is lost.
- D14 (W18): the guide's form. Options: (a) under the Template select, a one-line "What to capture" row that
  expands to the photo and caption lists, collapsed by default. While the caption field has focus, or dictation or
  recording runs, the caption list shows in a small panel directly above the field; it takes no focus and can be
  closed. (b) An always-expanded card. Default: (a), because FBK0000159 asks for the hint while typing or
  recording, and a card that is always open pushes the saves down on a phone.
- D15 (W20): how strict compatibility is. Options: (a) a merge is blocked, with the reasons named, when an
  incoming record uses a template with no local match, when an incoming field that holds values is missing
  locally, or when its type cannot hold the incoming values. Other differences are warnings that do not block.
  (b) As (a), but a missing field with values is added to the local template as a new template version before the
  merge. Default: (a), because the request is for projects built from the same templates, and changing a local
  template on import is its own decision.
- D16 (W21): how the merge settles records. Options: (a) by content. An entity new to this device is inserted,
  identical content is skipped, and differing values go through the specification's three automatic rules (§47),
  then to a person. Tombstones compare their delete time with the other side's last update, and an unclear case
  goes to a person. There is no undo; the preview and a person's confirmation come first, and the audit trail keeps
  every earlier value. (b) First maintain version vectors on every write in `BaseDao`, with a baseline migration,
  then merge by vector. Default: (a), because version vectors are never written today (the only caller of
  `bumpVersionVector` is `resolveMergeConflict`, `frontend/lib/core/db/tables/merge_conflicts.dart:153`), and
  vectors and undo belong to task 019.
- D17 (W22): the duplicate check. Options: (a) a "Check for possible duplicates" switch on the merge preview, on
  by default. Pairs are found before anything is written, and each pair offers "Keep both", the default, or "Don't
  import this record". Every pair is stored for later review, and nothing is decided automatically. (b) The same
  check, but off by default. (c) Scan only after the merge, and review the pairs later. Default: (a), because R3
  wants a person to decide, and deciding before the write lets an unwanted copy never enter the project.

## Rules

- FE-CONS-01, FE-CONS-02, FE-STR-09: reuse `core/` first; a pattern needed twice moves to `core/` with a gallery
  entry and a golden test in the same change.
- FE-STR-04, FE-STR-05, FE-STATE-05: domain logic (ranking, guide, compatibility, merge plan, duplicate signals)
  is pure Dart under `domain/`; tables are reached through repositories.
- FE-STR-11: platform access (pickers, downloads, share) stays behind `core/files/` services with interfaces and
  fakes.
- FE-L10N-01, FE-L10N-02, FE-L10N-03, FE-L10N-07: every new string is a `Copy` key named for its meaning; counts
  use `Intl.plural`; template labels, context values and catalogue text are data, never translated or matched
  against a translation.
- FE-RESP-02, FE-RESP-10, FE-A11Y-01, FE-A11Y-03: size classes come from `context.sizeClass`; every changed screen
  is checked at compact, medium and expanded widths, both orientations and 200 percent text, with 48dp targets.
- FE-THEME-01, FE-THEME-02: tokens only; light, dark and outdoor render from the same tokens.
- FE-SEC-05, FE-SEC-06: everything read from a package is untrusted data, validated before use.
- FE-PERF-02: hashing, zipping, unzipping, planning and duplicate scoring run through the isolate runner, with
  progress and cancel.
- FE-TEST-01, FE-TEST-02: tests ship with each item, at the layer FE-TEST-02 names.

## Before the work items

1. Record the work in the plan (FE-FLOW-08). The tool assigns the number. List W1 to W22 in the new task's
   Definition of done, write down the answers to D1 to D17, and note that FBK0000158 supersedes task 070's
   decision that Save and process is twice as wide (W8 of task 070).

   ```bash
   cd frontend && dart run tool/new_task.dart 24-product-refinements resolve-project-capture-package-feedback "Resolve project, capture and template feedback, and add project packages"
   ```

2. Note the overlap in the owning phase tasks, without ticking anything there. In
   `dev-plan/19-bundles-and-merge/019-bundles-and-merge.md`, add a line under **Implement** naming the new task as
   the one that ships these parts: the package format, writer and reader, import as a new project, the template
   compatibility check, the content merge with its preview and conflicts, and duplicate decisions before a merge.
   The line also says what 019 still owns: scopes, passwords, the secret-pattern scan, version vectors,
   tombstone vectors, undo, merge history, Type a value and Decide later, and file-open registration. In
   `dev-plan/18-export/018-export.md`, add a line saying that, per D13, the project export writes the package.

3. Add the plan tasks for work this prompt leaves out (FE-FLOW-04).

   ```bash
   cd frontend && dart run tool/new_task.dart 24-product-refinements suggest-shipped-templates-with-ai "Suggest shipped templates with AI"
   ```

   ```bash
   cd frontend && dart run tool/new_task.dart 24-product-refinements keep-device-id-in-storage-root "Keep the device id in the storage root"
   ```

   The first task names D12's reasons. It depends on task 024 for a provider behind the backend proxy. The second
   records that the device id lives in the OS temp folder (`frontend/lib/core/device/device_io.dart:4-6`), and
   only in memory on web. A package names its source device, so an id that changes after a temp clean makes one
   device look like two.

## W1 — Confirm a saved project and release the unsaved guard

**Feedback:** FBK0000156 · **Type:** Defect · **Priority:** P3 · **Effort:** S · **After:** —

### Evidence
- FBK0000156: on Project details, Save "doesn't work". `screenshots/FBK0000156.png` shows the edit form, titled
  "Project details", with a cover photo and the Save bar. Android, compact, portrait, light.
- Root cause: the save succeeds, but nothing says so.
  - `frontend/lib/features/projects/presentation/project_edit_screen.dart:151-159` awaits `_ProjectEdit.submit`
    (`:312-372`), which returns `true` after `ProjectRepositoryImpl.update`, then drops the result. There is no
    snack and no navigation.
  - `AppForm` marks itself edited on the first keystroke (`frontend/lib/core/widgets/forms/app_form.dart:125-129`)
    and never clears the mark. So `PopScope(canPop: !_shouldGuard)` (`:171-173`) still asks "Discard changes?"
    after a good save (`:145-159`).
  - The project settings form has the same gap (`project_settings_screen.dart:195-199`).
- Second cause: the form reads the *open* project through `currentProjectDetailsProvider` (`:54`), which looks it
  up in `projectListProvider`. That list hides archived projects (`current_project.dart:121-134`), so saving with
  Status set to Archived swaps the form for "No project open".

### Scope
- Reach: every platform, size class, orientation and theme, and every `AppForm` caller. No surface is left out.
- Change, per D1(a):
  - `AppForm.onSubmit` becomes `Future<bool> Function()`. After `true`, `AppForm` clears `_edited`; after `false`,
    the guard stays.
  - Every caller returns its outcome: `project_create_screen.dart`, `project_edit_screen.dart`,
    `project_settings_screen.dart`, `give_feedback_screen.dart`, `app_lock_screen.dart`,
    `operator_profile_screen.dart`, `field_add_sheet.dart`, `shipped_picker_screen.dart`,
    `template_create_screen.dart` and the gallery entry in `widget_gallery_screen.dart`.
  - On `true`, the project edit form shows `showAppSnack(context, Copy.projectSaved)` ('Project saved'). The
    project settings form does the same with `Copy.projectSettingsSaved` ('Settings saved').
  - `ProjectEditScreen` takes `projectId` from the route (`frontend/lib/app/router.dart:485-491`). It reads the
    project through a new `projectByIdProvider` family in `current_project.dart`, built over
    `ProjectRepository.watchAll(includeArchived: true)`, so an archived project stays editable.
  - After a save, `_bind` (`:182-199`) takes the saved row as its new `_source`. Today it returns early for the
    same id, so a second save starts from stale values.
- Do not change: validation, the cover photo's immediate store (`:139-148`), or the create flow's navigation.

### Rules
- FE-STATE-07: the snack follows the durable write. FE-SIMP-09: a failed save keeps the input and the guard.
- FE-CONS-05: one snack API. FE-A11Y-07: the snack announces the save.

### Steps
1. Change `AppForm` and its callers.
2. Change the project edit and settings forms as above.
3. Tests:
   - `test/design_system/app_form/`: after `onSubmit` returns `true`, back pops without a prompt; after `false`,
     the prompt remains.
   - `test/features/projects/presentation/project_edit_screen_test.dart`:
     - a save shows "Project saved";
     - back after a save does not prompt;
     - saving as Archived keeps the form;
     - a second save starts from the stored values.
4. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] Saving project details shows "Project saved", and leaving afterwards asks nothing.
- [ ] A failed save keeps the typed values and still asks before leaving.
- [ ] Saving a project as Archived keeps the form on screen with the saved values.
- [ ] Every `AppForm` in the app still submits; a save that fails keeps its guard.

## W2 — Keep the pane border and mark the open project

**Feedback:** FBK0000007 · **Type:** Defect · **Priority:** P3 · **Effort:** S · **After:** —

### Evidence
- FBK0000007: in the list pane under the search bar, the pane's right border disappears beside the rows, and the
  selected project should look distinct. `screenshots/FBK0000007.png` (web, expanded, landscape, light) shows the
  border running down to the search field, gone beside both rows, and back below them. "Error" is the open project,
  and its row looks like "Testing".
- Root cause:
  - `frontend/lib/app/nav_shell.dart:225-233` draws the pane's end border as the `DecoratedBox` background, and
    every `AppListTile` paints an opaque `Material` over it (`frontend/lib/core/widgets/app_list_tile.dart:138-140`).
  - `ProjectListView` (`frontend/lib/features/projects/presentation/project_list_view.dart:56-99`) passes nothing
    for the open project. `AppListTile.selected` means multi-select (a tick and a tint).

### Scope
- Reach: the expanded list pane on web, desktop and tablets at expanded width, in both orientations and all three
  themes. The marker also shows on the compact and medium landing list, which renders the same `ProjectListView`,
  for the project `currentProjectProvider` holds.
- Change, per D2(a):
  - `_Pane` (`nav_shell.dart:212-270`) draws its border in front: `DecoratedBox(position:
    DecorationPosition.foreground, …)`.
  - `AppListTile` gains `bool current = false`, documented as "the item the page beside this list shows". A
    current row has:
    - the `colors.surfaceVariant` fill;
    - a `Space.x1`-wide `colors.primary` bar on the start edge;
    - its title in `colors.primary`;
    - `Semantics(selected: true)`.

    `selected` keeps its tick, and both may be true.
  - `ProjectListView` sets `current: row.project.id == ref.watch(currentProjectProvider)`.
- Do not change: the rail's border, the divider indents, or the row actions.

### Rules
- FE-A11Y-05: the bar and the announcement, not colour alone. FE-L10N-05: the bar sits on the start edge.
- FE-CONS-03: the gallery shows the current state.

### Steps
1. Move the pane border to the foreground.
2. Add `current` to `AppListTile`, with a gallery entry, and set it in `ProjectListView`.
3. Tests:
   - `test/design_system/app_list_tile/`: a current row draws the start bar, the bar mirrors under right-to-left,
     and the row is announced as selected; with `selected` also true, the tick shows too.
   - `test/app/nav_shell_test.dart`: the pane's border decoration is in the foreground.
   - Regenerate `test/design_system/app_list_tile/goldens/app_list_tile_{light,dark,outdoor}.png`, and the images
     of `test/app/nav_pane_golden_test.dart` and `project_list_golden_test.dart`.
4. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] At expanded width the pane's border runs unbroken past every row, in light, dark and outdoor.
- [ ] The open project's row shows the start bar and fill and is announced as selected. Opening another project
      moves the marker.
- [ ] Long-press multi-select still shows its tick, on a current row too.

## W3 — Lay out the Project contexts page

**Feedback:** FBK0000006 · **Type:** Defect · **Priority:** P3 · **Effort:** M · **After:** —

### Evidence
- FBK0000006: the page looks crowded, with no spacing between buttons and no padding. `screenshots/FBK0000006.png`
  (web, expanded, landscape, light) shows:
  - content touching the pane and the window edge;
  - a bare "Templates" radio group;
  - a second, unpadded list of the level names;
  - Edit and Delete touching, with a drag icon over Delete;
  - Add level sitting against the list.
- Root cause (`frontend/lib/features/context/presentation/context_hierarchy_screen.dart`):
  - `AppPage(scrollable: false)` (`:111-121`) has a fixed body that adds no gutter
    (`frontend/lib/core/widgets/app_page.dart:215-235`), and the body `Column` (`:121-190`) adds none.
  - `_diagram` (`:423-453`) repeats the level list as plain text.
  - `_levelActions` (`:368-421`) sets two text `AppButton`s side by side with no gap; the theme outlines text
    buttons (`frontend/lib/app/theme/app_theme.dart:84-89`). On compact it sets two icon buttons instead.
  - `ReorderableListView.builder` (`:145-181`) keeps `buildDefaultDragHandles: true`. On desktop and web, Flutter
    adds its own handle at the row's end, over Delete, beside the leading handle (`:169-172`).
  - Add level (`:183-188`) has no space above it.

### Scope
- Reach: the page's levels state and proposals state, on every platform, size class, orientation and theme, at
  200 percent text.
- Change, per D3(a):
  - Inset the body by `AppPage.gutter(context)` on both sides and by `Space.x3` at the top, as
    `project_home_screen.dart:143-162` does.
  - Put the template choice under `AppSectionHeader(title: Copy.contextLevelSource)` ('Suggest levels from'),
    with `Space.x3` below it.
  - Remove `_diagram`.
  - Set `buildDefaultDragHandles: false`, so the leading handle is the only drag control.
  - Give every row, at every width, one trailing `AppOverflowMenu(outlined: false)` holding
    `AppOverflowAction(label: Copy.templatesEdit, icon: AppIcons.edit)` and
    `AppOverflowAction(label: Copy.contextRemoveLevel, icon: AppIcons.delete)`. `_levelActions` goes.
  - Add `SizedBox(height: Space.x3)` above Add level.
- Do not change: what Edit and Remove do, reorder persistence, Save levels, or the proposals' content.

### Rules
- FE-CONS-06: rows stay `AppListTile`. FE-RESP-04: forms keep the readable width. FE-A11Y-01: the menu button is 48dp.

### Steps
1. Make the layout changes above.
2. Tests: `test/features/context/presentation/context_hierarchy_screen_test.dart` at 360, 800 and 1280dp wide, in
   both orientations and at 200 percent text:
   - the body's start and end insets equal the gutter;
   - each row has exactly one drag handle and one overflow button;
   - no row overflows;
   - Edit and Remove from the menu behave as before.

   Regenerate that file's golden.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] The page's content is inset from the pane, the rail and the window edge at every width.
- [ ] No control overlaps another. Each level row shows a drag handle, its name, "Level n · key" and one menu.
- [ ] The level names appear once.

## W4 — Let a responsive pair share one row on compact

**Feedback:** FBK0000158 · **Type:** Improvement · **Priority:** P4 · **Effort:** S · **After:** —

### Evidence
- FBK0000158: put Save raw and Save and process in one row, the same width. `screenshots/FBK0000158.png` (Android,
  compact, portrait, light) shows them stacked at full width. That is task 070's layout.
- Root cause: `ResponsivePair` always stacks on compact
  (`frontend/lib/core/widgets/responsive/responsive_pair.dart:42-51`) and top-aligns its row (`:53-59`), so two
  controls of different heights misalign.

### Scope
- Reach: the shared widget, at every width. W12 uses it on Capture.
- Change:
  - `stacksOnCompact` (default `true`): `false` keeps the row on compact.
  - `matchesHeights` (default `false`): `true` wraps the row in `IntrinsicHeight` with
    `CrossAxisAlignment.stretch`, so both sides take the taller one's height.
  - Document both.
- Do not change: the default layout, which `capture_target_fields.dart:126` relies on.

### Steps
1. Add both parameters, with gallery entries.
2. Tests: `test/design_system/responsive_pair/` covers a row on compact, equal heights with a two-line label at 200
   percent text, and right-to-left order. Add goldens for the new variant only:
   `goldens/responsive_pair_row_compact_{light,dark,outdoor}.png`.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] With `stacksOnCompact: false` the pair is one row at 360dp; with `matchesHeights: true` both sides are
      equally tall.
- [ ] Every existing pair renders exactly as before.

## W5 — Share search folding and word matching in core

**Feedback:** FBK0000161, R3 · **Type:** Improvement · **Priority:** P4 · **Effort:** S · **After:** —

### Evidence
- The projects search folds case and Latin diacritics in a private helper
  (`frontend/lib/features/projects/presentation/project_list_filter.dart:97-112`, `_baseLetter` below it). The
  library search only lowercases (`frontend/lib/features/templates/presentation/shipped_picker_screen.dart:193-203`).
  W16 and W22 need the same folding in two more features (FE-STR-09).

### Scope
- Reach: shared Dart, every platform.
- Change: new `frontend/lib/core/normalise/search_text.dart`, exported by `core/normalise/normalise.dart`:
  - `String foldSearchText(String input)`: moved from `_foldProjectSearch` and `_baseLetter`, unchanged.
  - `List<String> searchWords(String input)`: folds, splits on anything that is not a letter or a digit, and drops
    words shorter than `AppConstants.search.minWordLength` (3) unless they contain a digit.
  - `String searchStem(String word)`: strips one trailing `ing`, `ed`, `es` or `s` when at least three letters
    remain. Words in other languages still match by prefix.
  - `project_list_filter.dart` calls `foldSearchText`.
- Do not change: what the projects search matches.

### Steps
1. Move and add the helpers.
2. Tests: `test/core/normalise/search_text_test.dart` covers diacritic folding, splitting "UNI-001" into "uni" and
   "001", dropping short words, and the stems. The existing projects-search tests still pass.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] `core/normalise` holds one folding function, and the projects search uses it with unchanged results.

## W6 — Let a section header collapse its section

**Feedback:** FBK0000161 · **Type:** Improvement · **Priority:** P4 · **Effort:** S · **After:** —

### Evidence
- FBK0000161 asks for groups that make the catalogue easy to scan (W15). `AppSectionHeader`
  (`frontend/lib/core/widgets/app_section_header.dart:11-16`) has a title, an action and `dense`, but cannot
  collapse, and `AppIcons` has `expand` but no collapse glyph.

### Scope
- Reach: the shared widget, every platform and theme.
- Change: `AppSectionHeader` gains `bool? expanded` and `VoidCallback? onToggle`, asserted to be both set or both
  null. When set:
  - the whole header is one button at least 48dp tall;
  - it shows `AppIcons.expand` when collapsed and a new `AppIcons.collapse` (`Icons.expand_less`) when expanded,
    at the end;
  - it carries `Semantics(expanded: …)`.

  Add `AppIcons.collapse` to the icon list that `test/architecture/icons_test.dart` reads.
- Do not change: the header without these parameters.

### Steps
1. Add the parameters and the icon, with a gallery entry for both states.
2. Tests: `test/design_system/app_section_header/`: a tap toggles, the semantics report expanded and collapsed,
   and the target is at least 48dp. Regenerate `goldens/app_section_header_{light,dark,outdoor}.png`.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] A collapsible header toggles on tap, shows its state by glyph and announcement, and a plain header is
      unchanged.

## W7 — Pick a document on every platform

**Feedback:** R2 · **Type:** Gap · **Priority:** P4 · **Effort:** M · **After:** —

### Evidence
- R2 needs a ZIP chosen from the device. No picker can choose one:
  - `FolderPicker` picks folders (`frontend/lib/core/files/folder_picker.dart:14-31`, `folder_picker_io.dart:22-93`);
  - `PhotoPicker` picks images;
  - Android's channel offers only `ACTION_OPEN_DOCUMENT_TREE`
    (`frontend/android/app/src/main/kotlin/com/tapture/app/MainActivity.kt:185`);
  - `file_picker` is not on `frontend/tool/allowlist.yaml`.

### Scope
- Reach: Android, iOS, Windows, macOS, Linux and web.
- Change, per D5(a): new `frontend/lib/core/files/document_picker.dart`, with `_io`, `_web` and `_stub` files by
  the conditional-import pattern `folder_picker.dart` uses:
  - `abstract interface class DocumentPicker` with `bool get canPick`,
    `Future<Result<PickedDocument>> pick({required List<String> extensions, required String mimeType})`,
    `DocumentPicker.platform()` and `DocumentPicker.fake(...)` (FE-STATE-10).
  - `PickedDocument` is sealed: `PickedFile(File file, String name, int byteLength)` on native, and
    `PickedBytes(Uint8List bytes, String name)` on web. A dismissed picker returns `CancelledFailure`.
  - Android: channel method `pickDocument` in `MainActivity.kt`. It opens `ACTION_OPEN_DOCUMENT` for the MIME type
    and copies the stream in 64 KiB chunks into `cacheDir/imports/<name>`, then returns that path.
  - iOS: the same method in `frontend/ios/Runner/AppDelegate.swift`, through `UIDocumentPickerViewController`
    with `asCopy: true`.
  - Windows: a PowerShell `OpenFileDialog` with a `*.zip` filter, as `folder_picker_io.dart` runs
    `FolderBrowserDialog`.
  - macOS: `osascript` `choose file of type {"zip"}`.
  - Linux: `zenity --file-selection --file-filter='*.zip'`.
  - Web: a hidden `<input type=file accept=".zip">` through `dart:js_interop`, reading the chosen file's bytes.
- Do not change: `FolderPicker` and `PhotoPicker`.

### Rules
- FE-STR-11: no feature calls a channel or a command directly. FE-SEC-06: W10 checks size before reading more than
  the header.

### Steps
1. Add the interface, the fake and the platform implementations.
2. Tests: `test/core/files/document_picker_test.dart` covers the fake's pick and cancel, and the desktop
   command-and-argument lists, as the folder picker's tests do. W19's tests use the fake.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] On each platform, choosing a `.zip` returns it and dismissing returns `CancelledFailure`.
- [ ] No feature file imports a channel, a process call or `dart:js_interop` for picking.

## W8 — Save and share a stored package without loading it whole

**Feedback:** R1 · **Type:** Gap · **Priority:** P4 · **Effort:** M · **After:** —

### Evidence
- R1's package holds every photo, so on a phone it can run to gigabytes. `DownloadService.save` and
  `openExternally` take bytes held in memory, and the service documents that it "never takes a stored path"
  (`frontend/lib/core/files/download_service.dart:80-120`). FE-PERF-07 forbids loading a file that large into
  memory.

### Scope
- Reach: Android, iOS, Windows, macOS and Linux. Web keeps bytes, per D6(a).
- Change, per D6(a):
  - `DownloadService` gains
    `saveStored({required String relativePath, required String fileName, required String mimeType, String? subfolder})`
    and `openStoredExternally({required String relativePath, required String fileName, required String mimeType})`.
  - Both accept only a path of the form `projects/<folder>/exports/<file>`, checked by `safeRelativePath`. Anything
    else returns a `StorageFailure`, so no original photo or audio file is ever handed out (FE-SEC-08).
  - Android: a new channel method `saveFileToDownloads(sourcePath, name, mimeType, subfolder)` beside
    `saveToDownloads` copies in 64 KiB chunks into `Download/Tapture/<subfolder>`.
  - Desktop: a streamed copy into `Downloads/Tapture/<subfolder>`.
  - Share on Android and iOS: `SharePlus.instance.share(ShareParams(files: [XFile(path, mimeType: mimeType)]))`.
  - Web: both methods return a `StorageFailure`.
  - The fake records both calls. The doc line becomes "never takes a stored path outside a project's exports
    folder".
- Do not change: `save`, `saveAs`, `openExternally` or their destinations.

### Steps
1. Add the two methods, the Android channel method and the fake.
2. Tests: `test/core/files/download_service_test.dart` covers:
   - a path outside `exports/` is refused;
   - a stored file is copied in chunks, byte for byte, to the desktop destination in a temp folder;
   - the fake records calls;
   - web refuses.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] A 1 GB stored package saves to Downloads and to the share sheet without the app's memory rising by its size.
- [ ] No stored path outside a project's `exports/` folder can be saved or shared.

## W9 — Write the project package

**Feedback:** R1 · **Type:** Gap · **Priority:** P4 · **Effort:** L · **After:** —

### Evidence
- R1. Today's export is a three-column workbook: Record, Status and Photos
  (`frontend/lib/features/exports/data/export_repository_impl.dart:323-352`). Nothing else leaves the device, and
  `frontend/lib/core/bundle/bundle.dart` is an empty barrel.
- The layout is specification §45, and task 019 plans `core/bundle/`. Every row already carries the merge
  columns `id` (UUIDv7), `createdAt`, `updatedAt`, `updatedByDevice` and `rev`
  (`frontend/lib/core/db/columns.dart:18-35`). Files are stored under project-relative paths with their sha256
  (`photos.dart:33,54`, `attachments.dart:21,30`).

### Scope
- Reach: every platform. Native streams to disk; web builds in memory under its ceiling (D6).
- Change, per D6(a) and D7(a):
  - `core/bundle/bundle_format.dart`:
    - `BundleFormat.name` = `'tapture-bundle'` and `BundleFormat.version` = 1;
    - the entry names;
    - `BundleManifest` with `toJson`/`fromJson`, holding: format, format_version, app_version, schema_version
      (`kSchemaVersion`), bundle_id, project_id, project_name, folder_name, exported_at, exported_by_device,
      exported_by_operator, scope `FULL`, counts, lineage (this device plus each `merge_sessions` source), templates
      (id, template_key, version, and each field's key and type), entries (path, byte_length, sha256) and
      missing_files.
  - Layout:
    - `manifest.json`;
    - `project.json` (the project row, its context levels and its presets);
    - `templates.json`;
    - `reference/<datasetId>.json` (a descriptor plus rows);
    - `records.json` (records, field values and field evidence);
    - `captions.json`;
    - `media.json` (photos, attachments and attachment owners);
    - `meetings.json`, `variances.json`, `processing.json`, `duplicates.json`, `audit.json` and
      `tombstones.json`;
    - every referenced file at its project-relative path (`photos/…`, `audio/…`, `documents/…`, `meetings/…`,
      `cover/…`);
    - `checksums.txt`.

    Each JSON file maps a SQL table name to a list of rows, each an object keyed by SQL column name, with values
    as stored.
  - `core/bundle/bundle_rows.dart` selects the project's rows per table, tombstoned rows and their tombstones
    included, as D7(a) lists. Audit rows are those whose entity the package carries.
  - Project settings are written through the `ProjectSettings` keys only. `device_profile`, `SettingsStore` and
    secure storage are never read.
  - `core/bundle/bundle_writer.dart`: `BundleWriter.write({required String projectId, required CancellationToken
    cancel, void Function(double)? onProgress})` returns `Future<Result<BundleOutput>>`. `BundleOutput` is sealed:
    `StoredBundle(relativePath, byteLength, sha256)` on native, and `InMemoryBundle(bytes)` on web.
    - Native: `ZipFileEncoder` from `package:archive/archive_io.dart` streams into
      `projects/<folder>/exports/<bundleId>.zip.part` and renames the file when complete. Files are added from
      disk through `InputFileStream`.
    - Web: `ZipEncoder` in memory, reading files through `FileReader`.
    - Tables are encoded on the isolate runner. Each entry's sha256 is taken as it is written. `checksums.txt`
      and the manifest are written last.
  - Before writing, an estimate (the sum of file sizes plus the table sizes) is checked against the D6 ceiling. An
    estimate over the ceiling returns a `StorageFailure` naming both sizes. A referenced file that is missing is
    listed in `missing_files`, and the write continues.
  - Cancel or failure deletes the `.part` file.

### Rules
- FE-SEC-01, FE-SEC-02: no key, token or credential enters a package. FE-PERF-07: files are streamed on native.
- FE-SEC-08: originals are read, never moved or rewritten. FE-PERF-10: progress and cancel.

### Steps
1. Add the format, the row selection and the two writers.
2. Tests: `test/core/bundle/bundle_writer_test.dart`, over an in-memory database seeded through a
   `seedProjectForBundle` factory (FE-TEST-04):
   - a round trip through W10's reader returns every row and file hash;
   - the manifest matches its schema;
   - a secret-shaped value planted in device settings never appears;
   - cancel leaves no `.part` file;
   - an estimate over the ceiling is refused before writing;
   - the web writer works over `BlobStore.memory`.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] The package holds every table and file D7(a) lists, and nothing it excludes.
- [ ] Every entry's sha256 in the manifest matches its bytes.
- [ ] A project with 2,000 photos packages on native without memory growing with the photos.

## W10 — Read and verify a project package

**Feedback:** R2 · **Type:** Gap · **Priority:** P4 · **Effort:** M · **After:** W9

### Evidence
- R2. `ImportKind.bundle` and `validateArchive`, which checks traversal, symlinks and zip-bomb size, exist
  (`frontend/lib/core/files/file_validation.dart:42-43`, `:86-106`), but nothing calls them, and they work on a
  `dart:io File` only. The ceilings are in `AppConstants.imports` (`frontend/lib/core/constants/app_constants.dart:198-216`).

### Scope
- Reach: every platform. Files on native, bytes on web.
- Change:
  - `core/bundle/bundle_reader.dart`: `BundleReader.inspect(PickedDocument source)` returns
    `Future<Result<InspectedBundle>>`. A refusal is a `BundleRejectedFailure` carrying a `BundleRejection`:
    `tooLarge`, `notAPackage`, `unsafePath`, `missingEntry`, `unreadable`, `unknownFormatVersion` or
    `checksumMismatch`. Each has a `Copy` message naming the check that failed.
  - The checks run in this order, all off the UI thread:
    1. the D6 ceiling;
    2. the ZIP magic bytes;
    3. the archive walk, through `validateArchive` for files and a bytes overload of the same walk for web;
    4. the required entries;
    5. the manifest (format `tapture-bundle`, format_version at most 1);
    6. every entry's sha256, streamed on native;
    7. each JSON table parsed into row maps, with the required columns per table present and unknown columns
       ignored.
  - `InspectedBundle` exposes `manifest`, `tables` and `Stream<List<int>> openEntry(String path)`. Nothing is
    written.
  - `AppConstants.imports.bundleMaxBytes` and `archiveUncompressedMaxBytes` apply to web. Native uses
    `AppConstants.bundles.nativeMaxBytes`, and that value plus 10 percent uncompressed (D6).

### Rules
- FE-SEC-05, FE-SEC-06: every value read is data; checks run before any row or file is written.

### Steps
1. Add the reader and the bytes overload of the archive walk.
2. Tests: `test/core/bundle/bundle_reader_test.dart`:
   - W9's output is accepted;
   - a fixture for each `BundleRejection` is refused with its reason: a flipped byte, a `../` path, format
     version 2, no manifest, a PNG renamed `.zip`, and a file over the ceiling.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] A tampered, unsafe, newer-format or oversized package is refused with a message naming the failed check,
      and nothing is written.
- [ ] A package W9 wrote is accepted on native and on web.

## W11 — Add a read-only project details page

**Feedback:** FBK0000156 · **Type:** Gap · **Priority:** P5 · **Effort:** M · **After:** W1

### Evidence
- FBK0000156: "project details page instead opens project edit UI; ensure proper CRUD pages". The only details page
  is the edit form. The home overflow item "Project details" goes to `/edit`
  (`frontend/lib/features/projects/presentation/project_home_screen.dart:233-237`, with `context.go`), as does the
  settings item (`project_settings_screen.dart:69-74`). The plan says so on purpose
  (`dev-plan/08-projects/008-projects.md:282`). Create, delete and archive have their own flows.

### Scope
- Reach: every platform, size class, orientation and theme.
- Change, per D8(a):
  - New route `details` under `/projects/:projectId` (`router.dart:478-498`) with
    `RoutePaths.projectDetails(id)`, to a new `ProjectDetailsScreen` (`project_details_screen.dart`) reading
    `projectByIdProvider` (W1).
  - The page shows, as dense `AppListTile` rows, each with `Copy.projectValueNotSet` ('Not set') when empty:
    - the cover photo through `AppPhotoThumb`;
    - name, description and organisation;
    - starts and ends;
    - status as an `AppStatusPill`;
    - created and updated, through the shared formatter (FE-CONS-09).

    Its primary action, `Copy.projectEditDetails` ('Edit details'), pushes `/edit`.
  - Both "Project details" menu items push `/details`.
  - The edit form's title becomes `Copy.projectEditFormTitle` ('Edit project'). After W1's successful save it
    pops back to details, or goes to details when there is nothing to pop.
  - Update `008-projects.md:282` to name both routes.
- Do not change: the edit form's fields and the photo actions.

### Steps
1. Add the route, the screen and the copy; retitle the form; change the two menu items and the save's
   navigation.
2. Tests:
   - `project_details_screen_test.dart`: every value, "Not set" for empties, an archived project, 200 percent
     text at three widths.
   - `project_home_screen_test.dart:198`: now routes to details.
   - `project_edit_screen_test.dart`: a save returns to details with "Project saved".
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] "Project details" opens a read-only page, and Edit details opens the form titled "Edit project".
- [ ] Saving the form returns to the details page showing the new values.

## W12 — Put Save raw and Save and process in one equal row

**Feedback:** FBK0000158 · **Type:** Improvement · **Priority:** P5 · **Effort:** S · **After:** W4

### Evidence
- FBK0000158, as in W4. `frontend/lib/features/capture/presentation/capture_screen.dart:312-337` builds the pair
  with `endFlex: 2`, stacked on compact, per task 070 (FBK0000004). `AppPrimaryAction` grows by its offline caption
  (`frontend/lib/core/widgets/app_primary_action.dart:57-60`, `:128-140`), so a row would misalign when offline.
  FBK0000158 is the later request, made after using task 070's layout, so it wins.

### Scope
- Reach: the new-record Capture page on every platform, size class, orientation and theme, at 200 percent text.
  The record-edit footer, a single "Save changes", is unchanged.
- Change, per D4(a):
  - The pair sets `stacksOnCompact: false`, `matchesHeights: true`, `endFlex: 1` and `gap: Space.x2`.
  - The offline line leaves `AppPrimaryAction.caption` and becomes a `Text(Copy.captureProcessNeedsNetwork,
    style: AppText.caption)` under the row, so both buttons stay `Sizes.controlHeight`.
  - Labels wrap to a second line at 200 percent text rather than clip.
  - The comment cites FBK0000004 and FBK0000158.
  - FE-SIMP-01 in `frontend/.rules/06-simplicity.md` reads as D4(a) words it, and the commit body says why
    (FE-FLOW-07).
- Do not change: which button is primary, their order, or what each saves.

### Steps
1. Change the pair, the caption and the rule.
2. Tests: `test/features/capture/presentation/capture_feedback_test.dart` at 360, 800 and 1280dp wide, in both
   orientations:
   - one row, with the two buttons at equal width and equal height;
   - at 200 percent text, both labels are fully visible;
   - offline, the caption sits under the row and Save and process is disabled.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] At every width the two saves share one row, at the same width and height, with Save and process at the end.
- [ ] Nothing clips at 200 percent text; offline, the reason shows under the row.

## W13 — Fill a record's fields by hand from the record page

**Feedback:** FBK0000162 · **Type:** Improvement · **Priority:** P5 · **Effort:** M · **After:** —

### Evidence
- FBK0000162: add a simple way to fill the fields by hand. `screenshots/FBK0000162.png` (Android, compact, light)
  shows the Fields rows reading "Not entered" and one Edit button, which opens capture's photo and caption editor
  (`frontend/lib/features/projects/presentation/record_detail_screen.dart:72-78`).
- Code:
  - The field rows cannot be tapped (`:148-159`).
  - The field editor hides behind the overflow item "Edit fields" (`:58-63`), and it types every field into a
    plain `AppTextField` (`record_edit_sheet.dart:107-116`), with no date, number or choice input.
  - `FieldEditor` (`frontend/lib/core/widgets/fields/field_editor.dart:22-75`) renders typed inputs, but only the
    gallery uses it. Its number branch drops the current value (`:156-164`), because `AppNumberField` has no
    initial value (`app_number_field.dart:18-54`).

### Scope
- Reach: the record page on every platform, size class, orientation and theme. It covers every field
  `recordEditEntries` (`record_edit_sheet.dart:189-230`) offers, context fields such as Country included. Hidden,
  automatic and computed fields stay excluded, as today.
- Change, per D9(a):
  - Each field row gets `onTap`, which opens `showRecordFieldSheet` (new `record_field_sheet.dart`). The sheet
    holds one `FieldEditor` for that field, through `fieldEditorField(FieldDef)`
    (`frontend/lib/features/templates/presentation/field_editor_bindings.dart:16-26`), with Save and Cancel.
  - Save goes through `RecordEditController.save` (`record_edit_controller.dart:29-57`) with that one entry, so the
    raw value and the audit row are written as today.
  - `RecordEditEntry` carries its `FieldDef`, and `RecordEditSheet` renders a `FieldEditor` per entry.
  - `AppNumberField` gains `initialValue`, which `FieldEditor._number` passes.
  - The Fields `AppSectionHeader` gets `action: AppButton(label: Copy.recordEditFields, variant:
    AppButtonVariant.text)`, which opens the all-fields sheet. The overflow item goes.
- Do not change: the Edit footer, raw-value immutability, or the audit trail.

### Rules
- FE-CONS-10: a tap on a value edits it. FE-SEC-08, FE-SEC-09: raw stays, and every change is audited.

### Steps
1. Make the rows tappable and add the one-field sheet; move the sheets to `FieldEditor`; add `initialValue`; move
   the menu item.
2. Tests:
   - `record_detail_screen_test.dart`: tapping "Region state" opens its sheet, and saving shows the value.
   - `record_edit_sheet_test.dart`: date, number and choice fields render typed inputs holding their values.
   - `test/design_system/app_number_field/`: the initial value shows.
   - FE-A11Y-01: 48dp rows.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] Tapping any editable field on the record page opens an input suited to its type, and saving shows the value
      at once.
- [ ] "Edit fields" sits on the Fields heading and edits every field with typed inputs.
- [ ] The raw value is unchanged, and an audit row records each change.

## W14 — See and change context from Capture

**Feedback:** FBK0000160 · **Type:** Gap · **Priority:** P5 · **Effort:** M · **After:** —

### Evidence
- FBK0000160: from Capture, see and change context-level values such as location and sub-location.
  `screenshots/FBK0000160.png` (Android, compact, light) shows Capture with no context anywhere.
- Code:
  - The shell's `ContextBar` (`frontend/lib/app/nav_shell.dart:68-78`) draws nothing until a level has a value
    (`frontend/lib/features/context/presentation/context_bar.dart:33-35`, `:59-61`, `:90-92`), so a first value
    cannot be set from Capture.
  - Levels are managed only from the project home's overflow menu.

### Scope
- Reach: the Capture tab on every platform, size class, orientation and theme, at 200 percent text, in
  right-to-left. Other tabs keep today's bar.
- Change, per D10(a):
  - `ContextBar({bool showsEmptyLevels = false})`. With it set:
    - each level of the open project is an `AppChip` reading "name: value", or `Copy.contextSetLevel(name)`
      ('Set District') when empty;
    - each chip opens `showContextPickerSheet` (`context_picker_sheet.dart:24-44`) to set, change or clear;
    - a last chip, `Copy.contextManage` ('Manage', `AppIcons.context`), pushes `RoutePaths.projectContext(id)`;
    - with no levels defined, the bar shows one chip, `Copy.contextSetUp` ('Set up context'), with the same
      route;
    - the chips sit in one horizontally scrolling line, not the clipped wrap.
  - `nav_shell.dart` passes `showsEmptyLevels: true` while the current branch is Capture and a project is open.
- Do not change: how values persist and stick, pinned-field chips, or the bar on other tabs.

### Rules
- FE-SIMP-05: values stay sticky. FE-RESP-03: switching tabs keeps state. FE-A11Y-01: 48dp chips.

### Steps
1. Add the mode and pass it from the shell.
2. Tests:
   - New `test/features/context/presentation/context_bar_test.dart`: empty levels show "Set …"; a tap opens the
     picker; Manage routes; no levels shows "Set up context"; the line scrolls at 200 percent text; other tabs are
     unchanged.
   - Regenerate the `context_bar_golden_test.dart` images.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] On Capture, every context level of the open project shows, set or not, and a tap sets or changes it.
- [ ] Capture offers a way to the project's context levels, including when none exist.

## W15 — Group the template library into collapsible categories

**Feedback:** FBK0000161 · **Type:** Improvement · **Priority:** P5 · **Effort:** M · **After:** W6

### Evidence
- FBK0000161: group the templates so they are easy to discover. `screenshots/FBK0000161.png` (Android, compact,
  light) shows "01 · Cross-sector foundations" and "UNI — Universal capture and records" above a flat list.
- Code: `_rows()` (`frontend/lib/features/templates/presentation/shipped_picker_screen.dart:443-476`) lays out 2,349
  templates (`frontend/assets/templates/_catalogue.json:4`) in one `ListView.builder` (`:229-239`), under 17 area
  headings and 72 category headings. None of the headings collapses or shows a count.

### Scope
- Reach: the shipped library on every platform, size class, orientation and theme.
- Change, per D11(a):
  - With no search and no filter, each area heading stays as it is, followed by its categories as collapsible
    `AppSectionHeader`s (W6). Each is titled `Copy.shippedCategoryHeading(code, title, count)`, for example
    'UNI — Universal capture and records · 34'.
  - Categories start collapsed; one holding a ticked template starts expanded.
  - The expanded set lives in a new autoDispose `Notifier`, `ShippedLibraryExpanded`
    (`shipped_library_expanded.dart`).
  - With a search or a filter active, the list is W16's ranked result, flat.
  - The list stays lazy (FE-PERF-03).
- Do not change: ticking, preview, Save, and the three filter facets.

### Steps
1. Build the grouped rows from the expanded set.
2. Tests: `test/features/templates/presentation/shipped_picker_screen_test.dart`:
   - it opens with every category collapsed, showing counts;
   - a tap expands one category;
   - a ticked template's category opens expanded;
   - a search shows a flat list;
   - at 200 percent text nothing clips.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] The library opens as area headings and collapsed, counted categories, and a tap shows a category's
      templates.

## W16 — Rank library search and accept a description

**Feedback:** FBK0000161 · **Type:** Improvement · **Priority:** P5 · **Effort:** M · **After:** W5, W15

### Evidence
- FBK0000161: make the search intelligent, so that a person can describe the work and get the best-matching
  templates in order.
- Code:
  - The search keeps only entries that contain every typed word as a substring, in catalogue order
    (`shipped_picker_screen.dart:193-203`). It searches the title, codes, category, area, record type, kind and own
    field keys (`:409-423`), so a sentence such as "count laptops in district offices" matches nothing.
  - The pack guidance (`_catalogue.json` `packs[].capture`, `ai_assistance`, `outputs`; `ShippedRecordType`,
    `frontend/lib/features/templates/domain/shipped_record_type.dart:4-36`) is never searched.
  - AI is out of reach per D12.

### Scope
- Reach: the shipped library on every platform, offline included. No egress.
- Change, per D12(a):
  - New pure-Dart `features/templates/domain/shipped_template_ranking.dart`:
    `ShippedTemplateRanking.rank(String query, List<ShippedTemplateEntry> entries, Map<String, ShippedRecordType>
    recordTypes)` returns the entries in rank order. Query words come from `searchWords` and `searchStem` (W5).
  - Each word scores its best-matching field. A word matches a field word that starts with its stem.

    | Field | Score |
    | :--- | :--- |
    | An exact code (`ast-001`) | 10 |
    | Title | 5 |
    | Category title | 3 |
    | Record type title and kind | 3 |
    | Own field labels | 2 |
    | Area title | 1 |
    | Pack capture, AI assistance and outputs text | 1 |

    An entry's score is the sum over the words. Entries scoring 0 drop out, and ties keep catalogue order. The
    facet filter still applies.
  - The search index keeps per-field word lists, built once per loaded list inside the existing isolate indexing
    (`frontend/lib/features/templates/data/shipped_template_loader.dart:621-720`).
  - `Copy.shippedLibrarySearchHint` becomes 'Search or describe your work'.
- Do not change: the filter sheet and the result count.

### Rules
- FE-PERF-01, FE-TEST-09: ranking 2,349 entries stays under the 300ms search budget, asserted by a test.

### Steps
1. Add the ranking, extend the index, and wire it into the screen.
2. Tests:
   - `test/features/templates/domain/shipped_template_ranking_test.dart` over a fixture of about 10 entries: a code
     ranks first; a title word outranks a field word; a description ranks the fitting entries above the others;
     zero scores drop out.
   - A timing test over the real catalogue.
   - A screen test: a typed sentence shows ranked rows.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] A plain description returns templates ordered by how well they match, offline.
- [ ] Typing a code puts that template first.

## W17 — Export the whole project as one package

**Feedback:** R1 · **Type:** Gap · **Priority:** P5 · **Effort:** M · **After:** W8, W9

### Evidence
- R1. `ProjectExportScreen` (`frontend/lib/features/projects/presentation/project_export_screen.dart:174-200`)
  saves and shares the three-column workbook, and `Copy.exportFileFormat` reads 'Excel workbook (.xlsx)'
  (`frontend/lib/core/copy/copy.dart:889-893`).

### Scope
- Reach: every platform. Native delivers the stored file (W8); web delivers bytes.
- Change, per D13(a):
  - `ExportRepositoryImpl.exportProject` writes the package through `BundleWriter` (W9), and adds the workbook it
    builds today as `records.xlsx`.
  - The `exports` history row gets `formats: ['bundle', 'xlsx']`, plus the package's path and hash.
  - The screen shows the size estimate before writing (`Copy.exportPackageSize(bytes)`), then progress and Cancel.
    It delivers through `saveStored` and `openStoredExternally` on native, and `save` and `openExternally` on web.
  - The file name is `PROJECT-NAME-DDMMYY-HHMMSS.zip`, from `export_file_name.dart`.
  - The format copy becomes 'Project package (.zip)', and the columns copy becomes 'Everything another Tapture app
    needs to open this project: records, photos, audio, templates, context, reference data and project settings.
    Unsaved capture drafts stay on this device.'
  - Older `.xlsx` history rows still list.
- Do not change: the export summary counts and the menu entries that open the screen.

### Steps
1. Switch the repository and the screen to the package.
2. Tests:
   - `export_repository_impl_test.dart`: a package holds `records.xlsx` and every file, and records history.
   - `project_export_screen_test.dart`: the estimate, cancel, and web bytes against native stored delivery through
     fakes.
   - Regenerate the `export_summary_golden_test.dart` images.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] Export produces one `.zip` that W10 accepts and that holds the workbook, every table and every file.
- [ ] On a phone, a package larger than 200 MiB saves and shares.

## W18 — Show a capture guide built from the template

**Feedback:** FBK0000157, FBK0000159 · **Type:** Suggestion · **Priority:** P6 · **Effort:** M · **After:** W12

### Evidence
- FBK0000157: while capturing, show a short guide to what the photos should show and what the caption should say,
  built from the template. For IT equipment, for example, the name plate in the photos, and the status and
  accessories in the caption.
- FBK0000159: show the hint as a pop-up while typing or recording.
- `screenshots/FBK0000157.png` and `FBK0000159.png` (Android, compact, light) show Capture with no guide.
- Code: nothing on Capture guides (`capture_screen.dart:339-452`; `record_caption_field.dart:94-103` is a plain
  field). Templates already hold what a guide needs:
  - identity fields (`TemplateDef.identityFieldKeys`, `FieldDef.identity`);
  - types, requiredness, groups and input modes.

  For example, AST-001 and ICT-001 name `item_identifier` and `serial_number` as identity, and inherit
  `barcode_value` and `condition_grade` (`frontend/assets/templates/01_ast_assets_and_equipment.json`,
  `11_ict_it_service_management_and_infrastructure.json`, `_catalogue_groups.json` `pack_asset`).

### Scope
- Reach: the Capture and record-edit pages, on every platform, size class, orientation and theme, at 200 percent
  text. A template with nothing to list shows no guide.
- Change, per D14(a):
  - New pure-Dart `features/templates/domain/capture_guide.dart`, exported by the templates barrel.
    `CaptureGuide.of(TemplateDef template)` builds two lists, each capped at `AppConstants.capture.guideMaxFields`
    (6), plus `isEmpty`:
    - `photoFields`: identity fields and `barcode` fields, in field order;
    - `captionFields`: REQUIRED then RECOMMENDED fields, leaving out photo fields, hidden fields, `InputMode.auto`,
      fields with `autoFill`, `contextLevel` or `stickable`, and the groups `record_admin`, `location`, `evidence`,
      `review` and `context`.
  - New `features/capture/presentation/capture_guide_card.dart`, under the Template select:
    - a one-line row, `Copy.captureGuideTitle` ('What to capture'), that expands and starts collapsed;
    - when expanded, `Copy.captureGuidePhotos` ('Photos should show') and `Copy.captureGuideCaption` ('Say or type
      in the caption'), each followed by its labels as wrapping text.
  - `RecordCaptionField` gains `List<String> guide`. While the field has focus, dictation runs, or the recorder
    records, a panel directly above the field lists those labels. It never takes focus. Its close control hides it
    until the template changes.
- Do not change: capture, saving, or the caption's behaviour.

### Rules
- FE-L10N-07: labels are template data, never translated. FE-SIMP-03: no tap is added to the capture path.

### Steps
1. Add `CaptureGuide`, the card and the caption panel.
2. Tests:
   - `capture_guide_test.dart`, pure Dart, over AST-001 and a user-built template with no identity fields.
   - Capture widget tests:
     - the row expands;
     - focusing the caption shows the panel, and blurring hides it;
     - recording shows it;
     - close hides it until the template changes;
     - at 200 percent text nothing clips, at three widths and in both orientations.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] For an asset template, Capture lists the identity and barcode fields under "Photos should show", and the
      required and recommended descriptive fields under "Say or type in the caption".
- [ ] While typing, dictating or recording a caption, those caption points show above the field.

## W19 — Import a package as a new project

**Feedback:** R2 · **Type:** Suggestion · **Priority:** P6 · **Effort:** M · **After:** W7, W10

### Evidence
- R2. `features/merge`, `features/import` and `core/bundle` are empty barrels. The only merge port is
  `MergeRepository` (`frontend/lib/features/merge/domain/merge_repository.dart:6-21`), with no implementation.
  `merge_sessions` exists (`frontend/lib/core/db/tables/merge.dart:19-40`).

### Scope
- Reach: every platform; web within the web ceiling.
- Change:
  - `ProjectListActions.overflow` (`project_list_actions.dart:38-50`) adds `Copy.projectImport` ('Import a
    project', `AppIcons.import`). That covers the compact and medium landing list and the expanded pane.
  - A new `features/merge/presentation/package_import_controller.dart` runs the flow:
    1. pick (W7);
    2. inspect (W10), with progress and Cancel;
    3. then, by the manifest's project id:
       - unknown here: an import sheet showing the name, source device, export time, counts and size, with
         `Copy.importAsNewProject` as primary and `Copy.importMergeInto` ('Merge into a project…', W20) as
         secondary;
       - live here: the merge preview for that project (W21);
       - tombstoned here: refused with `Copy.importProjectDeletedHere`, because a merge never brings back what
         was deleted (spec §44, principle 1).
  - A new `PackageImportRepository` port in `features/merge/domain/`, implemented in `features/merge/data/`, does
    the import as a new project:
    1. It checks headroom with `StorageGuard` for the files' total.
    2. It picks the folder: the manifest's folder name, with `-2`, `-3` and so on appended when that is taken.
    3. It writes the files through `FileWriter` and checks each against its sha256.
    4. It inserts every row in one transaction, in dependency order, keeping ids, `rev`, timestamps and devices
       exactly.
    5. It writes a `merge_sessions` row with status `imported`, the source device and the counts.

    Any failure rolls the transaction back and deletes the new folder. Global reference datasets are inserted when
    absent; when present, their rows follow W21's reference rule.
  - The picked copy is deleted when the flow ends. The new project's home opens with `Copy.importDone(records)`.

### Rules
- FE-STATE-07: nothing shows as imported before the commit. FE-SEC-09: audit rows travel unchanged.

### Steps
1. Add the menu item, the controller, the port and the implementation.
2. Tests:
   - An integration test: write a seeded project with W9, import it into an empty database, and compare every row
     and file.
   - A failure while copying leaves no rows and no folder.
   - A tombstoned project is refused.
   - A folder name collision gets the suffix.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] A package exported on one device imports on another as the same project: the same ids, records, photos,
      templates, context and settings.
- [ ] A failed import leaves the device exactly as it was.

## W20 — Check template compatibility before a merge

**Feedback:** R2 · **Type:** Suggestion · **Priority:** P6 · **Effort:** M · **After:** W19

### Evidence
- R2 asks for a compatibility check before a merge. Template identity across devices is the stable `templateKey`,
  stored in `detection['template_key']` (`frontend/lib/features/templates/data/template_mapper.dart:51-52`). The
  UUID differs per copy: `copyToProject` mints a new one
  (`frontend/lib/features/templates/data/shipped_template_loader.dart:77-104`). `TemplateVersioning.diff` names
  the added, removed and retyped keys (`frontend/lib/features/templates/domain/template_versioning.dart:35-60`).

### Scope
- Reach: every platform.
- Change, per D15(a):
  - New pure-Dart `features/merge/domain/template_compatibility.dart`:
    `TemplateCompatibility.check({required List<TemplateDef> incoming, required Map<String, Set<String>>
    filledFieldKeys, required List<TemplateDef> local})` returns a `CompatibilityReport`. Its `status` is
    `compatible`, `compatibleWithDifferences` or `incompatible`, and it holds one `TemplateMatch` per incoming
    template that a live incoming record uses.
  - Matching: the same id first, otherwise the same `templateKey`. When several local templates match, the one
    sharing the most field keys wins, then the higher version.
  - Blockers (each named):
    - no match;
    - a filled incoming field missing locally;
    - a filled field whose local type cannot hold the values. Identical types can; `text` and `long_text` hold
      anything; `decimal` holds `number`.
  - Differences (warnings that do not block, FE-SIMP-08): another version, local-only fields, changed
    requiredness, label or options, and unfilled incoming fields missing locally.
  - New `merge_target_sheet.dart`, opened from "Merge into a project…", lists local projects ordered by status.
    Each shows an `AppStatusPill` with an icon and text. A project that is not compatible lists its reasons and
    cannot be chosen. The same report heads W21's preview, the same-project case included.
- Do not change: any local template.

### Steps
1. Add the check and the sheet.
2. Tests: `template_compatibility_test.dart`, pure Dart, covers:
   - an identical template;
   - a different version;
   - an extra local field;
   - a missing filled field;
   - a retyped field in both allowed and blocked forms;
   - no match;
   - a match by key under different ids.

   A sheet widget test covers ordering and a blocked choice.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] Before any merge, each template the incoming records use is shown as compatible, compatible with named
      differences, or not compatible with named reasons.
- [ ] A merge into a project that is not compatible cannot start.

## W21 — Merge a package into a project

**Feedback:** R2 · **Type:** Suggestion · **Priority:** P6 · **Effort:** L · **After:** W20

### Evidence
- R2, and specification §46.2, §47 and §48. The tables exist: `merge_sessions`, `merge_conflicts`
  (`frontend/lib/core/db/tables/merge_conflicts.dart:13-46`) and `tombstones`. Photos are unique by project and
  sha256 (`frontend/lib/core/db/tables/photos.dart:72-73`). Field writes keep the raw value and audit every change
  (`frontend/lib/core/db/tables/record_fields.dart:175-209`). Record numbers are not stored, so nothing needs
  relabelling.

### Scope
- Reach: every platform; web within its ceiling.
- Change, per D16(a):
  - New pure-Dart `features/merge/domain/merge_planner.dart`. `MergePlanner.plan(incoming, local,
    CompatibilityReport, targetProjectId)` returns a `MergePlan` value (FE-STR-05), with these rules:
    - An id absent here is inserted. It moves to the target project, and its template id maps to the matched
      local template.
    - Identical content (every column except `rev`, `updatedAt` and `updatedByDevice`) is skipped.
    - Differing record fields go through §47's rules, in order: a verified value beats an unverified one; a
      barcode, reference or lookup source beats an OCR, AI or caption source; a non-empty value beats an empty one
      whose `rev` is at most 1. Anything left becomes a `FieldConflict`.
    - Captions and a record's status and context follow the same rules.
    - Photos: an existing id is the same photo. The same sha256 under another id counts as "already on this
      device". Otherwise the photo is inserted, and a path taken by other content goes to `photos/_merged/<id>.<ext>`.
    - Tombstones: an incoming delete applies when this side's `updatedAt` is not later than the delete; a delete
      here holds when the incoming `updatedAt` is not later. The other case is a conflict: keep or delete.
    - Audit, processing results, field evidence and variances: a union by id.
    - Context levels: a union by field key, with new levels appended. Presets: a union by name. `context_state`
      stays local.
    - Templates: for the same project, an absent template is inserted and a different version keeps the local one.
      For another project, only the mapping applies.
    - Reference datasets: an absent row key is inserted, and a differing row keeps the local values, counted.
    - The project row: the local one is kept, and differing attributes are listed.
  - New `merge_preview_screen.dart` at route `/projects/:projectId/merge`, reading the inspected package from the
    import controller. It shows:
    - the package name, source device and export time;
    - W20's report;
    - §48.1's counts, each expandable to the records it covers: new records, updated records, new photos, photos
      already here, deletions to apply, conflicts to settle, possible duplicates (W22), and values kept as on this
      device.

    Its primary action reads `Copy.mergeSettleConflicts(n)` while conflicts remain, then `Copy.mergeApply`, beside
    Cancel.
  - New `conflict_screen.dart` shows one conflict at a time, "Conflict 3 of 7": the record, the field, this
    device's value and the incoming value, each with its device and time. The choices are Keep this device's and
    Take incoming. The second controls, `Copy.mergeKeepAllMine(n)` and `Copy.mergeTakeAllIncoming(n)`, each ask
    for confirmation with the count.
  - `features/merge/data/merge_apply_impl.dart` applies the plan:
    1. It stages the new files into `projects/<folder>/imports/<bundleId>/`, checked by sha256.
    2. It writes, in one transaction: every row; the `merge_sessions` row with its counts; each `merge_conflicts`
       row with its resolution and chooser; and a taken value as the field's final value with an audit row naming
       both values.
    3. After the commit, it moves the staged files into place.

    A failure rolls back and deletes the staging folder. Raw values here never change.
  - Entry points: W19's flow, and a project home overflow item, `Copy.mergePackage` ('Merge a package',
    `AppIcons.import`).
- Do not change: anything before the person confirms. There is no undo, per D16(a).

### Rules
- FE-STATE-07: all or nothing. FE-SEC-08, FE-SEC-09: raw kept, every choice audited. FE-SIMP-07: bulk is a second
  control. FE-A11Y-07: announce "Merged".

### Steps
1. Add the planner, the two screens and the apply step.
2. Tests:
   - `merge_planner_test.dart`, pure Dart, covers each rule and each tombstone ordering. Planning the same package
     twice after applying it gives an empty plan.
   - `merge_apply_impl_test.dart`: a failure part-way leaves rows and files unchanged.
   - Widget tests: the preview's counts and its four states; each conflict choice and both bulk actions write one
     audit entry per conflict.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] A package from a compatible project merges: new records and photos arrive, identical ones are skipped, and
      every remaining difference is decided by a person.
- [ ] Importing the same package twice changes nothing the second time.
- [ ] Cancelling at the preview or on a conflict writes nothing.

## W22 — Check incoming records for possible duplicates

**Feedback:** R3 · **Type:** Suggestion · **Priority:** P6 · **Effort:** M · **After:** W5, W21

### Evidence
- R3, and specification §40. The `duplicates` table and its helpers exist
  (`frontend/lib/core/db/tables/duplicates.dart:25-52`, `:67`, `:144`), but no detector does: `features/quality`
  is an empty barrel.
- `records.identityHash` hashes the capture session, not the identity fields
  (`frontend/lib/features/capture/data/capture_record_writer.dart:78-80`), so it cannot find duplicates.
- A fuzzy matcher exists in reference data (`frontend/lib/features/reference/domain/fuzzy_matcher.dart:8-60`).

### Scope
- Reach: the merge preview on every platform.
- Change, per D17(a):
  - Move `FuzzyMatcher` to `frontend/lib/core/normalise/fuzzy_matcher.dart`, since a second feature now needs it
    (FE-STR-09), and update its callers in `features/reference`.
  - New pure-Dart `features/quality/domain/duplicate_signals.dart`, exported by the quality barrel.
    `DuplicateSignals.find(incoming, local)` compares only incoming records the plan inserts against live local
    records under the same template key. It returns `DuplicatePair(incomingId, localId, signal, score)` for three
    signals:
    - `identity`: every identity field that is non-empty on both sides is equal after `foldSearchText`, and at
      least one is; score 1.0.
    - `photo`: an identical photo sha256; score 1.0.
    - `caption`: the same context values, capture times within `AppConstants.merge.duplicateWindow` (24 hours),
      and caption similarity from `FuzzyMatcher` of at least 0.9; the score is the similarity.
  - The scan runs on the isolate runner while the plan is built.
  - The preview gets the switch `Copy.mergeCheckDuplicates`, on, and a "Possible duplicates" count. Each pair
    opens a side-by-side view laid out as §40.2 shows: the fields of both records, photo counts, and the signal. The
    view offers Keep both (the default) and `Copy.duplicateSkipIncoming` ("Don't import this record").
  - Apply writes every pair to `duplicates`: unresolved for Keep both, or resolved `discard_new`, with its
    chooser, for a record not imported. A record not imported brings none of its fields or photos.
- Do not change: anything automatic; no pair is ever settled without a person.

### Rules
- FE-SIMP-08: a warning never blocks the merge. FE-PERF-02: scoring stays off the UI thread.

### Steps
1. Move the matcher, then add the signals, the switch and the pair view.
2. Tests:
   - `duplicate_signals_test.dart`, pure Dart: each signal, only cross-boundary comparison, and none for different
     templates.
   - Widget tests: the switch off finds nothing; "Don't import" removes the record from the plan; the pairs are
     stored after apply.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] With the check on, incoming records that match a local one by identity fields, photo or caption are listed
      before the merge, and a person chooses for each.
- [ ] With the check off, the merge proceeds without the scan.

## Verification

- After the last item, run the full `cd frontend && dart run tool/verify.dart`. It fails only the gates that fail on
  the commit before this prompt, with the same findings, which the task lists by name. Those are the test-presence
  list, the architecture errors and state tests, the naming and structure checkers, and the dependency check's
  CRLF miss. Nothing here adds to them.
- Regenerate goldens with `--update-goldens` only for the following, and list the files under each item:
  - `app_list_tile`, `nav_pane_golden_test` and `project_list_golden_test` (W2);
  - `context_hierarchy_screen_test` (W3);
  - the new `responsive_pair_row_compact_*` images (W4);
  - `app_section_header` (W6);
  - `context_bar_golden_test` (W14);
  - `export_summary_golden_test` (W17).
- In a browser with `python run-tools/run-web.py`, and on an Android device:
  - export a project with photos;
  - import the package on the other platform as a new project;
  - change a field on each side, export again and merge;
  - settle the conflict and one possible duplicate;
  - confirm that a second merge of the same package changes nothing.
