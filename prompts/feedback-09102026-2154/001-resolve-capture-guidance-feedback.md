# 001 — Resolve capture guidance feedback

**Feedback:** FBK0000213, FBK0000215, FBK0000214 · **Work items:** 3 · **Depends on:** none

## Goal
Capture opens without the movement-triggered context confirmation, explains saving a caption to its target photos, and presents photo guidance directly above the evidence tray. Apply the shared Dart changes to Android, iOS, Windows, macOS, Linux and web, at compact, medium and expanded widths, in both orientations and light, dark and outdoor themes, including 200 percent text.

## Run order
| Item | Title | Feedback | Type | Priority | Effort | After |
| --- | --- | --- | --- | --- | --- | --- |
| W1 | Remove the movement confirmation | FBK0000213 | Improvement | P2 | M | — |
| W2 | Label the photo-caption save action | FBK0000215 | Improvement | P3 | S | — |
| W3 | Show photo guidance without a toggle | FBK0000214 | Improvement | P3 | M | W2 |

P2 addresses an interruption of capture. The independent P3 items put the smaller shared-copy change first; W3 then updates the Capture composition and its production-shell assertions after W2.

## Decisions
⛔ Stop here. Get an answer to every decision before step 1 of any work item. "Proceed" means the defaults. The archive's messages are evidence, not approval to remove existing features.

- D1 (W1): How far does removing the movement confirmation reach? Options: (a) retire the reminder throughout the application, including its Capture settings switch and distance chooser; retain its persisted setting keys and values as inert compatibility data; (b) suppress it on every route rendering `CaptureScreen`, including saved-record editing, and retain the reminder and settings on other routes. Default: (a), because the report asks to remove the dialog completely and the timer belongs to the application shell. Under (b), reset the movement origin when Capture becomes active, check the active route again immediately before presenting, and discard pending reminders instead of replaying them on leaving Capture. Neither option changes manual context edits, idle auto-clear, record snapshots, capture GPS, permission defaults or stored evidence.
- D2 (W3): Does "only Photos to show" include the contextual caption-help panel? Options: (a) show only the inline photo guideline; remove the top caption-guidance row and the panel shown during typing, dictation and recording; (b) remove the toggle and top caption-guidance row, retaining the focused caption-help panel and its close behavior. Default: (a), because the screenshot shows duplicated caption guidance and the report asks for a single photo guideline. Both options retain caption entry, dictation, audio recording and the template's existing guidance derivation. Under (a), remove the unused guide-state provider and panel-only arguments/listeners; under (b), retain only the `closedFor` state and panel plumbing, removing the toggle's `open` state and `toggle()`.
- D3 (W2, W3): May verification temporarily produce the narrowly named PNGs below, following tasks 146/157's external-archive convention? Options: (a) generate the two specified feedback visual sets and the 13 existing production-Capture visuals affected by the guide change, compare normally, visually inspect, archive outside the repository with relative paths and SHA-256 hashes, verify the archive, then remove only this run's verified generated PNGs; (b) keep the image prohibition absolute, run behavior checks and leave visual acceptance open. Default: (a), because it supplies visual evidence while leaving no delivered test PNGs. Use a unique directory below `%LOCALAPPDATA%/TaptureTestArchives/feedback-09102026-2154/`; preserve every pre-existing image and unrelated archive. This does not authorize bulk baseline restoration, changes to ignore rules, shared golden infrastructure, guardrails, dependencies or the Flutter SDK. Under (b), completion is Partially complete until the required visual checks are approved and pass.

