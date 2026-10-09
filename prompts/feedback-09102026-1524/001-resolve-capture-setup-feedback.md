# 001 — Resolve Capture setup feedback

**Feedback:** FBK0000207, FBK0000208 · **Work items:** 4 · **Depends on:** none

## Goal

New Capture shows the current project's name as its title and the selected template as a quieter second line. Project selection, template selection and editable context values live in the existing title-bar overflow menu, leaving the evidence, caption, guidance and save controls in the main Capture surface. Apply this to Android, iOS, web, Windows, macOS and Linux at compact, medium and expanded widths, both orientations, and light, dark and outdoor themes, including 200 percent text.

## Run order

| Item | Title | Feedback | Type | Priority | Effort | After |
| --- | --- | --- | --- | --- | --- | --- |
| W1 | Expose the existing searchable choice sheet | FBK0000207 | Improvement | P4 | S | — |
| W2 | Add reusable primary and secondary header text | FBK0000208 | Improvement | P4 | M | — |
| W3 | Move Capture target selection into overflow | FBK0000207, FBK0000208 | Improvement | P5 | M | W1, W2 |
| W4 | Move Capture context values into overflow | FBK0000207 | Improvement | P5 | M | W3 |

## Decisions

⛔ Stop here. Get an answer to both decisions before step 1 of any work item. “Proceed” means both defaults. These are decisions for the implementation runner; generating this prompt does not approve them.

- D1 (W3, W4): Approve the Capture presentation change and its bounded supersession of the current specification/task contracts? Options: (a) move all three setup controls into overflow on every new-Capture surface, use the project as the primary title and the template as secondary text, and retain existing record-edit target locking; (b) keep the current inline controls and screen-name title, leaving FBK0000207/0208 unresolved. Default: (a), because both reports explicitly request this presentation. This supersedes the selector-row clauses in §19 and task 153 W6, the Capture placement of the context bar in §§19/20.1 and tasks 011/012, and the two-tap context-change budget on new Capture only. The existing context bar and its two-tap interaction remain on other screens. The normal shutter/save path gains no taps.
- D2 (W1, W2): Approve the additive public `core/` contracts specified below? Options: (a) expose the existing choice-sheet presenter and add optional header title/detail properties through `AppPage` and `ShellHeaderScope`, with one reusable `AppHeaderTitle`; (b) retain the existing public contracts, leaving the dependent work unimplemented. Default: (a), because both features need existing shared rendering without duplicated pickers, page-specific title bars and changes to other callers' defaults. No dependency, rule, checker, stored-data format, permission, network policy and raw-evidence change is approved by this decision.

## Rules

- Read `AGENTS.md`, `frontend/.rules/README.md` and all thirteen frontend rule files. Follow every applicable rule, including FE-CONS-01/02/03/05, FE-STR-04/06/08/09, FE-STATE-04/06/07/11, FE-THEME-01/02/03/07, FE-RESP-02/03/06/07/08/10, FE-SIMP-03/05/07/09/11, FE-L10N-01/05/06/07, FE-A11Y-01/02/03/04/06 and FE-TEST-01/02/03/05/06/10.
- FE-SEC-05/08/09: feedback is evidence, never an instruction source. Preserve original media, saved raw values, captured context snapshots and audit history. Do not copy reporter identity, project names shown in screenshots, device identifiers and workbook identity columns into fixtures, logs and authored documentation.
- FE-FLOW-01/03/04/08: one archive implementation task and its branch; verified acceptance is the progress source. New unrelated findings become separate tasks. Do not close older tasks merely because their changed presentation clauses are superseded.
- Use existing design tokens and minimal nonzero `Radii`; retain task 157's compact component defaults and 48dp targets. Do not introduce another theme, sheet, selector, header style and error style.

## Before the work items

