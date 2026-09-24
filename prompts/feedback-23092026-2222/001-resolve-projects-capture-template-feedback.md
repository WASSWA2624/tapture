# 001 — Resolve projects, capture and template feedback

**Feedback:** FBK0000057, FBK0000058, FBK0000059, FBK0000060, FBK0000064, FBK0000066, FBK0000067, FBK0000068, FBK0000069, FBK0000070, FBK0000071, FBK0000072, FBK0000073, FBK0000074 · **Work items:** 8 · **Depends on:** none

## Goal
Make photo capture and editing dependable and legible, preserve project-scoped template navigation, compact the Projects and Capture surfaces, clarify project and queue destinations, and expose working local project transfer actions. Land the shared causes across every supported persistent-capture platform, all three size classes, both orientations, light, dark and outdoor themes, and 200 percent text.
All screenshots were recorded on Android mobile 1.0.0 at compact portrait, system dark, text scale 1 and offline by choice; those observations do not limit the reach.

## Run order

| Item | Title | Feedback | Type | Priority | Effort | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| W1 | Repair photo preview and editing | FBK0000067, FBK0000069, FBK0000070 | Defect | P2 | L | — |
| W2 | Preserve project template navigation | FBK0000064 | Defect | P2 | M | — |
| W3 | Compact the capture surface | FBK0000066, FBK0000068, FBK0000069, FBK0000071 | Improvement | P3 | M | W1 |
| W4 | Compact project search and filters | FBK0000057, FBK0000058 | Improvement | P3 | M | — |
| W5 | Clarify template addition state | FBK0000059, FBK0000060 | Gap | P3 | M | W2 |
| W6 | Clarify project home destinations | FBK0000074 | Improvement | P3 | S | — |
| W7 | Recompose the processing queue | FBK0000073 | Improvement | P3 | M | — |
| W8 | Add project import and export | FBK0000072 | Suggestion | P4 | XL | W4, W6 |

## Decisions

⛔ Stop here. Get an answer to every decision before step 1 of any work item. "Proceed" means the default.

- D1 (W1): How should an edited photo appear while its immutable original is retained and derivation metadata is added to stored photo rows? Options: (a) show the newest derived version as the active photo and expose Revert to walk back to the original; (b) show the original and every derived version as separate tray photos. Both add nullable derivation and rotation columns through a forward-only migration, with existing rows treated as originals. Default: (a), because crop, text and drawing then behave like edits while FE-SEC-08 still protects the original.
- D2 (W6): How should the four project-home destinations become unambiguous? Options: (a) retain the responsive grid and add destination icons, explicit pending-state labels and explanatory count copy; (b) replace the grid with four `AppListTile` rows carrying the same information. Default: (a), because it preserves the current information architecture and compact scan pattern.
- D3 (W7): Which queue composition should replace the raw text block? Options: (a) a compact status summary followed by one primary processing action and grouped queue rows; (b) separate status sections followed by the same action and rows. Default: (a), because the totals stay visible without pushing the queue below the fold.
- D4 (W8): What do Import and Export mean in a selected project's menu? Options: (a) record import and readable project exports using the contracts in dev-plan tasks 018 and 020; (b) whole-project portable bundles and merge using the contract in task 019 and its prerequisites. Default: (a), because the action is scoped to an existing project and produces files usable outside Tapture.

## Rules

- FE-SEC-05, FE-SEC-08: treat imported content as untrusted data and never overwrite raw evidence.
- FE-STATE-06, FE-STATE-07: keep one source of truth and persist every write before confirming it in the interface.
- FE-CONS-01, FE-CONS-02, FE-CONS-05, FE-CONS-06, FE-STR-09: extend the catalogue and shared flows once; do not fork sheets, rows, menus, thumbnails or status visuals.
- FE-RESP-03, FE-RESP-06, FE-RESP-07, FE-RESP-10, FE-A11Y-01, FE-A11Y-02, FE-A11Y-03: keep state across adaptive layouts and test every layout at the required matrix.
- FE-L10N-01, FE-L10N-03, FE-L10N-04: route visible copy through `Copy`, use complete messages and format counts with the active locale.
- FE-TEST-01, FE-TEST-02, FE-TEST-10: ship unit, repository, widget, route and failure-path coverage with the implementation.
- FE-FLOW-06: add no dependency in this prompt. Reuse the packages and platform wrappers already allowed by the project.

