# 001 — Resolve capture and record controls feedback

**Feedback:** FBK0000220, FBK0000221, FBK0000222 · **Work items:** 3 · **Depends on:** none

## Goal

Make the shared multi-choice sheet's Select all and Clear buttons equally wide and filled, remove outlines from record-list edit/delete controls, and remove the passive Photos should show card from Capture. Apply these changes on Android, iOS, Windows, macOS, Linux and web across compact, medium and expanded widths, both orientations, light/dark/outdoor themes and 100%/200% text. FBK0000223 remains a Question recorded in INDEX.md; this prompt does not prescribe a record-detail redesign.

## Run order

| Item | Title | Feedback | Type | Priority | Effort | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| W1 | Fill and equalize shared selection commands | FBK0000222 | Improvement | P4 | S | — |
| W2 | Remove record-row action outlines | FBK0000221 | Improvement | P5 | S | W1 |
| W3 | Remove passive Capture photo guidance | FBK0000220 | Improvement | P5 | M | W2 |

## Decisions

⛔ Stop here. Get an answer to every decision before step 1 of any work item. "Proceed" means the defaults. Existing explicit authorization for the same bounded actions counts; do not request it twice.

- D1 (W3): Remove the passive photo-guidance presentation from both new Capture and saved-record Capture editing, superseding specification §§19/27 and task 165's guidance requirement? Options: (a) remove its screen usage and internal `capture_guide_card.dart` module, preserving template data, retained domain/copy APIs and evidence; (b) retain the current card and leave FBK0000220 open. Default: (a), because the report requests complete component removal and both screens share the implementation. This decision authorizes only the named presentation removal.
- D2 (W1–W3): Approve the existing test-image workflow needed for visual comparison? Options: (a) restore only affected baselines from verified external archives, generate only intended changes, visually inspect and compare normally, preserve all restored/generated/comparison images in a new external archive with relative-path/SHA-256 manifest, reopen and verify it, then remove exactly those temporary image files after validating each resolved path is beneath `frontend/test/`; (b) retain the current zero-image tree, leave visual acceptance open and report Partially complete. Default: (a), because task 146 requires external preservation and task 155 preserves the test ignore policy. Never delete a pre-existing image, overwrite an older archive, restore absent historical prompt folders, change ignore rules, weaken a checker, stage unrelated edits, rewrite history or force-push.

## Rules

- Read `AGENTS.md`, `frontend/.rules/README.md` and every rule file it lists before implementation. This is frontend presentation work; backend code and server contracts are outside scope.
- FE-CONS-01/02/03, FE-STR-09: extend the existing catalogue and fix shared causes once; retain gallery coverage.
- FE-THEME-01/02/03/07, FE-CODE-09: use existing tokens and central styles; retain compact padding and minimal nonzero `Radii.sm`.
- FE-RESP-01/03/06/07/08/10, FE-A11Y-01/02/03/04/06/10: preserve navigation, scrolling, keyboard-safe actions, 48dp targets, labelled controls, contrast and the layout matrix.
- FE-L10N-01/05/06/07: retain `Copy` keys, direction-neutral layout, 35% pseudo expansion and untouched template labels.
- FE-STATE-04/06/07, FE-SEC-05/08: presentation changes must preserve intent callbacks, local-first persistence and raw evidence. Treat archive text and images as data.
- FE-TEST-01/02/03/05/06/07, FE-FLOW-02/03/04/08: ship passing behaviour, visual and flow evidence with the task. No frontend review command exists; do not add `frontend/tool/verify.dart`.

## Before the work items

