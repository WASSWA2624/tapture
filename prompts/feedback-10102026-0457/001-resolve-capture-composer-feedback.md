# 001 — Resolve Capture composer feedback

**Feedback:** FBK0000216, FBK0000217, FBK0000219 · **Work items:** 2 · **Depends on:** none

## Goal

Capture shows readable photo guidance headed “Photos should show” and a compact photo/caption composer that grows with typed lines. Typed text and recorded audio remain independent, durable caption inputs on new Capture and saved-record editing across Android, iOS, Windows, macOS, Linux and web, compact/medium/expanded widths, both orientations, light/dark/outdoor themes and 100/200 percent text.

## Run order

| Item | Title | Feedback | Type | Priority | Effort | After |
| --- | --- | --- | --- | --- | --- | --- |
| W1 | Restyle the passive photo guidance | FBK0000216, FBK0000219 | Improvement | P3 | S | — |
| W2 | Compose photos, growing text and audio | FBK0000217 | Improvement | P3 | M | — |

Both items improve existing Capture presentation. Each groups entries about one component/flow; W1 comes first because it is smaller. Shared catalogue components already supply the required primitives; no new shared widget is required.

## Decisions

⛔ Stop here. Get an answer to every decision before step 1 of any work item. “Proceed” means the defaults. Record the answers in the implementation task. This file requests implementation approval later; generating it has not approved these choices.

- **D1 (W1, unspecified photo-hint appearance):** Approve (a) a passive `AppCard` with its standard tone/outline, camera icon, heading in `AppText.label` and wrapping field labels in `AppText.body`; (b) the same contents without a card, using the existing outer `Space.x4` horizontal / `Space.x1` vertical padding. Default: **(a)**, because it gives guidance a clear shared surface without adding an interaction. Both use the exact new heading and preserve original template labels.
- **D2 (W2, WhatsApp reference and action placement):** Approve (a) a Tapture-styled composer with the photo-source action at the input's leading edge and existing dictation/recording actions at its trailing edge, removing duplicate photo-add actions from the tray on Capture; (b) the same growing caption field and audio actions with photo-add actions retained in the tray and no leading photo action. Default: **(a)**, because it best expresses the requested text/multimedia arrangement. Both start at one text line, grow through six lines and then scroll internally. “Exactly like WhatsApp” supplies no reference image of the intended external control; approval selects this concrete interpretation. Use Tapture colours, `Radii.sm`-equivalent existing field corners and 48dp targets; large capsule corners, send-message behaviour, emoji, stickers and new attachment types are excluded.
- **D3 (verification, removed test images):** Approve (a) restore only required archived test images temporarily, validate the intended visuals, archive restored/generated images outside the repository with path/SHA-256 manifests, then remove only those verified temporary images; (b) retain the required fixtures and approved baselines as deliverable test assets and explicitly supersede task 146's no-test-images criterion. Default: **(a)**, matching task 146 and task 164's established handling. Neither option changes a checker, skips a test, replaces an unrelated baseline, deletes an original archive or stages unrelated changes.

## Rules

- Read `AGENTS.md`, `frontend/.rules/README.md` and all 13 listed rule files. This is frontend work; backend code and server rules are outside its scope.
- FE-CONS-01, FE-CONS-02, FE-CONS-03, FE-STR-09: compose `AppTextField`, `AppIconButton`, `AppCard`, `AppPhotoThumb` and the existing recording/transcript components. Preserve their defaults and public contracts; add no parallel input, camera picker, recorder, thumbnail or guidance framework.
- FE-THEME-01 to FE-THEME-03, FE-THEME-06, FE-THEME-08, FE-CODE-09: use existing tokens and `AppIcons`. Corners stay at the existing minimal nonzero `Radii` values; themes share geometry.
- FE-RESP-03, FE-RESP-04, FE-RESP-06 to FE-RESP-10, FE-A11Y-01 to FE-A11Y-04, FE-A11Y-06: preserve input across resizing, keep keyboard insets with `AppPage`, cap readable width, test the full matrix and label every 48dp action.
- FE-L10N-01 to FE-L10N-03, FE-L10N-05 to FE-L10N-07: use `Copy.of(context)`, stable catalogue keys, directional layout, expanded pseudo-locale and RTL; template labels remain untranslated data.
- FE-STATE-04, FE-STATE-06, FE-STATE-07, FE-STATE-09, FE-SIMP-03, FE-SIMP-09, FE-SEC-04, FE-SEC-08: keep existing controllers, durable writes, offline capture and append-only evidence. This prompt changes presentation, not stored formats, ownership, permission policy, egress or recognition defaults.
- FE-TEST-01 to FE-TEST-07, FE-TEST-10, FE-FLOW-02 to FE-FLOW-04, FE-FLOW-08: ship meaningful tests, preserve guardrails, record verified acceptance and regenerate the tracker. There is no Flutter review command; do not add `frontend/tool/verify.dart`.