## Before the work items

1. Record W1-W7 in `dev-plan/23-hardening/062-resolve-feedback-23092026.md`; record W8 against tasks 018 and 020 under D4(a), and task 019 plus its declared prerequisites under D4(b) (FE-FLOW-08).
2. Run `cd frontend && dart run tool/verify.dart --fast` and save the baseline. Keep pre-existing failures distinct from regressions introduced by this prompt.

## W1 — Repair photo preview and editing

**Feedback:** FBK0000067, FBK0000069, FBK0000070 · **Type:** Defect · **Priority:** P2 · **Effort:** L · **After:** —

### Evidence

- FBK0000067: the report combines lost captures with missing preview, crop, text, drawing and scoped captions; its Android compact dark screenshot shows an empty capture state. Photo durability is already fixed by `frontend/lib/features/capture/presentation/capture_controller.dart:69-80`, which saves bytes and session state before emitting, and by the restore coverage in `frontend/test/features/capture/presentation/capture_feedback_test.dart:173`.
- FBK0000069: the Android compact dark screenshot shows a text placeholder where a captured-photo thumbnail should be. `frontend/lib/features/capture/presentation/photo_tray.dart:57-115` renders labels and hard-coded decoration instead of `AppPhotoThumb`.
- FBK0000070: the Android compact dark screenshot shows rotate, crop, caption and text controls in the viewer, but `capture_screen.dart:428-442` never supplies `onRotate`, `photo_crop_screen.dart:50-69` creates a fixed-height band from one drag coordinate, and `photo_markup.dart:36-61` has text markup but no drawing operation.

### Scope

- Reach: Android, iOS, Windows, macOS and Linux capture from compact through expanded, portrait and landscape, every theme and 200 percent text. Exclude web persistence because `dev-plan/23-hardening/029-enable-app-database-on-web.md` is unfinished; retain the current in-memory web capture behavior without a new storage claim.
- Change: `frontend/lib/core/db/tables/photos.dart`, `app_database.dart`, generated Drift output and migration fixtures; `photo_draft.dart`, a pure-Dart derivation selector beside it, `capture_photo_repository.dart`, `drift_photo_repository.dart`, `capture_controller.dart`, `photo_tray.dart`, `photo_viewer_screen.dart`, `photo_crop_screen.dart`, `photo_markup.dart`, a new `photo_doodle_screen.dart`, `capture_screen.dart`, `AppPhotoThumb`, the repository fakes and the related capture tests.
- Do not change: original evidence bytes, caption and audio scope semantics, photo ordering, template choice, save-and-process behavior, retention and tombstone rules.

### Rules

- FE-SEC-08, FE-STATE-07: every edit is a durable derived asset linked to immutable source evidence.
- FE-CONS-06, FE-PERF-02, FE-PERF-04: render `AppPhotoThumb`, decode cached thumbnails, and run image transforms away from the UI thread.
- FE-STR-05, FE-STR-11: keep derivation logic pure and filesystem reads behind a repository or `core/files` interface with a fake.
- FE-A11Y-02, FE-A11Y-05: label every editor control and show selection through a non-colour signal.

### Steps

1. Add nullable derivation and rotation columns to stored photos through one forward-only database migration per D1; existing rows become root originals. Regenerate Drift output and prove upgrade, rollback-safety and old-row reads with migration tests.
2. Add a pure `PhotoDerivation` selector that resolves the tray, completed-record and processing photo set per D1 from `PhotoDraft.derivedFrom`; reject cycles and missing ancestors with a typed failure.
3. Extend `CapturePhotoRepository` and its Drift implementation with durable photo-byte and cached-thumbnail reads. Resolve project paths in the data layer through `StorageRoot` and `ProjectFolders`; update every fake.
4. Refactor `PhotoTray` to render the resolved photos through `AppPhotoThumb`, including real thumbnails after process restart, caption marks, selected state, processing state and a labelled add-photo target.
5. Wire viewer rotation through `PhotoRotate` and `CaptureController.updatePhoto`; apply rotation in the tray and viewer. Replace the crop gesture with a visible, adjustable crop region that maps correctly through rotation.
6. Add freehand drawing with undo and clear, keep text placement legible, and save crop, text and drawing results through the same derived-photo write path per D1. Refresh the viewer and tray only after persistence succeeds.
7. Preserve a recoverable original and a working Revert path after repeated edits, completed-record filing and app restart. Report missing source files through the shared typed failure and keep the capture session usable.
8. Extend `capture_feedback_test.dart`, `capture_widgets_test.dart`, database migration and repository tests, and `photo_actions_test.dart`; add intended `AppPhotoThumb` gallery and golden coverage, then make `cd frontend && dart run tool/verify.dart --fast` green.