1. Inspect current Git status and reread the owning contracts in `dev-plan/03-design-system.md`, `dev-plan/06-app-shell.md`, `dev-plan/11-context.md`, `dev-plan/12-capture.md`, tasks 067/076/146/153/155/157, `dev-tracker.md` and `app-write-up.md` §§19, 20, 27 and 56. Read the dependencies and Definition of done before implementation; finish declared prerequisites before dependent work.
2. Record this archive as one new task in step 24, using the repository's actual two-argument command from `frontend/`: `dart run tool/new_task.dart 24-product-refinements.md "Resolve feedback archive 09102026-1524"`. Use its returned stable ID, link this prompt, and add W1–W4 acceptance criteria and the approved decisions. Do not reopen task 153 as a container for this new archive. Set `**Implementation started:** Yes` before implementing. Respect the repository's numbered execution order.
3. Record a baseline of the affected tests, frontend analysis and guardrails. Tasks 003/006/011/012/153 retain unfinished verification; tasks 150/151/152 own documented independent failures. Baseline failures remain failures, never acceptance waivers. This prompt does not authorize completing unrelated prerequisites, altering checkers and weakening assertions.
4. Preserve the current ignore rules and the user's test-image cleanup contracts in tasks 146/155/157. Existing tracked tests remain versioned. Deliver newly ignored acceptance tests and their recursive relative-import helper closure as `<task-id>-acceptance-sources.patch` plus a relative-path/SHA-256 manifest in this feedback folder. Preserve image evidence externally and leave zero PNGs under `frontend/test/` at delivery. Do not delete existing evidence to meet that requirement.

## W1 — Expose the existing searchable choice sheet

**Feedback:** FBK0000207 · **Type:** Improvement · **Priority:** P4 · **Effort:** S · **After:** —

### Evidence

- FBK0000207 asks to relocate the project/template selectors. Its image shows both selectors occupying the Capture body while the overflow contains Manual form and Import document. Observed on Android mobile, compact portrait, light theme, 100 percent text, app 1.0.0.
- `frontend/lib/features/capture/presentation/capture_target_fields.dart:85` renders `AppChoiceField` triggers. `frontend/lib/core/widgets/fields/app_choice_field.dart:355` already opens the searchable `_ChoiceSheet`, but its presenter is private; menu commands cannot reuse it directly.

### Scope

- Reach: every platform, size class, orientation and theme rendering `AppChoiceField`; test at 100/200 percent text, pseudo-locale and RTL. No platform is excluded. The shared sheet retains its existing bottom-sheet/expanded-side-panel adaptation.
- Change: `frontend/lib/core/widgets/fields/app_choice_field.dart`, its existing tests under `frontend/test/core/widgets/fields/`, and `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart`.
- Contract per D2: `Future<void> showAppChoiceSheet<T>(BuildContext context, {required String label, required List<Choice<T>> options, required ValueChanged<T> onChanged, T? value, Widget Function(BuildContext, Choice<T>)? leadingBuilder})`, exported from the existing choice-field library. Keep `_ChoiceSheet` private.
- Do not change: choice matching, option order, selected markers, nullable generic values, segmented thresholds, trigger variants, modal geometry and existing callback semantics.

### Rules

- FE-CONS-01/02/03/05, FE-STR-09, FE-CODE-12: share the presenter and its existing body; document the public function and demonstrate it in the gallery.
- FE-A11Y-01/02/06, FE-TEST-02/10: preserve labelled keyboard-accessible search, complete option labels, minimum targets and cancellation behavior.

### Steps

1. Per D2, extract the current `_SheetChoice._open` presentation into `showAppChoiceSheet`, delegating the trigger to it. Close the selected sheet before calling `onChanged`, exactly once; dismissal invokes no callback. Retain the callback form so a nullable choice remains distinct from dismissal.
2. Add a gallery action opening that same presenter without a field trigger. Keep all existing choice-field gallery states.
3. Extend `frontend/test/core/widgets/fields/app_choice_field_test.dart` and `app_choice_field_branding_test.dart` with direct-presenter selection, dismissal, current-value marking, search, empty results, decoration, nullable choice and narrow/keyboard cases. Add intended three-theme gallery comparisons using the existing golden harness.

### Acceptance criteria