## Before the work items

1. Inventory the current Git changes and preserve them. Read tasks 001/002, 003, 012, 065, 125, 146, 155, 157, 158, 164 and 162, their dependencies and Definitions of done. The snapshot used here is `a39c2476`; confirm the cited code still matches before applying the specified changes.
2. From `frontend/`, run `dart run tool/new_task.dart 24-product-refinements "Resolve feedback archive 10102026-0457"`. The actual tool takes two arguments. Give the allocated task completed prerequisites 001/002, copy both work items' acceptance criteria into its Definition of done, link this prompt and declare only the additive presentation/configuration members named below. Set `**Implementation started:** Yes` before the first implementation edit. Keep feature work in step 24 and whole-product hardening in step 27.
3. Record the selected D1–D3 options. Record supersession of task 164's old heading and six-line minimum without copying its historical completion claims. Preserve its unfinished acceptance and the existing task 012/003 verification gaps.
4. Baseline the affected tests listed under Verification. Task 146 documents the original image archive beneath the platform local-application-data directory at `TaptureTestArchives/2026-10-08-0be07c664cbc4f62a46a9d6648d58fe8/test-images.zip`; task 164's newer Capture images are at `TaptureTestArchives/feedback-09102026-2154/task164-visual-evidence.zip`, with `manifest.json` alongside. Verify member paths/hashes before D3 restoration; never overwrite a different existing file. The current tree also lacks the earlier feedback folders by user deletion; leave those deletions intact.
5. Use the local acceptance sources already present under `frontend/test/`. The final `/test/` rule in `frontend/.gitignore` ignores many of them. Deliver changed ignored tests and their recursive relative-import closure as `acceptance-sources.patch` plus `acceptance-sources.manifest.json` in this prompt's folder, using a temporary Git index to prove the patch reconstructs the exact sources. Preserve the real index and ignore policy. This avoids relying on a prior, currently deleted acceptance patch.

## W1 — Restyle the passive photo guidance

**Feedback:** FBK0000216, FBK0000219 · **Type:** Improvement · **Priority:** P3 · **Effort:** S · **After:** —

### Evidence

- FBK0000216 requests “Photos should show” in place of “Photos to show”. `prompts/TAPTURE-10102026-0457/screenshots/FBK0000216.png` shows the old heading and a camera icon above an inline list of three template field labels.
- FBK0000219 requests a better photo hint. `prompts/TAPTURE-10102026-0457/screenshots/FBK0000219.png` shows the same plain guidance on the page background above the empty photo tray and large caption/audio sections; it supplies no replacement design. Both reports: Android mobile, compact portrait, light, text scale 1, app 1.0.0.
- Confirmed current cause: `frontend/lib/features/capture/presentation/capture_guide_card.dart:34` supplies `captureGuidePhotos`; line 62 begins the padded icon/title/caption row. `frontend/lib/core/copy/l10n/app_en.arb:6991` still says “Photos to show”. `frontend/lib/features/capture/presentation/capture_screen.dart:549` mounts this shared Capture widget.

### Scope

- Reach: new Capture and saved-record editing using `CaptureGuideCard`, all six platforms, compact/medium/expanded, portrait/landscape, light/dark/outdoor, 100/200 percent text, English and expanded RTL pseudo-locale. `/capture`, project Capture and redirected legacy Rapid links use this same implementation.
- Change: `frontend/lib/features/capture/presentation/capture_guide_card.dart` (`CaptureGuideCard`, `_GuideList`), `frontend/lib/core/copy/l10n/app_en.arb` (`captureGuidePhotos`), `frontend/lib/core/copy/l10n/app_en_XA.arb`, `frontend/lib/core/copy/l10n/app_localizations.g.dart` and `frontend/lib/core/copy/l10n/app_localizations_en.g.dart`. Use existing `frontend/lib/core/widgets/app_card.dart`, `Space`, `AppText` and `AppIcons.camera` without changing their contracts.
- Do not change: `CaptureGuide.of` selection/order/cap, captured template-version resolution, template metadata, target selectors, empty-guide behavior, caption guidance removal, captions, audio and saves.
- Exclusions: standalone camera, scanner, photo viewer, Manual capture, backend and exports have no `CaptureGuideCard`. Add no new hint to those surfaces. No platform-specific implementation is required for this shared Dart presentation.

### Rules