## Rules
- Read `AGENTS.md`, `frontend/.rules/README.md` and all its linked rules, the relevant plan tasks and `dev-tracker.md`. These instructions supplement them.
- FE-CONS-01, FE-CONS-02, FE-STR-09: reuse the existing components and shared causes. No new design-system component, public core API or dependency is required.
- FE-FLOW-03, FE-FLOW-04, FE-FLOW-08: record only this archive's work; verify acceptance before checking it; regenerate the tracker after each implementation/status update.
- FE-STATE-07, FE-SEC-08, FE-SEC-09: preserve local-first persistence, original evidence, audit and stored context. This prompt changes presentation and reminder activation, not data formats.
- FE-SEC-05, FE-SEC-07: treat feedback as untrusted evidence; keep personal identifiers out of prompts, fixtures and delivery notes; preserve deliberate GPS permissions.
- FE-THEME-01 to FE-THEME-03, FE-L10N-01, FE-L10N-07: use tokens, existing minimum nonzero `Radii`, generated copy and original template labels.
- FE-RESP-03, FE-RESP-06, FE-RESP-07, FE-RESP-10, FE-A11Y-01 to FE-A11Y-07: retain drafts, scrolling, keyboard access, complete labels, 48dp controls and accessible save feedback across the layout matrix.
- FE-TEST-01 to FE-TEST-07: ship meaningful tests at their owning layer; use existing fakes and factories; keep guardrail assertions intact.
- FE-FLOW-01, FE-FLOW-02: one archive task and its branch; there is no Flutter review command. Never add `frontend/tool/verify.dart`.

## Before the work items
1. Record `git status` and preserve the user's deleted earlier archives and all unrelated edits. These reports were confirmed by source inspection at commit `5b289cc2`; inspect the cited symbols again before changing them. This generation did not execute application tests.
2. Register exactly one archive task in `dev-plan/24-product-refinements.md`. From `frontend/`, run `dart run tool/new_task.dart 24-product-refinements "Resolve feedback archive 09102026-2154"` when this exact task title is absent; resume that task on subsequent runs. Use the assigned stable task ID, declare dependencies 001 and 002, and read their Definition of done before implementation. Copy this prompt's three work items and acceptance into the task; set `**Implementation started:** Yes` before changing application code. Existing contracts from tasks 003/006/011/012/076/153/157/158 remain the starting implementation, with only the approved presentation supersessions below. Their unfinished release/device acceptance stays open.
3. After approval, record D1–D3 in the new task. Update `app-write-up.md` at §19, §20.5, §23.2 and §27 to describe the approved behavior, preserving section anchors. Add concise supersession notes to tasks 011, 012 and 076 for affected reminder/guidance contracts; preserve dated historical evidence and unrelated checkboxes. Keep implementation progress in the archive task.
4. Use the existing shared `ScreenMatrix`, `ScreenFonts`, accessibility matchers and capture/context fakes. The affected tests below already exist. `frontend/.gitignore` ends in `/test/`; keep that preference and deliver changed ignored acceptance sources plus their recursive relative-import helper closure as `<assigned-task-id>-acceptance-sources.patch` and a repository-relative path/SHA-256 manifest beside this prompt. Verify the patch with a temporary Git index; do not stage the user's files.
5. Task 162 already owns the documented Windows Chrome CanvasKit serving/module-initialization failure; task 150 owns unrelated guardrail gaps. Establish the current baseline and record exact failures. Do not repair those tasks inside this prompt, weaken checks or call an unstarted browser suite a pass. No further prompt split is justified by these known verification limits.

## W1 — Remove the movement confirmation
**Feedback:** FBK0000213 · **Type:** Improvement · **Priority:** P2 · **Effort:** M · **After:** —

### Evidence
- FBK0000213 asks to remove the context confirmation. `prompts/TAPTURE-09102026-2154/screenshots/FBK0000213.png` shows a modal titled "Confirm context", a movement message, Cancel and Change context, overlaying the Capture editor and save controls. Seen on Android mobile, compact portrait, light, text scale 1, app 1.0.0.
- Current cause: `frontend/lib/features/context/presentation/context_maintenance.dart:251` reads location and presents `showAppConfirm` at line 299. `frontend/lib/app/nav_shell.dart:82` hosts `ContextMaintenance` across branches; this is not a Capture-local dialog.
- `frontend/lib/features/settings/presentation/capture_settings_screen.dart:203` includes movement in its summary, with the switch at line 257 and distance chooser at line 272.