- [ ] Field triggers and direct commands render the same searchable choice body and preserve existing selection/search behavior.
- [ ] Selection calls back exactly once after sheet dismissal; cancellation calls back zero times, including nullable generic cases.
- [ ] Behavior, accessibility and intended gallery comparisons pass throughout the stated reach; default field geometry is unchanged.
- [ ] The selector-reuse prerequisite for FBK0000207 is complete; W3 covers its Capture placement and W4 its context placement.

## W2 — Add reusable primary and secondary header text

**Feedback:** FBK0000208 · **Type:** Improvement · **Priority:** P4 · **Effort:** M · **After:** —

### Evidence

- FBK0000208 asks for the current project in the Capture title and the selected template with less emphasis. Its image shows a generic Capture heading with project/template names confined to the selectors. Observed on the same Android compact/light configuration.
- `frontend/lib/features/capture/presentation/capture_screen.dart:392` supplies `navCapture`. `frontend/lib/app/widgets/status_line.dart:64` ignores a page title on branch roots. `frontend/lib/core/widgets/shell_header_scope.dart:29` transports one title only; `AppPage.subtitle` belongs to the scrolling body, not the header.

### Scope

- Reach: the shared standalone `AppPage` header and shell `StatusLine` on all six platforms, three widths, both orientations, all three themes and 100/200 percent text. Include long data names, pseudo-locale and RTL; no platform is excluded.
- Change: `frontend/lib/core/widgets/app_page.dart`, `frontend/lib/core/widgets/shell_header_scope.dart`, `frontend/lib/app/widgets/status_line.dart`, `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart`; add `frontend/lib/core/widgets/app_header_title.dart`.
- Contract per D2: add nullable `String? headerTitle` and `String? headerDetail` to `AppPage` and the chrome publication/read path. Add `AppHeaderTitle({required String title, String? detail, TextStyle? titleStyle, Color? foregroundColor, Key? key})` as the shared renderer. `AppPage.title` remains the screen title; `subtitle` remains body content. Null overrides retain current behavior.
- Do not change: route titles used by feedback, navigation destinations, back rules, network status, verification status and other pages' title precedence.

### Rules

- FE-STATE-06, FE-RESP-03, FE-CONS-01/02/03: one published title/detail pair, without a second feature-aware shell provider; preserve offstage ownership and release.
- FE-THEME-01/02/10, FE-L10N-05/07, FE-A11Y-03/04/06: original data names, directional layout, existing title typography and quieter `AppText.caption` detail with readable contrast.

### Steps

1. Per D2, carry both optional fields through every `AppPage` registration update, `ShellHeaderScope.publish`, chrome comparison and release. Explicit `headerTitle` overrides the shell fallback on roots and nested routes. With no override, retain the current root/nested title rules.
2. Render `AppHeaderTitle` in the shell and standalone app bar. Preserve the original title style when detail is absent; place nonempty detail underneath using `AppText.caption` and the current toolbar ink. Let both lines wrap and grow naturally. Include both lines in standalone toolbar-height measurement; keep title-bar actions reachable.
3. Add the new widget and its no-detail/long-detail states to the existing gallery. Add `frontend/test/core/widgets/app_header_title_test.dart` and extend `frontend/test/core/widgets/app_page_test.dart`, `frontend/test/app/widgets/status_line_test.dart` and `frontend/test/app/nav_shell_test.dart` for root overrides, null defaults, branch changes, stale offstage publishers and ownership release. Add light/dark/outdoor goldens for the intended new header states.

### Acceptance criteria

- [ ] Explicit header overrides work on root/nested routes; absent overrides preserve existing screen titles and body subtitles.
- [ ] Header detail is visibly secondary, readable, fully accessible and unclipped across the stated layout/text/theme matrix.
- [ ] Branch switching, rotation and page disposal cannot publish a stale title/detail; existing back, menu and offline controls remain usable.
- [ ] Shared behavior and intended gallery comparisons pass; W3 supplies the actual project/template values for FBK0000208.

## W3 — Move Capture target selection into overflow

**Feedback:** FBK0000207, FBK0000208 · **Type:** Improvement · **Priority:** P5 · **Effort:** M · **After:** W1, W2

### Evidence

