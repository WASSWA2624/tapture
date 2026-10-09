# 001 — Resolve Capture guidance feedback

**Feedback:** FBK0000210, FBK0000211, FBK0000212 · **Work items:** 3 · **Depends on:** none

## Goal

Capture retains the chosen context without an automatic movement confirmation. Photo guidance appears above the photo tray, and caption guidance appears once immediately above the caption input, using the resolved template's complete eligible field lists. The result applies to global Capture, project Capture and saved-record Capture editing on Android, iOS, Windows, macOS, Linux and web, across compact, medium and expanded layouts and all three themes.

## Run order

| Item | Title | Feedback | Type | Priority | Effort | After |
| --- | --- | --- | --- | --- | --- | --- |
| W1 | Retire automatic context confirmation | FBK0000212 | Improvement | P2 — Capture interruption | M | — |
| W2 | Show each Capture hint once | FBK0000210, FBK0000211 | Defect | P3 — Duplicate guidance | M | W1 |
| W3 | Retain complete template guidance | FBK0000210 | Gap | P5 — Guidance coverage | S | W2 |

## Decisions

⛔ Stop here. Get an answer to every decision before step 1 of any work item. “Proceed” means the defaults. These are implementation decisions; generating this prompt does not approve them.

- **D1 (W1): Retire movement confirmation throughout the shared shell?** Options: (a) remove the movement dialog, its location polling and its Settings controls everywhere, retaining stored movement keys and values as inert compatibility data; (b) suppress the dialog only while Capture is visible and retain the feature elsewhere. **Default: (a)**, because the report asks to remove this dialog and its host is shared. This approves removing the obsolete movement domain file and its dedicated unit test, supersedes only the movement portion of specification §20.5/task 011, and preserves idle auto-clear, manual context editing and Capture's separate opt-in GPS capture.
- **D2 (W2): Keep guidance visible without another control?** Options: (a) show non-dismissible photo and caption hints continuously in their respective locations, removing the “What to capture” action, its expansion state and the caption-guide close control; (b) show photo guidance continuously but retain the caption panel's focus/recording visibility and close behavior. **Default: (a)**, because required guidance stays visible without extra taps and has one owner per location. This approves deleting the obsolete feature-local guide-state file and supersedes task 070's D14 and tasks 153/158 only for guide presentation. Existing shared `core/` APIs retain their signatures.
- **D3 (W3): Resolve completeness versus the six-field limit?** Options: (a) remove the limit from both existing eligible lists, retaining every identity/barcode photo label and every eligible required/recommended caption label as wrapping text; (b) retain the six-field limit and explicitly accept that later fields are omitted. **Default: (a)**, because FBK0000210 requests all required and important guidance. “Important” means the existing identity/barcode and recommended-field selection; this does not introduce AI ranking, new requiredness rules or template edits. Concision comes from short headings and one label list, rather than omitted fields.
- **D4 (Before the work items): Allow this bounded archive task to run before unfinished earlier plan acceptance?** Options: (a) authorize an execution-order exception for W1–W3, reusing implemented foundations while leaving their unfinished acceptance open; (b) wait for the earlier prerequisite tasks to close in normal plan order. **Default: (a)**, because these changes can reuse the current implementation independently. This does not waive a failing required check, move final hardening ahead of features, authorize unrelated fixes or certify tasks 003/006/011/012/153/158/159–162 complete. It also authorizes removal of this run's exact temporary test-image paths only after their bytes and relative-path/hash manifests have been preserved and independently verified externally.

## Rules

- Follow repository `AGENTS.md` and every file listed in `frontend/.rules/README.md`; the identifiers below emphasize the affected contracts.
- FE-CONS-01, FE-CONS-02, FE-STR-04, FE-STR-08, FE-STR-09: inspect `core/widgets/` first, reuse the existing feature components and barrels, and keep guidance derivation in its owning template domain.
- FE-STATE-04, FE-STATE-06, FE-STATE-07, FE-SEC-08, FE-SEC-09: derive guidance from one resolved shape, persist before confirming, and preserve raw evidence, record snapshots and audit behavior.
- FE-THEME-01–03, FE-RESP-01–10, FE-A11Y-01–10: use tokens, natural wrapping, measured contrast and accessible targets. Reuse the smallest existing `Radii` token wherever a surface needs a radius; never use zero.
- FE-L10N-01–07, FE-L10N-10: localize headings and Settings summaries through `Copy`; template labels remain unmodified user data and locale changes retain input.
- FE-SIMP-03, FE-SIMP-05, FE-SIMP-07–09, FE-SIMP-12: add no Capture taps, replacement confirmation, new setting, blocking validation or input-loss path.
- FE-STR-11, FE-SEC-03–08: retain platform wrappers, absolute offline mode, current consent boundaries and append-only evidence; remove only movement-specific location work.
- FE-TEST-01–10, FE-FLOW-03, FE-FLOW-04, FE-FLOW-07, FE-FLOW-08: deliver meaningful tests with the implementation, preserve guardrails, keep unrelated findings in their own tasks, and report unfinished verification as Partially complete.