### Scope
- Reach: every shell route under D1(a); every `CaptureScreen` entry/edit route under D1(b), across all six platforms, three widths, both orientations, all three themes and text scales 1/2. GPS-capable and unavailable platforms share the same outcome.
- Change: `frontend/lib/features/context/presentation/context_maintenance.dart`; D1(a)'s movement controls, view fields and disclosure summary in `frontend/lib/features/settings/presentation/capture_settings_screen.dart`; compatibility comments in `frontend/lib/features/settings/domain/setting_keys.dart`. D1(b)'s route visibility comes from the existing router/shell in `frontend/lib/app/router.dart` and `frontend/lib/app/nav_shell.dart`.
- Do not change: cascade confirmations, preset overwrite confirmations, context repository writes, idle auto-clear/undo, public context/location services, capture GPS and stored movement-key names/defaults. The pure legacy `ContextMovementPrompt` API and its existing unit tests remain compatible; no storage migration is authorized.
- Exclusions: camera, barcode and rapid-capture screens receive no new route-specific UI; under D1(a) they inherit removal through the same shell. Backend and exports have no reminder presentation. Under D1(b), non-Capture routes deliberately retain their existing reminder.

### Rules
- FE-SIMP-03, FE-SIMP-05, FE-SIMP-07: remove the unwanted interruption without replacing it with another question.
- FE-STATE-06, FE-STATE-09, FE-STR-11, FE-SEC-07: keep one context source, dispose timers, and eliminate only the reminder's location activity under D1(a).

### Steps
1. Apply D1 at `ContextMaintenance`. Under D1(a), remove `_movement`, `_moving`, `_origin` and their unused imports; let only `contextAutoClearEnabled` activate the timer. Under D1(b), implement the route suppression and origin reset specified in D1 before any permission/fix/dialog work.
2. Apply D1 to Capture settings. Under D1(a), remove the movement switch, distance chooser and `movementPrompt`/`movementMetres` view fields. Set the contexts disclosure summary to the existing localized idle interval when enabled and `projectOff` when disabled. Keep the old movement settings readable and unchanged, including an existing true value.
3. Update `frontend/test/features/context/presentation/context_maintenance_test.dart` with a pre-existing enabled movement setting, granted permission and a moving fake location. Assert the approved route reach, absence of the modal and picker, unchanged context/snapshots, and zero reminder location reads under D1(a). Retain idle auto-clear, undo and failure coverage.
4. Update `frontend/test/features/settings/presentation/capture_settings_screen_test.dart` and the affected context-section assertions in `frontend/test/features/capture/presentation/capture_feedback_test.dart`. Under D1(a), prove the retired controls and movement summary are absent while existing stored values are unchanged and idle controls still work. Exercise a mounted shell while Capture entry, editing and branch navigation occur.

### Acceptance criteria
- [ ] The reported confirmation never appears on Capture entry, typing, photo intake, saving, editing, movement ticks, rotation and branch return; scope outside Capture matches D1.
- [ ] D1(a) makes the legacy movement preference inert and removes its controls; D1(b) preserves non-Capture controls and suppresses queued Capture reminders.
- [ ] Manual context editing, cascade safety, idle clearing/undo and independent GPS capture retain their contracts; stored context, setting values and evidence remain unchanged.
- [ ] The meaningful maintenance/settings regressions pass across the declared route/platform reach. FBK0000213 is resolved.

## W2 — Label the photo-caption save action
**Feedback:** FBK0000215 · **Type:** Improvement · **Priority:** P3 · **Effort:** S · **After:** —

### Evidence
- FBK0000215 asks for wording that explains saving the caption. `prompts/TAPTURE-09102026-2154/screenshots/FBK0000215.png` shows one photo, the Caption text field and a button actually labelled "Add to the photo". The field label is not the action to rename. Seen on Android mobile, compact portrait, light, text scale 1, app 1.0.0.
- `frontend/lib/features/capture/presentation/capture_screen.dart:721` binds `capture-caption-add` to `captionAddToTicked`/`captionAddToAll`. The current English plurals are in `frontend/lib/core/copy/l10n/app_en.arb:4163` and line 4174. `_addCaption` at screen line 1000 durably appends to the target photos, then clears the record-caption input.