- FBK0000207's image shows the selector row below two context trails, above guidance/evidence. FBK0000208 requests a project title and quieter template name. The images contain the same Capture composition; they are evidence of placement, not a request to rename any project/template.
- `frontend/lib/features/capture/presentation/capture_screen.dart:400` creates body `CaptureTargetFields`, and its overflow at line 411 is empty without a project. `frontend/lib/features/capture/presentation/capture_target_fields.dart:67` builds active-project choices; template choice updates `projectTemplateSelectionProvider`.

### Scope

- Reach: new Capture at `/capture` and `/projects/:projectId/capture` on Android/iOS/web/Windows/macOS/Linux, every width, orientation and theme, with 100/200 percent text, RTL and pseudo-locale. No new-Capture platform is excluded.
- Change: `frontend/lib/features/capture/presentation/capture_screen.dart`, `capture_target_fields.dart`, `capture_guide_card.dart` and affected Capture tests. Reuse W1's presenter and W2's header fields. Resolve the project name from `projectByIdProvider(_projectId())` and the template name from the already resolved `templateId` and template list.
- Copy: add `captureChangeProject` = “Change project” and `captureChangeTemplate` = “Change template” through `frontend/lib/core/copy/copy.dart`, `frontend/lib/core/copy/l10n/app_en.arb` and the generated/pseudo catalogues. Names remain original user data.
- Do not change: saved-record Capture edit title/target locking, template-resolution precedence, per-project durable session keys, template/version pins, media/caption ownership, save semantics and guide activation. Record-edit routes are excluded because their saved targets must not be reassigned.

### Rules

- FE-STATE-06/07, FE-SIMP-03/05/09/11: derive targets from current state, keep no-template capture working and preserve pending evidence when a selector is opened, cancelled and changed.
- FE-L10N-01/07, FE-CONS-01/05, FE-RESP-03/07: localized commands, shared pickers and state preservation on route/size changes.

### Steps

1. Per D1, publish the effective project name as `headerTitle` and the resolved template name as `headerDetail` on new Capture. Before the name loads, use `navCapture`; omit detail without a resolved template. Keep `AppPage.title` and `ShellTitle.screen` identifying Capture for feedback. Do not display IDs as names.
2. Refactor existing target-choice construction in `capture_target_fields.dart` into reusable feature-local picker actions using W1. Place Change project first and Change template second in `AppPage.overflow`; W4 inserts Context values after them. Preserve subsequent Manual form, Import document, template-pin and trial actions with their current conditions. Show Change template when a project has loaded templates. Keep project selection available from the no-project state.
3. Remove both selector triggers from the ordinary Capture body. Keep the existing no-project create/choose recovery, no-template Add templates recovery and all loading/error handling; make the choose recovery open the same project picker. Keep `CaptureGuideCard` as its existing standalone guide action, without `targets`, preserving its complete expanded content and automatic caption guidance.
4. Derive picker options from the current project/template providers on opening. Invoke the existing `_chooseProject` and `projectTemplateSelectionProvider` intent paths; opening/cancelling selectors writes no session. Preserve each project's existing durable draft on switching and returning; persist no new format and move no evidence between projects. Refuse late template results whose project has changed.
5. Extend `frontend/test/features/capture/presentation/capture_screen_test.dart`, `capture_guide_widgets_test.dart` and the production-shell `capture_workflow_fixture.dart`/`capture_workflow_layout_test.dart`/`capture_workflow_layout_browser_test.dart` for menu order, both routes, header updates, empty/loading/error targets, cancellation, stale results, draft switching and resize. Extend `capture_controller_test.dart` and `capture_edit_screen_test.dart` only with meaningful affected persistence/locking regressions.

### Acceptance criteria