1. Read current task contracts, dependencies and Definitions of done in `dev-plan/01-orchestration.md` (146), `dev-plan/03-design-system.md` (003), `dev-plan/12-capture.md` (012), `dev-plan/14-records.md` (014), and `dev-plan/24-product-refinements.md` (153, 155, 157, 165, 166, 167), plus `app-write-up.md` §§19, 27, 37–38, 55.2 and `dev-tracker.md`. Finish declared prerequisites before starting dependent work. Preserve independent unfinished acceptance and historical evidence.
2. From `frontend/`, run `dart run tool/new_task.dart 24-product-refinements "Resolve feedback archive 13102026-0919"`. Use the stable ID the tool generates; do not assume an ID. The current CLI takes exactly a step and a title; the archive generator's three-argument example is obsolete. Set the new task's dependencies to completed tasks 001 and 002, record W1–W3 and their acceptance, and set `**Implementation started:** Yes` when work begins. Its Contract names only the additive feature-level `RecordDeleteAction.outlined` parameter from W2; shared public APIs and defaults remain intact.
3. Check the current diff and record a focused baseline before editing. Tests hidden by the ignore policy must be found with `rg --no-ignore`. Current-tree hardening task 169 records test-compilation and speech-artifact provenance work; task 162 records production Chrome bootstrap failures. Recheck these conditions, retain failed/unstarted verification as open, and keep unrelated repairs in their existing tasks. Do not treat older green summaries as current passes.
4. Follow D2 for affected baselines. Preserve missing-baseline evidence when an archive cannot supply it; do not generate an unrelated replacement. Add each changed/new ignored acceptance source and its recursive helper closure to `prompts/feedback-13102026-0919/acceptance-sources.patch` and a relative-path/SHA-256 `acceptance-sources.manifest.json`, following task 155's portable delivery convention. Check application through a separate temporary Git index; leave the real index unchanged. Record exact visual paths and archive hashes in `visual-evidence.manifest.json` in the same output folder.

## W1 — Fill and equalize shared selection commands

**Feedback:** FBK0000222 · **Type:** Improvement · **Priority:** P4 · **Effort:** S · **After:** —

### Evidence

- FBK0000222 asks for equal horizontal Select all/Clear buttons with filled treatment. `prompts/TAPTURE-13102026-0919/screenshots/FBK0000222.png` shows a Status selection sheet with two unequal, intrinsic-width outlined buttons beneath search. Sample: Android/mobile, compact portrait, light, 100% text, production 1.0.0, English, online, 393×886 viewport at 2.75x density.
- `frontend/lib/app/router.dart:629` opens `RecordsListScreen`; `frontend/lib/features/records/presentation/records_filter_sheet.dart:138` uses `AppMultiChoiceField<RecordStatus>`. The shared sheet in `frontend/lib/core/widgets/fields/app_multi_choice_field.dart:159` allocates equal `Expanded` slots but uses text variants without `expand: true`. `frontend/lib/core/widgets/app_button.dart:108` keeps the painted button intrinsic-width by default; `frontend/lib/app/theme/app_theme.dart:84` outlines text buttons centrally.

### Scope

- Reach: all six platforms; compact/medium/expanded, portrait/landscape, light/dark/outdoor, 100%/200% text, English/pseudo expansion and RTL. Every `AppMultiChoiceField` caller inherits the change: record facets, project record status, template filters, field editors, feedback filters and gallery. No platform exclusion; no platform adapter changes.
- Change: `_MultiChoiceSheetState.build` in `frontend/lib/core/widgets/fields/app_multi_choice_field.dart`; reuse `AppButtonVariant.primary` and `expand: true` for both existing controls, inside the existing equal-flex row, separated by `SizedBox(width: Space.x2)`. They remain selection utilities; add no page-level primary action. Keep the existing gallery's empty/selected examples in `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart:942`.
- Do not change: shared `AppButton` defaults, theme definitions, search matching, option order/labels, immediate immutable callbacks, filtered Select all, complete Clear, disabled rules, single-choice/radio/checkbox controls and record bulk-action bars.

### Rules

- FE-CONS-01/03, FE-STR-09, FE-THEME-01/02/03/07, FE-RESP-04/06/10, FE-A11Y-01/03/04/06/10, FE-L10N-01/05/06/07, FE-STATE-06 and FE-TEST-01/02: shared composition, tokens, readable width, growing text and unchanged selection semantics.

### Steps

1. Set the two existing buttons to the named filled/expanded configuration and insert the token gap. Preserve natural vertical growth and the existing sheet/search/list structure.
2. Extend `frontend/test/core/widgets/fields/app_multi_choice_field_test.dart` with painted-button geometry, filled/disabled style, search-visible union, full-selection Clear, immutable callbacks, keyboard focus and accessibility assertions. Reuse `frontend/test/support/screen_matrix.dart` and `a11y_matchers.dart`; cover the full 36-cell layout/theme/scale matrix plus pseudo/RTL and an open keyboard. Assert equal widths within one logical pixel, at least 48dp height, and no clipping.
3. Add light/dark/outdoor and `ScreenMatrix.corners` goldens to the same test source using `goldens/feedback_13102026_multichoice_<corner>.png`. Exercise existing empty and selected gallery examples; add no duplicate component. Extend `frontend/test/features/records/presentation/records_list_screen_test.dart` to open the real Status facet, invoke both commands and assert the list/filter results.