- FE-CONS-01, FE-THEME-01 to FE-THEME-03, FE-THEME-06, FE-L10N-01, FE-L10N-02, FE-L10N-07: use D1's existing surface/tokens and retain original template field labels.
- FE-SIMP-03, FE-SIMP-06, FE-RESP-04, FE-RESP-06, FE-A11Y-03, FE-A11Y-04: guidance remains passive, immediately readable and naturally sized.

### Steps

1. Change only `captureGuidePhotos` to “Photos should show” and describe it as passive guidance about photo contents. The later report explicitly supersedes task 164's older “Photos to show” request. Preserve the semantic key and `captureGuideItems` formatting.
2. Apply D1 to `CaptureGuideCard` and `_GuideList`: camera icon at the directional start, heading followed by fully wrapping original labels. Use the approved single outer padding layer, existing text styles and on-surface ink. Preserve `targets` and the early empty-photo-fields return. Exclude new expansion, dismissal, navigation, selection and persistence state.
3. From `frontend/`, run `dart run tool/generate_pseudo_locale.dart`, `flutter gen-l10n` and `dart run tool/generate_copy_messages.dart`. Preserve unrelated messages and method signatures.
4. Update `frontend/test/core/copy/copy_test.dart` and `frontend/test/features/capture/presentation/capture_guide_widgets_test.dart`: exact heading, passive surface, no toggle/caption panel, original long labels, empty/caption-only guide, `targets`, template changes, semantics and contrast. Exercise `ScreenMatrix.cells` with production fonts, English and expanded RTL text. Preserve the caption-persistence regressions in that same suite for W2.
5. Update only the guide's existing visual expectations under D3. Regenerated set for this item: `frontend/test/features/capture/presentation/goldens/feedback_2154_guide_<corner>.png` for the 12 existing `ScreenMatrix.corners` names. Compare normally and inspect every image. W2 owns the final full-shell images because it also changes that composition.

### Acceptance criteria

- [ ] Every affected Capture guide visibly and accessibly says “Photos should show”; the superseded heading is absent from this UI.
- [ ] D1's surface uses shared tokens and minimal nonzero corners; guidance is immediate and requires no interaction.
- [ ] Original labels retain their order and full content; empty photo guidance reserves no guideline space and existing `targets` still render.
- [ ] Guidance wraps without clipping throughout the declared width/orientation/theme/text/locale matrix and does not displace keyboard-safe save access.
- [ ] Copy, widget, accessibility and approved visual checks pass. FBK0000216 and FBK0000219 are resolved.

## W2 — Compose photos, growing text and audio

**Feedback:** FBK0000217 · **Type:** Improvement · **Priority:** P3 · **Effort:** M · **After:** —

### Evidence

- FBK0000217 requests a WhatsApp-style photo/caption input with height following the text rows. `prompts/TAPTURE-10102026-0457/screenshots/FBK0000217.png` shows photo intake in a separate empty-state block, a tall empty Caption field with dictation/waveform icons and a separate saved-transcript panel. Seen on Android mobile, compact portrait, light, text scale 1, app 1.0.0.
- Confirmed layout cause: `frontend/lib/features/capture/presentation/record_caption_field.dart:99` sets `minLines: 6` and `maxLines: null`. `frontend/lib/features/capture/presentation/capture_screen.dart:594` renders `PhotoTray` separately from the caption at line 664; `frontend/lib/features/capture/presentation/photo_tray.dart:70` creates the empty-state photo action.
- Text/audio capability already exists and is a preservation contract: `frontend/lib/features/capture/presentation/capture_screen.dart:671` writes typed captions; line 683 selects the existing live/plain audio action, and line 1138 stages audio ownership before recording. `frontend/lib/features/capture/data/capture_record_writer.dart:248` persists audio attachments with record/photo links, and line 302 independently persists typed captions. Both can coexist; audio-only input must need no fabricated text. Rearranging the composer must preserve these existing paths.

### Scope