## Before the work items

1. Work from the current tree. Preparation inspected `main` at `1bf79f80` on 2026-10-09. Record `git status`, the baseline commit and current plan/checklist state; preserve existing user edits and staged selections.
2. Apply the recorded Decisions. The detailed steps below implement defaults D1(a)–D4(a); a nondefault answer requires revising the affected steps and acceptance before code work begins.
3. Read owning task contracts and acceptance in `dev-plan/01-orchestration.md`, `02-foundation.md`, `03-design-system.md`, `06-app-shell.md`, `07-account-and-settings.md`, `09-templates.md`, `11-context.md`, `12-capture.md`, and tasks 070/125/143/144/146/153/158 in `dev-plan/24-product-refinements.md`. Read final hardening tasks 159–162 for existing failure ownership.
4. From `frontend/`, create one scoped task with `dart run tool/new_task.dart 24-product-refinements "Resolve feedback archive 09102026-2007"`. Use the generated stable ID, add completed prerequisites 001 and 002, copy the W1–W3 acceptance and Verification obligations into its Definition of done, link this prompt and record the approved Decisions/execution-order exception. Set `**Implementation started:** Yes` before application edits. Do not renumber earlier tasks.
5. Establish the affected baseline with the suites listed under Verification. Task 158 records Chrome bootstrap failures and tasks 159–161 own separate hierarchy, branded-choice and protected-field failures. Restore hash-verified image inputs temporarily from the task 146/157/158 external archives before image comparisons. Preserve actual results; an absent baseline image and an unstarted browser suite are failures to verify.
6. Inspect the existing design-system catalogue, `ScreenMatrix`, accessibility matchers and test factories. Use a single template-shape resolution path already present in `CaptureScreen.build`; saved-record edits use their captured template version. Application, test and plan edits begin only during this implementation run, after the Decisions.

## W1 — Retire automatic context confirmation

**Feedback:** FBK0000212 · **Type:** Improvement · **Priority:** P2 · **Effort:** M · **After:** —

### Evidence

- FBK0000212 requests removal of the context-confirmation dialog. `prompts/TAPTURE-09102026-2007/screenshots/FBK0000212.png` shows the movement question covering project Capture and interrupting caption/photo work. Seen on Android mobile, compact portrait, light, English, text scale 1, app 1.0.0, production, online; viewport 393×886 logical pixels at 2.75 density.
- `frontend/lib/app/nav_shell.dart:82` mounts `ContextMaintenance` around shell content. `frontend/lib/features/context/presentation/context_maintenance.dart:108` schedules checks from both settings; `_tick` invokes `_movement`, which checks permission, reads location and calls `showAppConfirm` at line 299. This is a shell-wide feature, rather than a Capture-specific save guard.
- `frontend/lib/features/settings/presentation/capture_settings_screen.dart:202` includes movement in the context summary; lines 257–297 expose its switch and distance picker. `frontend/lib/features/settings/domain/setting_keys.dart:62` retains persisted opt-in and distance keys. Specification §20.5 and task 011 still require the old feature.

### Scope

- Reach: all shell destinations on Android, iOS, Windows, macOS, Linux and web; compact/medium/expanded, portrait/landscape, light/dark/outdoor, text 1×/2×, English/pseudo-locale and RTL. No rendered shell surface is excluded. Platforms lacking location still follow the same no-dialog outcome without a location implementation change.
- Change: `context_maintenance.dart`, `features/context/domain/context_movement_prompt.dart`, `features/settings/presentation/capture_settings_screen.dart`, comments on the two movement keys in `features/settings/domain/setting_keys.dart`, localized Settings-summary copy, owning tests and documentation. Keep the `ContextMaintenance` host and its public constructor intact.
- Do not change: idle auto-clear and undo, current context values/pins, manual picker/cascade/preset confirmations, GPS privacy defaults and capture stamping, capture/review writes, permissions manifests, stored setting values, schema, routes, backend and network policy.