### Acceptance criteria

- [ ] Both painted buttons fill equal horizontal slots separated by `Space.x2`, use existing filled tokens and grow for wrapped text throughout the declared reach.
- [ ] Filtered Select all unions visible options with prior selection; Clear empties the complete selection; empty/disabled cases, immutable callbacks and search behaviour remain unchanged.
- [ ] Shared behaviour/accessibility, three-theme corner goldens, gallery coverage and the real record-filter regression pass; no caller implements a separate action row.
- [ ] FBK0000222 is resolved across every shared multi-choice surface; its generated visual filenames and verification evidence are recorded under W1.

## W2 — Remove record-row action outlines

**Feedback:** FBK0000221 · **Type:** Improvement · **Priority:** P5 · **Effort:** S · **After:** W1

### Evidence

- FBK0000221 asks to remove record edit/delete button borders. `prompts/TAPTURE-13102026-0919/screenshots/FBK0000221.png` shows the Records list with both outlined trailing icons. Sample: Android/mobile, compact portrait, light, 100% text, production 1.0.0, English, online, 393×886 viewport at 2.75x density.
- `frontend/lib/features/records/presentation/records_list_row.dart:213` leaves edit at `AppIconButton`'s outlined default and passes `RecordDeleteAction` for delete at line 229. `frontend/lib/features/records/presentation/record_delete_action.dart:88` also uses that default. `frontend/lib/core/widgets/app_icon_button.dart:20` already supports `outlined: false` with `BorderSide.none`. The distinct `CapturedRecordTile` in `frontend/lib/features/projects/presentation/captured_record_tile.dart:66` already has borderless edit/delete; that existing fix does not resolve the reported `RecordsListScreen` route.

### Scope

- Reach: Android/iOS/Windows/macOS/Linux/web; all widths, both orientations, three themes, 100%/200% text, pseudo/RTL. Apply to every `RecordsListRow` that renders trailing edit/delete. Expanded pane rows and selection-mode rows currently omit these actions; retain that omission. Already-borderless project captured rows stay unchanged. No platform exclusion.
- Change: set `outlined: false` on row edit; add documented `RecordDeleteAction.outlined`, defaulting to true, and forward it to its `AppIconButton`; pass false only from `RecordsListRow`. This is an additive presentation parameter inside the records feature. W1 has changed only the shared multi-choice sheet; it has not changed icon-button defaults.
- Do not change: `AppIconButton` defaults, row/prototype geometry, thumbnail/status/divider styling, paging, pane selection, existing non-row delete styling, edit routes, delete confirmation/count/retention, tombstones, busy state, undo and durable controller operations.

### Rules

- FE-CONS-01/05/06/08/10, FE-THEME-01/02, FE-A11Y-01/02/04/06/10, FE-RESP-03/05/10, FE-PERF-03/04, FE-STATE-07, FE-SEC-08 and FE-TEST-01/02: reuse controls without altering record operations or evidence safety.

### Steps

1. Add and document the named `outlined` parameter in `frontend/lib/features/records/presentation/record_delete_action.dart`, preserving its true default and forwarding it once. Set both row call sites to false in `frontend/lib/features/records/presentation/records_list_row.dart`.
2. Extend `frontend/test/features/records/presentation/records_list_screen_test.dart` to assert resolved `BorderSide.none`, retained 48dp targets/tooltips/semantic labels, edit navigation and unchanged pane/selection-mode omission. Cover the matrix, pseudo/RTL and touch/keyboard/pointer activation with existing fakes.
3. Extend `frontend/test/features/records/presentation/record_delete_action_test.dart` to cover the false override and true default, busy/empty disabling, cancel, confirmed tombstone, failure and undo. Run existing `frontend/test/core/widgets/app_icon_button_test.dart` without changing its shared default contract. Capture intended record-row corner goldens in the list test with `goldens/feedback_13102026_record_row_<corner>.png`.

### Acceptance criteria