### Acceptance criteria

- [ ] Every captured image displays an actual cached thumbnail after capture and after session restoration on each included platform.
- [ ] Rotate, crop, text and drawing visibly update the active photo, survive restart and retain the byte-identical original.
- [ ] Derivation and rotation metadata survive capture completion and database upgrade, with every pre-migration photo readable as an original.
- [ ] Revert restores the preceding version through the original without deleting raw evidence.
- [ ] Failed reads and failed derived writes keep every prior photo and caption available with a plain recovery action.
- [ ] Captions still target the current photo, selected photos and all photos; audio keeps its existing record and photo links.
- [ ] FBK0000067's durability portion remains covered by the existing persistence tests, and W1 closes its remaining preview and editor portion together with FBK0000069 and FBK0000070.

## W2 — Preserve project template navigation

**Feedback:** FBK0000064 · **Type:** Defect · **Priority:** P2 · **Effort:** M · **After:** —

### Evidence

- FBK0000064: Back from a template opened while adding it to a project lands on Settings; the Android compact dark screenshot shows the Settings index after that navigation.
- `frontend/lib/app/router.dart:521-525` gives the project branch only a shallow `templates` route, while `template_list_screen.dart:182-197` and `shipped_picker_screen.dart:244-249` send every create, library and detail action to `/more/templates`. The global branch owns those child routes at `router.dart:678-750`, so system Back returns through Settings.

### Scope

- Reach: every platform, size class, orientation and theme because the route graph and Back behavior are shared. Cover browser history, Android system Back, app-bar Back and desktop keyboard Back.
- Change: `frontend/lib/app/route_paths.dart`, `frontend/lib/app/router.dart`, `template_list_screen.dart`, `shipped_picker_screen.dart`, every template child navigation helper, `frontend/test/app/router_test.dart` and template navigation widget tests.
- Do not change: the existing `/more/templates` deep links, template data ownership, current-project restoration and Settings navigation.

### Rules

- FE-RESP-03, FE-CONS-10: navigation adapts without changing its history semantics.
- FE-SIMP-09: Back never discards a template draft.
- FE-STR-08: keep cross-feature routing through the existing public barrels and route helpers.

### Steps

1. Add project-scoped helpers under `RoutePaths.projectTemplates(projectId)` for library, create, import, detail, field edit and every existing template child destination.
2. Give `projects/:projectId/templates` the same child graph as the global template branch through one reusable route builder. Keep the global paths as valid Settings destinations.
3. Pass project scope into template screens and replace local `/more/templates` string assembly with `RoutePaths` helpers. Keep project-origin create, copy, import, preview, edit and field actions inside the project branch.
4. Make app-bar Back and system Back return from field detail to the project template list, then to project home. Preserve unsaved-form guards at each transition.
5. Add route-helper, deep-link, browser-history and widget navigation tests at compact and expanded widths, then make `cd frontend && dart run tool/verify.dart --fast` green.

### Acceptance criteria

- [ ] Every template destination opened from a project retains `/projects/<projectId>/templates` ancestry.
- [ ] Back from template detail returns to that project's template list and never opens Settings.
- [ ] Global `/more/templates` links still resolve and return through Settings.
- [ ] Draft guards, the current project and template edits survive all tested Back conventions.
- [ ] FBK0000064 is resolved on each surface named under Reach.

## W3 — Compact the capture surface