### Rules

- FE-STR-11, FE-STATE-07, FE-SEC-04, FE-SEC-07–09: remove the movement caller without touching other location consumers, consent boundaries or persisted evidence.
- FE-SIMP-03, FE-SIMP-05, FE-SIMP-07, FE-SIMP-12: remove the interruption and its obsolete controls without replacement UI.
- FE-L10N-01–03, FE-TEST-01–06: update localized presentation and its behavioral coverage together; keep guardrails unchanged.

### Steps

1. Per D1, remove `_movement`, its invocation, `_moving`, `_origin` and the movement-specific imports from `ContextMaintenance`; schedule its timer only for enabled idle auto-clear. Preserve activity detection, project/context subscriptions, disposal and auto-clear's concurrent-write behavior.
2. Delete the obsolete `frontend/lib/features/context/domain/context_movement_prompt.dart` and its dedicated `frontend/test/features/context/domain/context_movement_prompt_test.dart`. Replace the maintenance test that expects a dialog with retirement regressions using the existing fake clock, permission and location services.
3. Remove the movement switch, distance selector and movement fields from `_CaptureView` and its snapshot/default construction in `capture_settings_screen.dart`. Keep `SettingKeys.contextMovementPromptEnabled`, `contextMovementMetres` and their existing persistence registration unchanged; document them as retired compatibility keys. Do not rewrite existing values.
4. Add `settingsContextRetentionSummary(String interval)` through the existing localized copy/catalogue pipeline, with English text `Clear after: {interval}` and placeholder metadata. Render only the auto-clear summary. Retain existing `Copy` method signatures and historical message keys so this does not become a public cross-feature API refactor.
5. Extend `context_maintenance_test.dart` and `capture_settings_screen_test.dart`: legacy movement=true with GPS allowed causes zero maintenance location/permission calls and no dialog, even after multiple ticks, navigation, resume and project changes; movement=false and GPS-denied states have the same result. Assert raw legacy preferences remain unchanged after other Settings writes and reopening.
6. Retain and run idle auto-clear/undo/failure coverage and Capture's separate enabled/disabled GPS tests. Update specification §20.5 and task 011 with a bounded dated supersession; retain historical evidence and the unrelated open criteria.

### Acceptance criteria

- [ ] No shell destination opens the movement question, including Capture with typed captions and photos, repeated ticks and previously enabled movement settings.
- [ ] Context maintenance performs zero movement-specific permission checks and location reads, opens zero movement dialogs, and makes zero automatic context changes; the capture GPS path retains its existing consent and data behavior.
- [ ] The movement switch, distance choice and movement summary are absent from Capture Settings; auto-clear, idle duration, durable preferences and its undo behavior remain functional.
- [ ] Stored movement keys/values survive unchanged; existing context, pins, record snapshots, raw media/captions and audit rows remain unchanged by retirement.
- [ ] Unit, maintenance/Settings widget, real-shell navigation and repository-backed offline regressions pass across the stated reach, including the layout/text/theme matrix for changed Settings presentation.
- [ ] Specification §20.5 and task 011 describe the approved bounded retirement, and FBK0000212 is resolved without closing unrelated acceptance.

## W2 — Show each Capture hint once

**Feedback:** FBK0000210, FBK0000211 · **Type:** Defect · **Priority:** P3 · **Effort:** M · **After:** W1

### Evidence

- FBK0000210 asks to remove “What to capture” while retaining concise photo/caption hints from the active template. `prompts/TAPTURE-09102026-2007/screenshots/FBK0000210.png` shows the action above both expanded hint lists on global Capture.
- FBK0000211 asks for caption hints only above the input. `prompts/TAPTURE-09102026-2007/screenshots/FBK0000211.png` shows the same caption-label list in the expanded guide and again immediately above the caption field on project Capture. Both reports have W1's Android/viewport/theme/text/version/environment/connectivity metadata.
- `frontend/lib/features/capture/presentation/capture_guide_card.dart:31` reads expansion state and renders the button plus both lists. `capture_screen.dart:550` mounts it before the tray; lines 671–684 also pass caption fields into `RecordCaptionField` with per-template dismissal state.
- `frontend/lib/features/capture/presentation/record_caption_field.dart:140` separately renders `_CaptionGuidePanel` during typing/dictation/recording. `capture_guide_state.dart` owns expansion and dismissal, so two independent presentation paths repeat one derived list.

