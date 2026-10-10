# Feedback prompts — TAPTURE-10102026-0457.xlsx

4 entries → 1 prompt, 2 work items (3 actionable entries, 1 Already resolved). Generated 2026-10-10 (Africa/Kampala). Repository commit: `a39c2476`.

Read all four Feedback rows, four Screenshots rows, Export Details and every full-size image. The workbook reports four records/four screenshots with unrestricted filters. Output is prompts only; application code, tests, plan and tracker were not changed. Existing user deletions remain intact.

## Run order

| Prompt | Item | Title | Feedback | Type | Priority | After |
| --- | --- | --- | --- | --- | --- | --- |
| [001](001-resolve-capture-composer-feedback.md) | W1 | Restyle the passive photo guidance | FBK0000216, FBK0000219 | Improvement | P3 | — |
| [001](001-resolve-capture-composer-feedback.md) | W2 | Compose photos, growing text and audio | FBK0000217 | Improvement | P3 | — |

One prompt covers the archive. The work items group a real shared component and a real Capture flow respectively. Both are presentation improvements; the smaller guidance item runs first. No migration, external repository or later-result dependency requires a split.

## Coverage

| Feedback ID | Category | Screen | Outcome |
| --- | --- | --- | --- |
| FBK0000216 | General feedback | Projects › Capture | 001 W1 — Improvement: use “Photos should show” throughout the existing guide. |
| FBK0000217 | General feedback | Projects › Capture | 001 W2 — Improvement: compact photo/caption arrangement and text-driven height; D2 fixes the visual interpretation. |
| FBK0000218 | General feedback | Projects › Capture | Already resolved: `frontend/lib/features/capture/presentation/capture_screen.dart:671` writes text, line 683 exposes live/plain recording, and `frontend/lib/features/capture/data/capture_record_writer.dart:248` files audio independently from typed captions at line 302. No implementation item. |
| FBK0000219 | General feedback | Projects › Capture | 001 W1 — Improvement: restyle the same photo-guidance component per D1. |

## Open questions

All questions belong to prompt 001 and are answered before implementation, not during prompt generation. “Proceed” selects every default.

- **001 D1:** Photo-hint surface: (a) standard passive `AppCard`; (b) borderless existing padding. Default **(a)**.
- **001 D2:** Composer placement: (a) leading photo action with growing text and existing trailing voice/audio actions, suppressing duplicate tray photo actions; (b) growing caption with photo actions remaining in the tray. Default **(a)**. Both use one-to-six rendered lines and Tapture's minimal nonzero corners. The archive does not establish a pixel reference for the external application's control.
- **001 D3:** Test-image handling: (a) temporary restoration/generation followed by verified external archival and exact-file cleanup; (b) retain required approved test assets and supersede task 146's no-test-images criterion. Default **(a)**.

No separate reporter question prevents specification under these defaults. FBK0000218 requests alternative text/audio inputs already supported by the current code; no exclusivity requirement is stated. W2 preserves that capability while implementing FBK0000217's requested layout.

## Evidence inventory

All entries were observed on Android mobile, app 1.0.0, production, English, online, compact portrait, light theme and text scale 1. Viewport: 393×886 logical pixels at 2.75× density; display: 393×886. Device model was recorded generically as Android. These are sample conditions, not the implementation reach. Account, project, device and network identifiers, personal names and user-agent strings have been omitted.

The normalized route for every entry is `/projects/:projectId/capture`, route name `capture`. Project-specific screen text is omitted. `frontend/lib/app/router.dart:839` maps that route to `CaptureScreen`; line 832 serves the Capture branch and line 851 redirects legacy Rapid links to ordinary Capture. Every change also applies to the existing saved-record editing use of the affected widgets.