### Scope
- Reach: new Capture and saved-record editing, Android/iOS/Windows/macOS/Linux/web, all three widths, both orientations, light/dark/outdoor, 100/200 percent text, English and the expanded pseudo-locale with RTL.
- Change: the existing `captionAddToAll` and `captionAddToTicked` catalogue values/descriptions; regenerate `frontend/lib/core/copy/l10n/app_en_XA.arb` and generated localization output. Keep the stable `Copy`/`LocalizedCopy` method names and `capture-caption-add` key.
- Do not change: the Caption field label, footer save actions, target selection, append behavior, persistence, success toast, failure recovery, record-only caption autosave and input-clear timing. No fresh caption-writing operation is introduced.
- Exclusions: the separate photo-viewer caption editor has its own action and does not use these two copy keys. Legacy Rapid links redirect to ordinary Capture and receive this change; the retired Rapid widget gets no new UI. Backend, exports and stored caption data contain no affected action label.

### Rules
- FE-L10N-01 to FE-L10N-03, FE-L10N-06: retain semantic keys and ICU plurals; never build the phrase with concatenation.
- FE-SIMP-09, FE-SIMP-10, FE-A11Y-02, FE-A11Y-07, FE-STATE-07: name the action plainly and preserve durable success/failure behavior.

### Steps
1. Set `captionAddToAll` to `{count, plural, one{Save caption to 1 photo} other{Save caption to all {count} photos}}`. Set `captionAddToTicked` to `{count, plural, one{Save caption to 1 ticked photo} other{Save caption to {count} ticked photos}}`. Update translator descriptions to distinguish saving to target photos from saving the whole record.
2. Run `dart run tool/generate_pseudo_locale.dart`, `flutter gen-l10n` and `dart run tool/generate_copy_messages.dart` from `frontend/`. Preserve method signatures and untouched catalogue messages.
3. Update `frontend/test/core/copy/copy_test.dart`, `frontend/test/features/capture/presentation/capture_feedback_test.dart` and `frontend/test/features/capture/presentation/capture_edit_screen_test.dart`. Assert exact singular/plural wording, counts and semantics for one photo, all photos, one ticked photo, several ticked photos, empty text and zero targets. Preserve the append/clear/failure/record-only caption assertions.
4. Add tests named with prefix `feedback 2154 caption visual` to the existing feedback suite. Reuse its caption harness and `ScreenMatrix.corners`; name outputs `frontend/test/features/capture/presentation/goldens/feedback_2154_caption_<one|all|ticked_one|ticked_many>_<corner>.png`. Under D3(a), generate only this set, compare normally and inspect it before the final archive/cleanup.

### Acceptance criteria
- [ ] The visible and accessible action begins "Save caption" and names the exact target count/scope in every singular/plural case; old "Add to..." action wording is absent on both affected surfaces.
- [ ] Empty/whitespace captions stay disabled, zero targets show no photo-caption action, and selecting photos does not rewrite the typed text.
- [ ] Successful activation still appends independent photo captions and clears the input only through the existing durable path; failure retains the text and existing photo captions.
- [ ] Behavior, copy, accessibility and D3 visual checks pass across the declared matrix. FBK0000215 is resolved.

## W3 — Show photo guidance without a toggle
**Feedback:** FBK0000214 · **Type:** Improvement · **Priority:** P3 · **Effort:** M · **After:** W2

### Evidence
- FBK0000214 asks to remove "What to capture" and retain an elegant photo-content guideline titled "Photos to show". `prompts/TAPTURE-09102026-2154/screenshots/FBK0000214.png` shows the toggle, a "Photos should show" list, a separate caption-guidance row and another caption-help panel above the editor. Seen on Android mobile, compact portrait, light, text scale 1, app 1.0.0.
- `frontend/lib/features/capture/presentation/capture_guide_card.dart:33` reads toggle state, creates the button at line 40 and gates both lists at line 64. `frontend/lib/features/capture/presentation/capture_screen.dart:550` mounts it, while lines 677–684 separately supply the caption panel. `frontend/lib/features/capture/presentation/record_caption_field.dart:159` shows that panel during active input.
- Guidance comes from `CaptureGuide.of` in `frontend/lib/features/templates/domain/capture_guide.dart:23`, including captured-version resolution in Capture. W2 has changed only the photo-caption action copy; its key and persistence still have their original contracts.