### Scope

- Reach: `/capture`, `/projects/:projectId/capture` and saved-record Capture editing on Android/iOS/Windows/macOS/Linux/web. Cover compact/medium/expanded, both orientations, light/dark/outdoor, 100%/200% text, English/pseudo-locale/RTL, keyboard open, touch, pointer and keyboard traversal. No Capture renderer is excluded; camera hardware is unnecessary for guidance tests.
- Change: the existing `CaptureGuideCard`, `RecordCaptionField`, `CaptureScreen.build/_evidence`, `capture_guide_state.dart`, their feature-local callers/tests and guidance copy keys. After W1 the shell no longer presents movement confirmation; all other shell/context behavior remains intact.
- Do not change: resolved template selection/version rules, header/feedback identity, overflow setup and Manual form, picker behavior, durable drafts, caption writes, dictation, audio/live transcription, photo selection/application/removal, source policies, storage guards and saved-record locking.

### Rules

- FE-CONS-01, FE-STATE-04, FE-STATE-06: render the existing derived guide once per destination; extend the existing components without a second hint implementation.
- FE-THEME-01–03, FE-RESP-04/06–10, FE-A11Y-01–10, FE-L10N-01–07: concise localized headings, complete user labels, natural height, directional spacing and reachable actions.
- FE-SIMP-03, FE-SIMP-09, FE-SEC-08, FE-TEST-01–05: no extra taps, focus theft, lost input or raw-evidence writes caused by guidance.

### Steps

1. Per D2, reuse `CaptureGuideCard` as photo guidance only: remove its expansion action and caption-list branch, keep its existing constructor/optional `targets` compatibility, and render the photo heading/list directly before `PhotoTray`. An empty photo list contributes no guide spacing. Keep the existing responsive composition for supplied targets.
2. Render `RecordCaptionField`'s existing hint panel once, immediately above its input whenever the passed caption list is nonempty. Remove its close action and focus/recording-only visibility machinery. Keep `_focused`, text-controller/reset-key reconciliation, persist-on-keystroke/lifecycle behavior and failure callbacks that protect user input. Remove only obsolete feature-local guide recorder/live-status arguments and listeners; leave audio and transcription controls wired through their existing services.
3. Remove the guide toggle and closed-for-template state from `CaptureScreen` and delete the now-unused `frontend/lib/features/capture/presentation/capture_guide_state.dart`. Continue passing one `CaptureGuide` derived from the effective shape; preserve captured-version guidance for edits and keep existing unknown-shape/no-template recovery behavior.
4. Use `captureGuidePhotos` = `Show in photos` and `captureGuideCaption` = `Include in caption` in all locale catalogues; reuse `captureGuideItems` and template labels unchanged. The caption panel includes its localized heading and a single wrapping label list. Keep obsolete message keys compatible, but render no “What to capture” action and no hide-guide control.
5. Update `capture_guide_widgets_test.dart`, `capture_screen_test.dart`, `capture_workflow_fixture.dart` and both native/browser workflow roots. Assert one photo hint above the tray and one caption hint above the field before focus, while typing/dictating/recording, after stopping and after keyboard dismissal. Assert absence of the former toggle and upper caption copy in both widget and semantics trees.
6. Cover no project, missing/empty/loading/failed template lists, photo-only/caption-only/empty guides, long labels, template/version/project switches, stale selections, caption-write failure/retry, draft recovery and locked saved-record edits. Verify photo/dictation/audio/manual/import/save actions remain usable with no new taps.
7. Update specification §27 and the guide-only presentation notes in tasks 070/153/158. Regenerate and visually inspect only the intended Capture outputs listed in Verification; preserve their originals and new bytes externally per D4.

### Acceptance criteria

- [ ] The “What to capture” button, expandable guide state and caption-guide close control are absent from every Capture variant.
- [ ] Nonempty photo hints appear once immediately above the tray; nonempty caption hints appear once immediately above the caption input and nowhere else, including the accessibility tree.
- [ ] Focus, dictation, ordinary audio, live transcription, stopping and keyboard dismissal preserve the same single visible caption-guidance location.
- [ ] Effective-template changes update both hints; saved-record edits use their captured shape; missing/unknown/empty shapes show no stale labels and leave raw Capture usable.
- [ ] Long labels wrap completely across the stated layout/text/theme/locale matrix; remaining controls meet target/contrast/focus checks and preserve input during rotation/window resizing.
- [ ] Caption/media durability, cancellation, failure recovery, saved-record locking and the existing Capture tap budget pass behavioral, offline and real-shell native/Chrome checks.
- [ ] Reviewed intended comparisons pass; documentation agrees. FBK0000211 is resolved, and FBK0000210's action/placement requirements are resolved with completeness assigned to W3.