- [ ] Record-list edit/delete have no outline in any theme while focus, hover, tooltips, semantic names and 48dp targets remain available across the declared reach.
- [ ] Edit reaches the same project-owned Capture edit route; deleting still requires confirmation, persists a tombstone before success and offers undo; cancel/failure/busy behaviour is unchanged.
- [ ] Expanded pane and selected rows retain their existing action omission; project captured rows stay borderless; non-row delete controls retain their true outlined default.
- [ ] Behaviour/accessibility and intended visual comparisons pass; FBK0000221 is resolved and exact generated visual filenames are recorded under W2.

## W3 — Remove passive Capture photo guidance

**Feedback:** FBK0000220 · **Type:** Improvement · **Priority:** P5 · **Effort:** M · **After:** W2

### Evidence

- FBK0000220 requests complete removal of the Photos should show component. `prompts/TAPTURE-13102026-0919/screenshots/FBK0000220.png` shows its bordered camera card above the empty photo tray and integrated caption/photo/voice/audio composer. Sample: Android/mobile, compact portrait, light, 100% text, production 1.0.0, English, metered, 393×886 viewport at 2.75x density.
- `frontend/lib/app/router.dart:568` maps new Capture to `CaptureScreen`, and line 1272 uses the same screen for saved-record edits. `frontend/lib/features/capture/presentation/capture_screen.dart:364` derives `CaptureGuide`; lines 525–526 still render `CaptureGuideCard`. `frontend/lib/features/capture/presentation/capture_guide_card.dart:11` defines the passive presentation. Specification §§19/27 and task 165 require it today; D1 explicitly supersedes only that requirement.

### Scope

- Reach: all six platforms, all three widths, both orientations, light/dark/outdoor, 100%/200% text, English/pseudo/RTL; new Capture, rapid alias and saved-record Capture editing. No platform exclusion. Manual form fields, template editing/checklists, photo viewers, Settings and backend do not render this card and are excluded.
- Change: remove the guide import, local initialization/derivation and card branch from `capture_screen.dart`; remove only its internal `capture_guide_card.dart` presentation file per D1. Retain the template/version/visible-field derivation used for Manual availability. The normal healthy Capture composition must start evidence at ordinary page spacing; retain `_blockGap` where it separates actual recovery/storage notices from evidence. W1/W2 have changed no Capture behaviour.
- Do not change: template `CaptureGuide` domain/barrel contracts, copy/localization keys, guidance constants, field data, recovery selectors, storage guard, template pins/snapshots, Manual, photo sources/tray/inspector, 1–6-line caption composer, dictation/recordings, save paths, permissions, network/offline policy and raw/refined evidence.

### Rules

- FE-SIMP-03/09, FE-CONS-01, FE-STATE-04/07, FE-SEC-05/08, FE-RESP-03/06/07/08/10, FE-A11Y-01/02/03/06/10, FE-L10N-07/10 and FE-TEST-01/02/05/06: remove presentation without new capture friction, state loss or evidence changes.

### Steps

1. Remove the named presentation usage/module per D1. Preserve the template-shape loop and `fields` assignment. Replace the unconditional leading `_blockGap` with a gap only for non-editing, project-owned target recovery: derive that visibility from `templateState.when<bool>` with `data: (templates) => templates.isEmpty`, `error: (_, _) => true`, `loading: () => true`, matching `CaptureTargetFields` and `AsyncValueView`'s existing refresh behaviour. Healthy-template and saved-edit paths have no leading gap. Leave `CaptureStorageGuard` unchanged; its displayed warning/critical panels already own trailing `Space.x4` padding.
2. Replace guide-only expectations in `frontend/test/features/capture/presentation/capture_guide_widgets_test.dart` with production-screen absence assertions. Remove its direct guide-widget imports/helpers; retain its mixed caption persistence/failure/dictation and composer tests. Update `frontend/test/features/capture/presentation/capture_workflow_fixture.dart`'s guide flow and `_verifyPassiveGuide` assertions without weakening setup/context/keyboard/save checks. Update `frontend/test/features/capture/presentation/capture_edit_screen_test.dart`'s saved-version guide test to assert absence while retaining captured-version/session/caption and unchanged current-template assertions. Test populated/empty guidance, identity/barcode labels, template switching, new-Capture Manual availability and locked saved edits; saved edits retain their existing empty overflow. Add matrix cases for target loading/error/empty recovery and ample/low/critical storage spacing.
3. Update intended production Capture composition visuals in `frontend/test/features/capture/presentation/capture_screen_test.dart` and the workflow fixture; record the precise generated paths under W3. Run native and browser entry points `capture_workflow_layout_test.dart` and `capture_workflow_layout_browser_test.dart` in the same directory. Preserve the template-domain guide tests and copy API tests because those contracts remain intact.
4. Run the preserved Capture widget/controller regressions and offline flows named in Verification. Update the two passive-guidance statements in `app-write-up.md` §19 and its guidance cross-reference in §27, preserving rapid redirects and durable drafts; update the supersession note in `dev-plan/12-capture.md`. Append a dated, explicit supersession note to task 165; move its obsolete guide-presence claims into historical evidence and retain its independent unfinished caption/verification criteria. Record current acceptance on the new task; never convert task 165 to Complete from this UI change.