**Feedback:** FBK0000066, FBK0000068, FBK0000069, FBK0000071 · **Type:** Improvement · **Priority:** P3 · **Effort:** M · **After:** W1

### Evidence

- FBK0000066 and FBK0000071: Android compact dark screenshots show add-photo and photo-caption sheets occupying most of the screen with a second large outlined surface and unused space.
- FBK0000068 and FBK0000069: Android compact dark screenshots show a sparse capture column with weak grouping around photos, audio, captions and the two save actions.
- `frontend/lib/core/widgets/feedback/app_bottom_sheet.dart:51-91` always expands the body, and `showAppSheet` caps every compact sheet at 75 percent height at lines 135-150. `capture_screen.dart:203-299` places the entire flow in one column and gives Save raw and Save and process equal footer width.

### Scope

- Reach: global and project capture on each W1 platform, all size classes, both orientations, every theme and 200 percent text. Expanded layouts keep the established side-panel convention.
- Change: add a content-sized mode to `AppBottomSheet` and `showAppSheet`; use it in the capture add-photo, caption, audio-scope and type-on flows; restructure `CaptureScreen`, `PhotoTray`, `AudioRecorder`, `RecordCaptionField` and capture copy through existing catalogue widgets.
- Do not change: W1 photo behavior, recording lifecycle, caption persistence, template selection, offline capture and save ordering.

### Rules

- FE-CONS-05, FE-SIMP-06, FE-RESP-06: one sheet API, content-sized simple actions and scroll safety under keyboard and large text.
- FE-SIMP-01, FE-SIMP-03: Save and process is the sole primary action; Save raw remains a reachable secondary action without adding a capture tap.
- FE-THEME-01, FE-THEME-06: tokens, tone and outlines only; introduce no private radius, colour or shadow.

### Steps

1. Extend the shared sheet API with an explicit content-sized mode that shrink-wraps short actions, scrolls long content under keyboard insets, and retains the expanded side panel.
2. Apply content-sized sheets to add photo, caption scope, audio scope and type-on. Remove redundant inner surface chrome and keep one title, one action hierarchy and one safe-area boundary.
3. Group photos, evidence audio, record caption and inline fields with `AppSectionHeader` and token spacing. Keep the photo tray above secondary evidence controls and keep fields in the natural focus order.
4. Render Save and process through the page's primary footer action. Place Save raw as the labelled secondary action beside the relevant save context without competing visual weight.
5. Add capture layout and sheet widget tests at 360, 800 and 1200 dp, both orientations, 200 percent text and keyboard-open state; update intended capture goldens in every theme and make the fast gate green.

### Acceptance criteria

- [ ] Short capture sheets use only the height their content needs and contain no nested full-height surface.
- [ ] Every sheet scrolls without clipping at 200 percent text and with the keyboard open.
- [ ] Global and project capture share the same grouped hierarchy and one visually dominant save action.
- [ ] Photo, audio, caption and field state survives rotation and size-class changes.
- [ ] FBK0000066, FBK0000068, FBK0000069 and FBK0000071 are resolved without changing capture persistence.

## W4 — Compact project search and filters

**Feedback:** FBK0000057, FBK0000058 · **Type:** Improvement · **Priority:** P3 · **Effort:** M · **After:** —

### Evidence

- FBK0000057: the Android compact dark screenshot shows a large filter sheet over the Projects surface and asks for a simpler, less nested presentation.
- FBK0000058: the Android compact dark screenshot shows a full-width search field followed by separate labelled Filters and Clear buttons. `frontend/lib/features/projects/presentation/project_list_toolbar.dart:34-64` still implements that two-row column and wrap.

### Scope

- Reach: Projects list and expanded list pane on every platform, all size classes, both orientations, every theme, RTL and 200 percent text.
- Change: `project_list_toolbar.dart`, project filter copy and semantics, `project_list_screen_test.dart`, `project_list_golden_test.dart` and expanded pane goldens. Reuse `AppSearchField`, `AppIconButton` and the shared sheet.
- Do not change: query debounce, active filter criteria, project ordering, pin behavior, archived visibility and the create-project primary action.

### Rules