## W3 — Retain complete template guidance

**Feedback:** FBK0000210 · **Type:** Gap · **Priority:** P5 · **Effort:** S · **After:** W2

### Evidence

- FBK0000210 says the hints should cover all required fields and important information from the current template. The screenshot establishes the guidance surface; it does not prove a particular field was missing.
- `frontend/lib/features/templates/domain/capture_guide.dart:23` derives ordered photo and caption labels from the template. Lines 56/59 truncate each list with `.take(cap)`; `frontend/lib/core/constants/app_constants.dart:918` sets `guideMaxFields` to six. Any eligible seventh field is therefore omitted independently of requiredness. `frontend/test/features/templates/domain/capture_guide_test.dart` currently asserts that limit.

### Scope

- Reach: the shared pure-Dart derivation and every W2 Capture hint renderer on Android/iOS/Windows/macOS/Linux/web, compact/medium/expanded, portrait/landscape, light/dark/outdoor, 1×/2× text, English/pseudo-locale/RTL. No guidance consumer is excluded.
- Change: `CaptureGuide.of`, its documentation, the obsolete `AppConstants.capture.guideMaxFields` member and `capture_guide_test.dart`; use W2's wrapping hint locations. Keep `deviceReadingFreshness` intact in the same constants record.
- Do not change: template serialization, versions, field requiredness, conditional-requiredness evaluation, input/source policy, inherited groups, automatic/context/stickable/file/signature exclusions, hidden-field handling, AI extraction, capture validation and the raw-save contract.

### Rules

- FE-STR-05, FE-STATE-06, FE-L10N-07: keep one pure derivation from the resolved template, with labels treated as data.
- FE-CODE-04/09, FE-RESP-06, FE-A11Y-03: preserve immutable results and complete wrapping instead of another magic limit.
- FE-SIMP-08, FE-SEC-08, FE-TEST-01/02/04: guidance is advisory; verify coverage through pure tests without manufacturing required-field blocking.

### Steps

1. Per D3, remove both `.take(cap)` operations and the unused limit. Preserve photo field order and selection (`identity`, `identityFieldKeys`, barcode), then caption required-before-recommended ordering with all existing eligibility exclusions and label fallback behavior. Do not change the public `CaptureGuide` constructor/fields.
2. Replace the cap test with tests exceeding six eligible required fields, six recommended fields and six photo fields. Assert exact membership/order, a late required field before recommended labels, unchanged excluded fields, template-specific labels, empty cases and nonmutation of the input template. Treat distinct fields with identical labels as distinct fields.
3. Exercise the complete derived lists in W2's widget/real-shell tests with long labels and more than six entries. Assert each selected field is represented in its designated hint, remains accessible by scrolling and causes no hard clipping/ellipsis. Keep expanders, summary counts, extra screens, new settings and provider calls out of this change.
4. Switch active templates/projects and reopen a captured-version edit to prove the expanded lists follow the same resolved shapes as W2, preserving both session contents and saved evidence. Update the current guidance contract beside the W2 presentation supersession and record the approved meaning of “important.”

### Acceptance criteria

- [ ] Every eligible photo identity/barcode label and every eligible required/recommended caption label is retained beyond six entries, in the existing deterministic order.
- [ ] Existing exclusions and raw label/fallback semantics remain intact; templates, field rules, source policies and file formats remain unchanged.
- [ ] W2's single hint locations display the complete lists across their full reach, with accessible scrolling and unchanged Capture actions.
- [ ] Pure derivation, widget, captured-version, template-switch and offline regressions pass; missing required data remains advisory and does not block raw saving.
- [ ] The current guidance contract documents the uncapped eligible lists, and FBK0000210's completeness requirement is resolved.

## Verification