| Entry | Message paraphrase | Full-size image inspected | Image observation |
| --- | --- | --- | --- |
| FBK0000216 | Rename the photo-guidance heading to “Photos should show”. | `prompts/TAPTURE-10102026-0457/screenshots/FBK0000216.png` | Camera icon, old heading and three inline template labels above empty-photo guidance, tall caption input and audio/transcript content. |
| FBK0000217 | Arrange photo/caption input like a familiar messaging composer and grow text height with its rows. | `prompts/TAPTURE-10102026-0457/screenshots/FBK0000217.png` | Separate photo-add empty state; oversized empty caption box with dictation/waveform icons; separate saved-audio transcript panel; footer saves. No external composer reference is pictured. |
| FBK0000218 | Accept text and audio as caption inputs. | `prompts/TAPTURE-10102026-0457/screenshots/FBK0000218.png` | The Caption field, dictation and audio controls appear simultaneously with a saved transcript area; the requested input types already exist. |
| FBK0000219 | Give photo guidance a clearer appearance. | `prompts/TAPTURE-10102026-0457/screenshots/FBK0000219.png` | The same plain, minimally differentiated photo hint on the page background; no alternative visual design is shown. |

## Current-code confirmation and reach

- **Heading and hint remain actionable:** `frontend/lib/core/copy/l10n/app_en.arb:6991` still contains the old heading. `frontend/lib/features/capture/presentation/capture_guide_card.dart:62` renders only a padded icon/title/text row. W1 changes this shared feature component once, preserving `CaptureGuide`'s original labels and empty handling. The newer heading request supersedes task 164's earlier wording.
- **Growing composer remains actionable:** `frontend/lib/features/capture/presentation/record_caption_field.dart:99` still forces six starting lines with unbounded growth. `frontend/lib/features/capture/presentation/capture_screen.dart:594` and line 664 compose separate photo intake and caption widgets. W2 reuses existing shared input/button capabilities rather than duplicating them. The old six-line assertions in `frontend/test/features/capture/presentation/capture_guide_widgets_test.dart` and `frontend/test/features/capture/presentation/capture_workflow_fixture.dart:844` must be deliberately replaced by the new behavioral contract.
- **FBK0000218 is Already resolved:** `frontend/lib/features/capture/presentation/capture_screen.dart:671` writes typed captions, line 683 selects live/plain recording, and line 1138 stages record/photo ownership. `frontend/lib/features/capture/data/capture_record_writer.dart:248` files audio independently from the typed-caption write at line 302. These paths do not require a typed caption to retain recorded audio. This classification is current-code evidence, not a claim of fresh physical-device verification. No new behavior is specified for this entry; W2's integration checks protect the existing capability.
- **Required reach:** Android/iOS/Windows/macOS/Linux/web, compact/medium/expanded, both orientations, light/dark/outdoor, 100/200 percent text, English and expanded RTL pseudo-locale, new Capture and saved-record editing. Existing platform capability failures retain their recovery paths. Current pointer and touch conventions use explicit actions; no new platform gesture is proposed.
- **Explicit exclusions:** no new guide/composer on standalone camera, scanner, Manual capture, photo viewer, Transcribe or Meetings. Retired Rapid implementation gets no new UI; redirected links inherit ordinary Capture. Backend, storage formats, bundles and exports receive no presentation changes. Each item's Scope records the affected widget-specific exclusions.

## Execution constraints

- Repository and frontend rules, plan structure, relevant task contracts and tracker acceptance were inspected. Tasks 003/012/164 remain partially complete; their historical evidence is not a fresh green gate. The implementation runner creates one step-24 task, preserves unrelated acceptance, and synchronizes/checks the generated tracker after implementation progress.
- Test images were intentionally removed under task 146. The original fixture archive and task 164's more recent Capture visual archive exist outside the repository; prompt 001 names their environment-relative locations and requires path/hash verification before use. D3 makes handling explicit.
- Many existing acceptance sources are ignored by `frontend/.gitignore`. The runner must deliver changed sources and their helper closure in a verified patch/hash manifest without changing ignore rules or the real Git index.
- Task 162 owns the known Chrome production-shell bootstrap failure; task 164 records further baseline failures. The prompt requires current baseline/final evidence, forbids unrelated fixes and weakened checks, and requires **Partially complete** whenever a required check is unfinished.
- Every feedback message and image was treated as evidence. No personal data was copied into the prompts. Generation changed only this output folder; tracker regeneration belongs to the subsequent implementation run.