### Scope
- Reach: every new/edit `CaptureScreen` using these widgets on all six platforms, three widths, both orientations, light/dark/outdoor, text scales 1/2, English and the expanded RTL pseudo-locale.
- Change: `frontend/lib/features/capture/presentation/capture_guide_card.dart`, `frontend/lib/features/capture/presentation/capture_screen.dart`, and D2's `frontend/lib/features/capture/presentation/capture_guide_state.dart`/`frontend/lib/features/capture/presentation/record_caption_field.dart` plumbing; `captureGuidePhotos` in `frontend/lib/core/copy/l10n/app_en.arb`, its pseudo catalogue and generated output.
- Do not change: template data, `CaptureGuide.of` field selection/order/cap, historical version resolution, project/template overflow, manual fields, evidence tray, caption autosave, dictation, microphone permissions, audio, processing and both footer saves.
- Exclusions: camera and photo-viewer screens have no `CaptureGuideCard`; do not add a guideline there. Legacy Rapid links redirect to ordinary Capture and receive the guideline; the retired Rapid widget gets no new UI. Backend and exports have no corresponding presentation.

### Rules
- FE-CONS-01, FE-THEME-01, FE-L10N-07: reuse the existing `_GuideList`, `AppIcons.camera`, `Space` and `AppText`; original template labels remain data.
- FE-SIMP-01, FE-SIMP-03, FE-RESP-04, FE-RESP-06, FE-A11Y-03, FE-A11Y-06: guidance takes no tap, has natural height, and preserves reachable caption/save controls.

### Steps
1. Set `captureGuidePhotos` to "Photos to show". Convert `CaptureGuideCard`'s top guidance into one passive, immediately visible `_GuideList` with camera icon, that heading and `captureGuideItems(guide.photoFields)`. Remove the toggle, expansion semantics and top caption list. With no photo fields, render no guideline heading/container; retain the existing optional `targets` constructor contract.
2. Gate the guide in `CaptureScreen` using `guide.photoFields.isNotEmpty`. Apply D2's exact caption-panel/state policy. Preserve `RecordCaptionField`'s focused-input protection, controller synchronization and lifecycle writes while removing approved panel-only state/listeners. Keep the six-line editor, voice/audio controls and W2's save-caption action.
3. Regenerate pseudo/localization output with W2's commands. Update `frontend/test/features/capture/presentation/capture_guide_widgets_test.dart`: guidance is visible without interaction, no toggle/top caption row exists, empty/photo-empty/caption-only guides create no orphan heading, and long original labels remain complete. Assert D2's panel behavior during typing, dictation, recording, close and template change, alongside unchanged caption persistence.
4. Update `frontend/test/features/capture/presentation/capture_workflow_fixture.dart` wherever it assumes `capture-guide-toggle`, expansion semantics and the caption panel. Replace only superseded guide interaction assertions with passive-guidance readability/semantics assertions. Preserve all target-picker, focus/caret, accessibility, failed-write, draft, resize, save and route tests used by the native/browser entrypoints.
5. Exercise `ScreenMatrix.cells` with production fonts plus 393×886 at normal text and open keyboard. Assert immediate readable guidance, no overflow, six-line caption availability and reachable save actions; rotate/resize with a photo and caption present and assert neither is lost.
6. Add tests named with prefix `feedback 2154 guide visual` in the guide suite using the existing theme/font/matrix support. Name outputs `frontend/test/features/capture/presentation/goldens/feedback_2154_guide_<corner>.png`, with `<corner>` from `ScreenMatrix.corners`. Under D3(a), also regenerate the existing `frontend/test/features/capture/presentation/goldens/capture_workflow_<corner>.png` set and `frontend/test/features/capture/presentation/goldens/capture_workflow_reported_light.png` through the native workflow entrypoint's `production Capture visual` tests. These 13 full-shell visuals intentionally lose the old guide button; update no unrelated visual baseline.