- All commands below run from `frontend/`. There is no `frontend/tool/verify.dart`; do not create one. The generated task closes only after every required check passes on the final sources; preserved baseline failures do not count as passes.
- Run `dart run tool/generate_pseudo_locale.dart`, `flutter gen-l10n`, `dart run tool/generate_copy_messages.dart`, `dart run tool/generate_copy_messages.dart --check` and `dart run tool/check_l10n.dart` before the locale matrix. Format changed non-generated Dart files and run `flutter analyze`.
- Run the owning behavior/domain suites: `test/features/context/presentation/context_maintenance_test.dart`, `test/features/context/domain/context_auto_clear_test.dart`, `test/features/settings/presentation/capture_settings_screen_test.dart`, `test/features/templates/domain/capture_guide_test.dart`, `test/features/capture/presentation/capture_guide_widgets_test.dart`, `test/features/capture/presentation/capture_screen_test.dart`, `test/features/capture/presentation/capture_controller_test.dart`, `test/features/context/presentation/context_bar_test.dart`, `test/app/nav_shell_test.dart` and `test/app/widgets/status_line_test.dart`. Use `flutter test` with these exact roots. The deleted movement evaluator suite is replaced by W1's no-poll/no-dialog coverage, rather than skipped as a live feature test.
- Run `flutter test test/hardening/capture_raw_offline_host_test.dart` for the existing real-database offline flows. Extend their existing fixtures to verify unchanged raw captions/photos/audit rows/snapshots, committed-context reload, no movement interruption and zero outbound/AI calls; retain first-save and draft ownership assertions.
- Run `flutter test test/features/capture/presentation/capture_workflow_layout_test.dart` and `flutter test --platform chrome test/features/capture/presentation/capture_workflow_layout_browser_test.dart` with the production fixture. Use `ScreenMatrix.cells` for all three widths, both orientations, both text scales and all themes; retain pseudo-locale, RTL, keyboard, traversal and per-platform behavior. Confirm the reported 393×886 portrait case and short landscape with the keyboard open. Exercise Android capture/save/rotation and Chrome pointer/keyboard/window-resize smoke flows with fakes for unavailable hardware.
- **Existing blockers:** task 162 owns the Windows Chrome renderer/module-init failure, task 159 the hierarchy drag failure, task 160 archived branded-choice comparisons and task 161 the protected-field override regression. Record current reproductions against the unchanged baseline. Keep unrelated repairs in those tasks, preserve all real-shell assertions, and leave this task Partially complete while a required affected run cannot pass. Do not replace production bootstrap with a simpler app to obtain a green result.
- **Intended image changes, W1:** update only Capture Settings images from `capture_settings_screen_test.dart` showing the removed movement controls/summary. Enumerate the exact existing relative paths before regeneration in the task's evidence.
- **Intended image changes, W2/W3:** the twelve existing `frontend/test/features/capture/presentation/goldens/capture_composition_{compact,compact_landscape_text2,medium,expanded_text2}_{light,dark,outdoor}.png` outputs, plus existing `capture_workflow_*.png` outputs that render the affected Capture guidance. Expand these families to an explicit path list under W2 evidence before running `--update-goldens`. Add corresponding guidance corners to the existing guide widget suite. Do not regenerate unrelated component/context/record baselines.
- Compare against verified restored originals first. Use `--update-goldens` only for the declared intended changes, visually review every changed output, then run normal comparisons. Preserve original/generated/failure images externally under `%LOCALAPPDATA%/TaptureTestArchives/` with relative paths, byte lengths and SHA-256 hashes. Independently reopen and verify the archive before removing only this run's exact temporary test PNG paths per D4; deliver zero PNGs under `frontend/test/`. Never delete an unowned image or raw feedback screenshot.
- Run the affected architecture suites for layering, state, tokens, icons, network, raw-data safety, localization and accessibility from `frontend/test/architecture/` without skipping or weakening assertions. Do not change rules/checkers in this archive task.
- Ignored tests still ship: provide `<generated-task-id>-acceptance-sources.patch` and a relative-path/SHA-256 JSON manifest in `prompts/feedback-09102026-2007/`, containing the exact acceptance roots above and their recursive local-import helper closure, plus recorded removals. Verify patch reconstruction against the recorded Git baseline in a temporary index, independent of the real index; verify every reconstructed source hash. Keep ignore rules unchanged and do not stage user edits automatically.
- Tick only acceptance supported by final-source results; preserve dated historical evidence and all unrelated open boxes. Run `dart run tool/sync_dev_tracker.dart`, `dart run tool/sync_dev_tracker.dart --check` and `dart run tool/check_plan.dart` after the implementation/progress update. Include the generated tracker with the implementation and report Partially complete whenever required work remains.