- FE-A11Y-01, FE-A11Y-02, FE-A11Y-05: icon actions retain 48dp targets, tooltips, semantic state and a visible active signal.
- FE-RESP-06, FE-RESP-10: the toolbar wraps safely only when text scale requires it and never clips.
- FE-CONS-01, FE-SIMP-01: use catalogue controls and retain one primary page action.

### Steps

1. Replace the second toolbar row with filter and clear `AppIconButton` controls inline with the search field. Show Clear only while criteria are active.
2. Give the filter control a selected state and localized semantic label containing the active-filter count. Keep the count readable without a text button.
3. Reduce outer toolbar spacing to the existing compact tokens and keep the expanded pane aligned with its list rows.
4. Keep the existing filter sheet fields and apply behavior; use the W3 content-sized sheet mode only when its content fits, with scrolling retained at large text.
5. Extend toolbar behavior, RTL, semantics and responsive golden tests, then make `cd frontend && dart run tool/verify.dart --fast` green.

### Acceptance criteria

- [ ] Search, Filters and active Clear occupy one compact toolbar row at normal compact text scale.
- [ ] Filters announces its active count and selection without relying on colour.
- [ ] The toolbar remains operable without overflow at every required width, orientation and text scale.
- [ ] Search, filter application, clearing, pins, archived visibility and project ordering retain their existing behavior.
- [ ] FBK0000057 and FBK0000058 are resolved on the list and expanded pane.

## W5 — Clarify template addition state

**Feedback:** FBK0000059, FBK0000060 · **Type:** Gap · **Priority:** P3 · **Effort:** M · **After:** W2

### Evidence

- FBK0000059: the project-context empty state says “Open Templates” where the requested action is adding templates. The current value is `Copy.contextOpenTemplates` at `frontend/lib/core/copy/copy.dart:1720`.
- FBK0000060: the Android compact dark shipped-library screenshot gives no sign that a shipped template is already attached. `shipped_picker_screen.dart:83-103` renders only name and field count, while `_ShippedPicker.add` at lines 199-228 always offers another copy.

### Scope

- Reach: project context, pinned-fields empty state and shipped template library on every platform, size class, orientation and theme. The global Settings template list keeps its current management wording.
- Change: visible template-add copy in `Copy`, `context_hierarchy_screen.dart`, `pinned_fields_sheet.dart`, `shipped_picker_screen.dart`, a derived association provider using `TemplateRepository.watchByProject`, and their tests.
- Do not change: shipped template definitions, template keys, existing project copies, global template management and the editable-copy capability.

### Rules

- FE-STATE-06, FE-STATE-08: derive association state from the live project-template stream.
- FE-L10N-01, FE-L10N-03: use complete localized action and status copy.
- FE-SIMP-05, FE-SIMP-07: show the known association and make an intentional second copy one clear decision.

### Steps

1. Change the project-context action copy to “Add templates” through the existing `Copy` symbol and update all project-context call sites.
2. Derive shipped-library association by stable `templateKey` against the open project's live templates. Render “Added to this project” as text plus a status icon on each matching row.
3. In preview, present Add to project for an unattached shipped template. For an attached template, show the association and label the submit action Create a custom copy so a second copy is explicit.
4. After a successful add, stay in the W2 project route and open the new editable field list. Keep failure state on the preview with the typed recovery message.
5. Add provider, widget, duplicate-name and route tests to `shipped_picker_screen_test.dart`, context screen tests and W2 router tests, then make the fast gate green.

### Acceptance criteria

- [ ] Project context and pinned-field empty states say “Add templates” and open the project-scoped library.
- [ ] Every shipped template already represented in the project is visibly marked before preview.
- [ ] An unattached template adds once through Add to project; an attached template creates another copy only through the explicitly labelled custom-copy action.
- [ ] Added templates open inside the project route and remain editable independently of the shipped library and sibling copies.
- [ ] FBK0000059 and FBK0000060 are resolved without mutating shipped definitions.

## W6 — Clarify project home destinations

**Feedback:** FBK0000074 · **Type:** Improvement · **Priority:** P3 · **Effort:** S · **After:** —

### Evidence