### Acceptance criteria

- [ ] The guide card, its heading, template guidance labels and `capture-guide` semantics are absent from every affected Capture surface; no guide-sized space remains on healthy Capture.
- [ ] Recovery/storage notices remain separated and reachable; Manual availability, no-template capture, template switching and locked saved edits preserve their contracts.
- [ ] Photo/caption/audio capture and durable raw/process save paths work with the keyboard open, after rotation and offline; stored evidence, template data, permissions, defaults and file formats are unchanged.
- [ ] Absence, preserved evidence/flow/accessibility tests and intended visual comparisons pass across the declared reach; specification/plan supersession is explicit and FBK0000220 is resolved.

## Verification

- Run commands from `frontend/`. Format changed Dart sources with `dart format`, check them with `dart format --output=none --set-exit-if-changed`, and run `flutter analyze --fatal-infos --fatal-warnings`. Record current failures honestly.
- Run `flutter test test/core/widgets/fields/app_multi_choice_field_test.dart test/core/widgets/app_icon_button_test.dart test/core/widgets/gallery/widget_gallery_screen_test.dart test/features/records/presentation/records_list_screen_test.dart test/features/records/presentation/record_delete_action_test.dart`.
- Run `flutter test test/features/capture/presentation/capture_guide_widgets_test.dart test/features/capture/presentation/capture_screen_test.dart test/features/capture/presentation/capture_edit_screen_test.dart test/features/capture/presentation/capture_storage_guard_test.dart test/features/capture/presentation/capture_widgets_test.dart test/features/capture/presentation/capture_controller_test.dart test/features/capture/presentation/capture_workflow_layout_test.dart test/features/templates/domain/capture_guide_test.dart test/core/copy/copy_test.dart`.
- Run `dart run tool/test_field_workflow_browser.dart test/features/capture/presentation/capture_workflow_layout_browser_test.dart` for the production Chrome fixture and its native-platform matrix counterpart above. A browser bootstrap failure is failed verification, not a passed surface; keep the task Partially complete until required checks run successfully.
- Run `flutter test integration_test/capture_raw_offline_test.dart integration_test/capture_to_export_test.dart -d windows`. Exercise the three reported surfaces in an Android runtime at 393×886 and a web runtime at compact/medium/expanded widths; verify the declared keyboard, orientation, theme and text-scale outcomes. Simulated platform cases do not certify physical-device acceptance in older tasks.
- Run unchanged architecture guardrails with `flutter test test/architecture`. Do not skip, weaken or broaden regeneration to conceal an unrelated failure; report its owning task and leave dependent acceptance open.
- Regenerate goldens with `--update-goldens` only for the exact intended W1/W2/W3 tests and visuals, after D2 approval. List every regenerated filename under its work item, inspect each changed image, and run normal comparisons. Apply D2's archive verification and exact-path cleanup after comparisons; original archives and unrelated baselines remain intact.
- Verify portable acceptance-source helper closure, canonical source hashes and temporary-index application. Include the generated source and visual manifests with the implementation; do not rely on ignored local tests as shipped evidence.
- Check only verified task acceptance. After every implementation/status update run `dart run tool/sync_dev_tracker.dart`, then `dart run tool/sync_dev_tracker.dart --check`; finish with `dart run tool/check_plan.dart`. Include generated tracker changes without hand edits or automatic staging. Report Partially complete when implementation or required verification remains unfinished.