- Reach: the same six platforms, three widths, both orientations, three themes, text scales 1/2 and English/expanded RTL locale on new Capture and saved-record editing. Touch, pointer and keyboard use the existing explicit tap/click actions; introduce no hold-to-record gesture. Web keeps its existing device-service capability outcomes.
- Change: `frontend/lib/features/capture/presentation/record_caption_field.dart`, `frontend/lib/features/capture/presentation/capture_screen.dart`, `frontend/lib/features/capture/presentation/photo_tray.dart` and `frontend/lib/core/constants/app_constants.dart`. Add optional `RecordCaptionField.leading`, forwarding to the existing `AppTextField.prefix`; add backward-compatible `PhotoTray.showAddAction = true`. Add `AppConstants.captureCaption` with `minLines: 1`, `maxLines: 6`. Existing core widget defaults remain intact.
- Do not change: caption autosave/reset/focus/caret protection, `capture-caption-add` wording/counts/append/clear timing, photo ordering/selection/delete/undo, photo source choices, permission prompts, microphone lease, raw/audio/transcript bytes, audio ownership, speech readiness/fallback, transcript lifecycle, footer actions, routes and local-first save semantics.
- Exclusions: Manual fields and the photo viewer's separate caption editor retain their current input contracts. Standalone camera/scanner/Transcribe/Meetings, backend, bundles and exports have no composer presentation change. Legacy Rapid links inherit ordinary Capture; the retired Rapid widget receives no new UI.

### Rules

- FE-CONS-01, FE-STR-11, FE-STATE-04, FE-STATE-07, FE-STATE-09: forward existing callbacks and reuse the source sheet, `AppTextField`, `AppIconButton`, recorder and transcript components.
- FE-RESP-03, FE-RESP-06 to FE-RESP-10, FE-A11Y-01 to FE-A11Y-03, FE-A11Y-06, FE-L10N-05: grow by rendered lines, retain text through resize, keep every action reachable and mirror the composer.
- FE-SIMP-03, FE-SIMP-09, FE-SEC-04, FE-SEC-08, FE-TEST-10: audio input never requires text, network availability, a speech model or successful transcription; denied permissions and failed writes retain all existing evidence.

### Steps

1. Add the named line-limit constants and use them in `RecordCaptionField`'s existing `AppTextField`. Keep `TextInputAction.newline`. Grow from one through six rendered text lines, shrink after deletion, scroll internally above the maximum and scale naturally at 200 percent text. Preserve the field controller, focus synchronization, `resetKey` and lifecycle writes.
2. Apply D2: forward the optional leading slot; build its photo action with `AppIconButton`, `AppIcons.addPhoto`, `captureAddPhoto` for label/tooltip and the existing `_add` callback, disabled by the existing readiness gate. Pass D2's explicit tray-action visibility. When hidden, an empty tray keeps passive `AppEmptyState` guidance and a populated tray renders only the existing thumbnails; every photo remains reachable. Preserve the tray's default for other callers.
3. Keep dictation and the existing waveform action as distinct labelled operations in the composer. Retain `CaptureTranscribeButton` when live speech is ready and `_RecordAudioButton` as the existing fallback, plus `AudioRecorder`/`LiveTranscriptPanel` under their existing visibility conditions. Typing, microphone start/stop and photo addition retain one another's drafts. Keep text-only, audio-only and mixed evidence save paths with existing ownership. Exclude new mode selectors, schema changes, dependencies and recording implementations.
4. Update `frontend/test/features/capture/presentation/capture_guide_widgets_test.dart`, `capture_widgets_test.dart`, `capture_feedback_test.dart`, `capture_edit_screen_test.dart` and `capture_screen_test.dart`: measure empty/one/three/six/eight-line heights and shrinkage, scroll to the last line, preserve caret during delayed persistence, test explicit reset, newline/paste, failed writes, photo action/selection, typing during audio and denied microphone. Assert D2's exact action count and semantics. Use existing hand-written fakes.
5. Extend `frontend/test/features/capture/data/capture_record_writer_test.dart` for text-only, audio-only and mixed sessions, reload and owner links, with no empty typed-caption row for audio-only input. Update `frontend/test/features/capture/presentation/capture_workflow_fixture.dart:817` and its other six-line-minimum assumptions to the approved growing contract. Preserve its production shell, real fonts, per-platform variants, route/resizing/keyboard/save assertions and both native/browser entrypoints; exercise `ScreenMatrix.cells`, reported 393×886 and 200 percent text with an open keyboard.
6. Under D3, regenerate only this item's intended visual sets: the existing 12 `frontend/test/features/capture/presentation/goldens/capture_workflow_<corner>.png` images and `capture_workflow_reported_light.png`, plus new `frontend/test/features/capture/presentation/goldens/feedback_0457_composer_<state>_<corner>.png` images for `empty`, `multiline`, `audio` and `photos` across the 12 `ScreenMatrix.corners` names. Register the new visuals in the existing guide/field suite with prefix `feedback 0457 composer visual`; compare normally and inspect the resulting 61 images. Final shell images include W1's completed guide.

### Acceptance criteria