- FBK0000074: the Android compact dark screenshot shows four cards labelled only Review, Process, Export and Share with zero counts and calls them ambiguous.
- `frontend/lib/features/projects/presentation/project_home_screen.dart:249-295` supplies terse visible labels while its richer pending descriptions are semantics-only at lines 252-278.

### Scope

- Reach: project home on every platform, size class, orientation and theme, including RTL and 200 percent text.
- Change: `_countRows`, `_CountCard`, the `Copy.home*` visible messages, project-home widget tests and intended project-home goldens per D2.
- Do not change: destination routes, live count queries, count meanings, project association rows and Continue capturing.

### Rules

- FE-THEME-05, FE-A11Y-05: pair each status with icon, text and count.
- FE-L10N-03, FE-L10N-04: use complete pluralized messages and locale-formatted counts.
- FE-SIMP-10, FE-CONS-08: use plain action language and the established icon for each destination.

### Steps

1. Implement the D2 presentation with visible labels “Needs review”, “Ready to process”, “Ready to export” and “Exports to share”, each paired with its established icon and localized count message.
2. Make zero state explicit in visible copy and keep the entire destination target tappable with one semantic announcement.
3. Keep two columns on compact and four on medium and expanded under D2(a); use one column on compact and two on wider layouts under D2(b). Preserve reading and focus order.
4. Add route-tap, pluralization, semantics and responsive golden coverage in `project_home_screen_test.dart`, then make the fast gate green.

### Acceptance criteria

- [ ] Every destination states what its count means without requiring a tap.
- [ ] Zero, singular and plural counts read naturally and use locale formatting.
- [ ] Icons, text and semantics identify the same destination and pending state.
- [ ] The layout survives every required width, orientation, theme, RTL and text scale without clipping.
- [ ] FBK0000074 is resolved without changing the four routes and their queries.

## W7 — Recompose the processing queue

**Feedback:** FBK0000073 · **Type:** Improvement · **Priority:** P3 · **Effort:** M · **After:** —

### Evidence

- FBK0000073: the Android compact dark screenshot shows four unstructured text lines, two stacked processing buttons and one queue group with weak hierarchy.
- `frontend/lib/features/processing/presentation/queue_screen.dart:51-148` concatenates raw count strings, and `process_actions.dart:53-62` renders Process selected while its callback is null.

### Scope

- Reach: global and project-filtered queue on every platform, size class, orientation and theme, including offline-by-choice and 200 percent text.
- Change: `queue_screen.dart`, `process_actions.dart`, queue copy, existing processing screen tests and new intended queue goldens per D3.
- Do not change: queue queries, request caps, egress confirmation, retry semantics, cancellation and processing order.

### Rules

- FE-CONS-04, FE-CONS-06: keep four-state rendering and use shared rows and status visuals.
- FE-L10N-03, FE-L10N-04: replace concatenation with localized messages and locale-formatted counts.
- FE-SIMP-01: expose one primary batch action before processing starts.
- FE-SEC-03, FE-SEC-04: retain explicit egress preview and absolute offline behavior.

### Steps

1. Build the D3 summary from `AppStatusPill`, `AppSectionHeader`, `AppListTile` and token spacing. Show unprocessed, queued, failed and daily usage as complete localized messages.
2. Keep Process all as the sole primary idle action. Render Process selected only when a real selection callback and a non-empty selection exist; retain Cancel as the primary running action.
3. Separate failed jobs from context groups with labelled sections. Keep retry on failed rows and batch processing on group rows, with counts and status icons visible.
4. Keep progress and completion summary adjacent to the action and announce running, completed and failed state changes.
5. Extend `processing_screens_test.dart` for global and project filters, null selection, failures, offline state, running state, semantics and responsive goldens; make the fast gate green.

### Acceptance criteria

- [ ] Queue totals and daily usage have a clear visual and semantic hierarchy under D3.
- [ ] Exactly one primary action is visible in idle and running states.
- [ ] Process selected is absent until a non-empty selection has a working callback.
- [ ] Failed jobs and context groups remain actionable, correctly counted and visibly distinct.
- [ ] Egress confirmation, offline behavior, retries and cancellation retain their current guarantees.
- [ ] FBK0000073 is resolved on global and project queue routes.