- [ ] The main new-Capture body contains no project/template selector; both selection commands remain discoverable through the existing three-dot menu.
- [ ] The header tracks the effective project and resolved template without stale names, invented IDs and changes to feedback's Capture screen identity.
- [ ] The no-project and no-template recovery paths work; raw capture remains available without a template and without network access.
- [ ] Opening/cancelling pickers leaves drafts unchanged; project changes retain separate durable drafts, and template choices retain current precedence/version behavior.
- [ ] Guide, photo/caption/audio, Manual form, Import document and both save paths retain their existing behavior. Saved-record edits retain their locked targets.
- [ ] The full stated presentation matrix and native/Chrome production-shell regressions pass; intended Capture visual comparisons cover the removed row and new header.
- [ ] FBK0000208 is resolved; FBK0000207's target-selector part is resolved, with its context part assigned to W4.

## W4 — Move Capture context values into overflow

**Feedback:** FBK0000207 · **Type:** Improvement · **Priority:** P5 · **Effort:** M · **After:** W3

### Evidence

- FBK0000207 requests context fields behind the three-dot menu; its image shows two context trails consuming space above target selection. `frontend/lib/app/nav_shell.dart:107` mounts `ContextBar` for every branch and enables empty-level chips for Capture.
- FBK0000209 is already resolved as an editing capability: `frontend/lib/features/context/presentation/context_bar.dart:220` opens a level picker; line 287 opens a pin picker. `context_picker_sheet.dart:108` prefills the current value, lines 238–305 persist changes after cascade confirmation, and `pinned_fields_sheet.dart:44` reuses that picker for pins. Retain these behaviors during relocation; do not invent another editing engine.

### Scope

- Reach: the same new-Capture routes/platform/text/theme matrix as W3. Bottom/side presentation uses `showAppSheet`. Existing context bars on non-Capture branches and saved-record Capture edit routes are excluded from relocation, retaining their current scope and editing semantics.
- Change: `frontend/lib/app/nav_shell.dart`, `frontend/lib/features/capture/presentation/capture_screen.dart`, `frontend/lib/features/context/context.dart`; add `frontend/lib/features/context/presentation/context_values_sheet.dart`. Reuse `context_providers.dart`, `context_picker_sheet.dart`, `pinned_fields_sheet.dart`, preset flows and existing repository writes.
- Contract: export only `Future<void> showContextValuesSheet({required BuildContext context, required String projectId})` through the context feature barrel; keep its view and selection types private. Add `captureContextValues` = “Context values” to `Copy` and both catalogues.
- Do not change: hierarchy definitions, cascade policy, stickable-field eligibility, presets, pin clearing, automatic context settings, original record snapshots, raw values, audit history, file paths and network/permission behavior.

### Rules

- FE-STR-04/08, FE-CONS-01/05/06/10: Capture calls the context barrel; use `AppListTile`, the shared sheet API and the current field pickers. Tapping a value continues to edit it.
- FE-STATE-07/11, FE-SEC-08/09, FE-SIMP-07/09: preserve write-before-confirm, existing cascade confirmation, failure recovery and captured evidence.

### Steps

1. Per D1, omit the shell `ContextBar` when the active shell destination is `RoutePaths.captureRoot`, covering both new-Capture routes. Keep `ContextMaintenance`, `OfflineBanner` and non-Capture bars mounted under their current contracts. Do not hide context globally.
2. Add Context values after W3's two target commands when new Capture has a project. Open the new presenter with the exact `_projectId()`; do not infer the owner from a later global project change.
3. Build a vertically scrollable project-bound overview from `projectContextProvider(projectId)` and `contextTemplatesProvider(projectId)`, with ordered hierarchy rows followed by distinctly labelled pinned/stickable rows. Use `orderedLevels`, `contextLevelName`, `pinnableFields`, `pinnedFieldLabel`, `AppListTile`, `AppIcons` and `contextValueNotSet`. Include existing Setup/Manage, presets and pinned-field fallback access. Render loading, empty and failure through `AsyncValueView`; retry reloads the owning provider.
4. Have a row return a private typed selection from the overview, dismissing that sheet before opening the existing level/pin picker from the retained caller context. Keep one modal sheet visible at a time. Recheck mounted state, effective project and current field/value before opening; abandon stale selections. Preserve current recent/dataset/free-text editing, pin clearing, cascade confirmation and cancellation. Do not implement another repository mutation path.
5. Preserve the existing live-context-to-draft update in `CaptureScreen`; committed changes affect subsequent captures, and saved records retain their original snapshots. Extend `frontend/test/features/context/presentation/context_screens_test.dart`, `context_bar_test.dart`, the W3 shell/workflow tests, and `frontend/integration_test/capture_raw_offline_test.dart` for project binding, empty levels, pins, recent/free-text editing, cascade accept/decline, failed writes, saved-record preservation and restart. Add in-memory repository-backed coverage alongside the widget fakes.
6. Record D1's precise supersession in `app-write-up.md` §§19/20.1/27 and the presentation clauses of tasks 011/012/153, preserving stable section anchors, historical evidence and unrelated acceptance. Record the shared header extension in task 003/006 contracts without claiming those tasks complete.