- [ ] D2's photo/caption arrangement renders once, uses shared components, preserves the photo source sheet and retains labelled 48dp dictation/recording targets.
- [ ] Empty input starts at one rendered line, grows through six, scrolls beyond six and shrinks after deletion; no text disappears at 200 percent scale.
- [ ] Text-only, audio-only and mixed inputs save and reload through existing durable paths; audio-only input creates no placeholder caption and preserves record/photo ownership.
- [ ] Typing, dictation, recording, photo intake, backgrounding, rotation and width/locale/theme changes preserve draft evidence, controller text, caret and explicit-reset behavior.
- [ ] Denied microphone, unavailable speech model, offline mode and storage failure leave typing/photo capture usable and retain prior evidence; no new egress occurs.
- [ ] Both footer saves and photo-caption count/scope/append behavior retain their contracts. Behavior, real-database, native/browser flow, accessibility and D3 visual checks pass across the declared reach. FBK0000217 is resolved.

## Verification

- Run commands from `frontend/`. Record baseline and final exit codes separately. Required frontend analysis: `flutter analyze --no-pub`; formatting: `dart format --output=none --set-exit-if-changed` followed by the exact changed Dart paths. Run `dart run tool/check_l10n.dart`, `dart run tool/generate_pseudo_locale.dart --check` and `dart run tool/generate_copy_messages.dart --check`.
- Run `flutter test` with these existing paths: `test/core/copy/copy_test.dart`, `test/core/widgets/fields/app_text_field_test.dart`, `test/features/capture/presentation/capture_guide_widgets_test.dart`, `test/features/capture/presentation/capture_widgets_test.dart`, `test/features/capture/presentation/capture_feedback_test.dart`, `test/features/capture/presentation/capture_edit_screen_test.dart`, `test/features/capture/presentation/capture_screen_test.dart`, `test/features/capture/presentation/capture_controller_test.dart` and `test/features/capture/data/capture_record_writer_test.dart`. Use the pre-work inventories/manifests to restore required unchanged fixtures and baselines under D3.
- Run `flutter test test/features/capture/presentation/capture_workflow_layout_test.dart` and `flutter test --platform chrome test/features/capture/presentation/capture_workflow_layout_browser_test.dart`. The shared native fixture enumerates all five native `TargetPlatform` values; the browser entrypoint verifies real web composition. This is shared presentation verification, not certification of untested physical-device audio adapters.
- Run `flutter test integration_test/capture_raw_offline_test.dart -d windows` to preserve real local-first/offline capture. Keep its backend-unreachable and zero-egress assertions. Run `flutter test test/architecture/tokens_test.dart test/architecture/responsive_test.dart test/architecture/icons_test.dart test/architecture/layering_test.dart test/architecture/state_test.dart test/architecture/data_safety_test.dart test/architecture/network_test.dart test/security/secret_scan_test.dart` unchanged, including their deliberate-violation fixtures; never weaken a checker to pass.
- Use `--update-goldens` only on W1/W2's explicitly listed visuals, then rerun their comparisons without that flag. Keep all unrelated restored baselines byte-identical. In the task evidence list the actual paths regenerated under each item, selected D3 handling and visual inspection results.
- Under D3(a), create a unique external archive containing the exact temporary restored/generated-image inventory and its SHA-256 manifest. Reopen it, verify every member's path/hash/decode, verify all cleanup targets resolve beneath `frontend/test/`, then remove only that inventory and empty generated directories. Preserve original archives and every pre-existing image. Deliver a sanitized portable `visual-evidence.manifest.json` beside this prompt; use environment-relative external locations, never a personal profile path. Under D3(b), retain approved assets and update the specifically superseded task-146 criterion. Missing assets prevent verification; they never justify skipping checks.
- Task 164 records unrelated existing test failures and task 162 owns the Chrome CanvasKit/bootstrap blocker. Reproduce failures against the baseline, retain their evidence and leave their owners unchanged. This prompt does not authorize SDK patches, guardrail changes, fabricated baselines or unrelated fixes. A required failure remains an open checkbox and the result is **Partially complete**; do not claim a green gate from source existence, a fake alone or a historical run. Those blockers do not meet the generator's split reasons.
- Update `app-write-up.md`'s existing Capture presentation requirements and task 012's presentation-supersession note to this task without duplicating requirements or renumbering sections. Update the new task's acceptance only from completed checks and retain open prerequisite/whole-product criteria.
- Regenerate `dev-tracker.md` with `dart run tool/sync_dev_tracker.dart`, then run `dart run tool/sync_dev_tracker.dart --check` and `dart run tool/check_plan.dart`. Never hand-edit the tracker. Verify the ignored-test patch/hash manifest in a temporary index and preserve unrelated edits and the real index. Report the changed behavior, tests, approved visual paths and any remaining acceptance blockers.