## W8 — Add project import and export

**Feedback:** FBK0000072 · **Type:** Suggestion · **Priority:** P4 · **Effort:** XL · **After:** W4, W6

### Evidence

- FBK0000072: the Android compact dark screenshot shows a project overflow with rename, pin, archive and delete actions but no import and export commands.
- `frontend/lib/features/projects/presentation/project_list_view.dart:130-168` and `project_home_screen.dart:299-343` omit transfer actions. The current `features/import/` presentation layer is empty, and the export route at `router.dart:493-498` is still a placeholder.

### Scope

- Reach: project-list row menu and project-home menu on every platform and size class. Implement native file selection and sharing through existing wrappers; exclude automatic cloud transfer because the feedback requests local project actions and FE-SEC-03 forbids undeclared egress.
- Change: a reusable `project_transfer_actions.dart`, project menu builders, `route_paths.dart`, `router.dart`, import and export feature barrels, then the exact files and contracts declared by dev-plan tasks 018 and 020 under D4(a), and task 019 with its declared prerequisites under D4(b).
- Do not change: automatic sync, background egress, provider credentials, raw evidence, unrelated project commands and the existing template and reference-data importers.

### Rules

- FE-SEC-04, FE-SEC-05, FE-SEC-06, FE-SEC-08, FE-SEC-09: work offline, validate before reading, preserve evidence and audit every transfer.
- FE-STATE-07, FE-SIMP-07, FE-SIMP-09: preview before writes, commit atomically and retain recovery without discarding input.
- FE-PERF-02, FE-PERF-07, FE-PERF-10: stream large files in isolates with progress and cancellation.
- FE-CONS-01, FE-STR-04, FE-STR-11: reuse the existing file gate, readers, writers and platform services through feature contracts.

### Steps

1. Implement the selected D4 dev-plan contracts completely in their declared dependency order, reusing `FileValidation`, the existing spreadsheet reader, export storage, transaction helpers and platform share wrappers.
2. Add project-scoped import and export routes that receive the selected project id and render real four-state screens. Replace the current project export placeholder.
3. Add shared Import and Export actions to both project overflow surfaces through `project_transfer_actions.dart`; use one copy key and icon per command.
4. Under D4(a), make Import enter the task-020 validated file router with the selected project fixed as destination, and make Export open the task-018 scope screen preselected to that project. Under D4(b), make Export write the versioned project bundle and make Import inspect, preview and merge it through task 019.
5. Keep every write local-first. Show import effects before commit, require explicit resolution for matched data, record completed transfers, and expose progress, cancellation and retry without partial output.
6. Add pure domain tests, in-memory repository and transaction tests, corrupt-file and interrupted-write tests, route and overflow widget tests, platform-wrapper fakes and the performance assertions named by the selected task set.
7. Make each selected dev-plan Definition of done green, then make `cd frontend && dart run tool/verify.dart --fast` green.

### Acceptance criteria

- [ ] Import and Export appear in project-list and project-home overflow menus and always target the selected project.
- [ ] Each command opens a complete, working local flow under D4 with loading, empty, failure and offline states.
- [ ] Import validates content before reading, previews effects before writing and never silently overwrites stored data.
- [ ] Export writes reproducible, recorded output without overwriting an earlier export and shares only after an explicit user action.
- [ ] Large transfers show progress and cancellation while preserving the previous durable state.
- [ ] Corrupt, unsupported and interrupted inputs leave the project and raw evidence unchanged with a plain recovery action.
- [ ] FBK0000072 is resolved without adding automatic network egress.

## Verification

- Run the focused tests named under every work item and all changed repository, route, widget, semantics and golden suites.
- Test compact, medium and expanded widths in portrait and landscape, light, dark and outdoor themes, default and 200 percent text; test RTL where layout direction changes.
- Exercise capture, Back navigation, project menus, queue actions and the D4 transfer flow offline on a production-supported mobile target.
- Regenerate goldens with `--update-goldens` only for visuals named by W1, W3, W4, W6 and W7, and list every regenerated file under its work item.
- After the last item, the full `cd frontend && dart run tool/verify.dart` is green.