### Acceptance criteria
- [ ] Capture shows one immediate "Photos to show" guideline with original photo-field labels, no "What to capture" button and no top caption-guidance row; the focused caption-help panel follows D2.
- [ ] An empty photo-guidance list renders no guideline content and reserves no guideline space, including templates containing caption guidance alone.
- [ ] Template changes and captured-version edits display the correct photo guidance without stale state; template metadata and stored evidence are unchanged.
- [ ] Guide, caption, voice/audio, photo intake and both saves remain readable/reachable across every declared width/orientation/theme/text/locale case; rotation and resizing retain draft evidence.
- [ ] Updated widget, production-shell and D3 visual checks pass. FBK0000214 is resolved; W2's caption-save behavior remains verified.

## Verification
- Run each command below from `frontend/`. Record actual exit codes and failures in the archive task; source inspection and generated files do not establish runtime acceptance.
- Run `dart run tool/generate_pseudo_locale.dart --check`, `dart run tool/generate_copy_messages.dart --check`, `dart run tool/check_l10n.dart` and `flutter analyze`. Check formatting with `dart format --output=none --set-exit-if-changed` followed by the explicit changed Dart paths.
- Run the affected suites: `flutter test test/features/context/presentation/context_maintenance_test.dart test/features/settings/presentation/capture_settings_screen_test.dart test/core/copy/copy_test.dart test/features/capture/presentation/capture_feedback_test.dart test/features/capture/presentation/capture_edit_screen_test.dart test/features/capture/presentation/capture_guide_widgets_test.dart test/features/templates/domain/capture_guide_test.dart`. Keep D3(a)'s temporary visual baselines present for normal comparisons.
- Run `flutter test test/features/capture/presentation/capture_workflow_layout_test.dart` and `flutter test --platform chrome test/features/capture/presentation/capture_workflow_layout_browser_test.dart`. Run `flutter test test/features/context/presentation/context_values_sheet_test.dart test/features/context/domain/context_cascade_test.dart test/features/capture/domain/gps_capture_test.dart test/features/capture/presentation/capture_controller_test.dart test/features/capture/presentation/capture_live_transcript_test.dart` for the preserved nearby contracts.
- Run `flutter test integration_test/capture_raw_offline_test.dart -d windows` against the existing native offline harness. Assert durable capture/snapshots, preserved captions and zero outbound calls. Platform-style variants alone do not certify device GPS, a real camera or Chrome runtime behavior.
- Run the relevant unchanged guardrails: `flutter test test/architecture/tokens_test.dart test/architecture/responsive_test.dart test/architecture/state_test.dart test/architecture/layering_test.dart test/architecture/network_test.dart test/architecture/data_safety_test.dart test/architecture/icons_test.dart`. Keep their deliberate-violation fixtures and assertions intact.
- Under D3(a), use `--update-goldens` only with the exact affected test path and `--plain-name "feedback 2154 caption visual"` / `--plain-name "feedback 2154 guide visual"` / `--plain-name "production Capture visual"`. Record every actual regenerated relative path under W2/W3. Compare without that flag, visually inspect the intended results, archive PNGs plus a relative-path/hash manifest externally, reopen the archive and verify every entry, then remove only this run's exact generated files with checked absolute paths. Preserve pre-existing files and all archived evidence.
- Deliver the acceptance-source patch/manifest described above and verify that a temporary index can apply it with its helper closure. Do not change ignore policy, force-add ignored content or automatically stage unrelated work.
- Check only freshly verified acceptance. After each progress update run `dart run tool/sync_dev_tracker.dart`, then `dart run tool/sync_dev_tracker.dart --check`; finish with `dart run tool/check_plan.dart`. Include the generated tracker changes.
- When task 162 still prevents the required Chrome matrix, D3(b) defers visual evidence, a required suite fails, or another required check cannot run, report **Partially complete**, retain the relevant open acceptance and name the exact blocker. Existing tasks 150/159/160/161/162 remain separate; neither this archive nor a passing focused suite certifies the entire repository green.