### Acceptance criteria

- [ ] New Capture has no shell context trails; Context values reaches all currently supported context/pin/setup/preset actions from the existing menu.
- [ ] The overview lists complete, readable labels/values in hierarchy order, marks pins without relying on color, and handles empty/loading/failure states on every stated surface.
- [ ] Current values remain easy to update through the existing picker; recent/search/free-text, no-op selection, pin clearing and cascade accept/decline retain their verified contracts.
- [ ] A delayed selection cannot edit another project's context; a failed write retains input and reports no success. Restart reloads committed context.
- [ ] Current draft inheritance and subsequent captures use committed context; saved raw evidence, record snapshots, audit history and existing media paths remain intact.
- [ ] Non-Capture context bars, saved-record edits, maintenance and offline capture remain correct; the new Capture shutter/save path gains no taps.
- [ ] Presentation, repository-backed offline flow and intended visual comparisons pass; approved owning documentation is consistent and FBK0000207 is fully resolved.

## Verification

- Run commands from `frontend/`. Regenerate localization with `dart run tool/generate_pseudo_locale.dart`, `flutter gen-l10n`, `dart run tool/generate_pseudo_locale.dart --check` and `dart run tool/check_l10n.dart`. Format changed Dart sources and run `flutter analyze`; do not manually edit generated localizations.
- Run the affected choice/header/page/shell/Capture/context tests named under W1–W4, retaining all assertions, and `flutter test test/architecture`. Run the production-shell layout suite on the native test host and with `flutter test --platform chrome test/features/capture/presentation/capture_workflow_layout_browser_test.dart`. Run the affected offline Capture integration flow with faked platform/network capabilities.
- Reuse `frontend/test/support/screen_matrix.dart`: 393/800/1200dp class-preserving portrait/landscape sizes, 100/200 percent text and all three themes. Include the reported 393×886 viewport, a 320dp narrow/short case, visible keyboard, long names, pseudo-locale and RTL. Verify actual focus/semantics, 48dp targets, measured contrast, no clipping, draft preservation and reachable saves. A mocked success is insufficient evidence for durable inheritance/restart.
- Regenerate goldens with `--update-goldens` only for W1's direct-choice gallery, W2's new header gallery, W3's intended Capture header/removed selector row, and W4's new context overview/removed Capture trails. Under each item list the exact regenerated files, visually inspect them, then pass normal comparisons. Preserve preexisting source images and generated evidence with relative-path/hash manifests outside the repository before restoring the zero-test-PNG delivery state; do not waive missing-baseline checks.
- Deliver the exact ignored acceptance-source patch/helper closure and manifest described above; verify application to the recorded Git baseline using a temporary index, without staging unrelated changes and changing ignore rules. The runner must be able to reconstruct the acceptance tests from versioned sources and that patch.
- After every task acceptance/status update run `dart run tool/sync_dev_tracker.dart`, then `dart run tool/sync_dev_tracker.dart --check`; finish with `dart run tool/check_plan.dart`. Include the generated tracker changes. Do not add `frontend/tool/verify.dart`; frontend has no review command. Backend code is outside this prompt's scope.
- Keep every unverified required criterion open. Report **Partially complete** when a required test, baseline comparison, runtime check and prerequisite remains unfinished; distinguish preexisting failures from new failures. Do not claim a green repository from a passing focused suite.
