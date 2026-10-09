# Feedback prompts — TAPTURE-09102026-2154.xlsx

3 entries → 1 prompt, 3 work items. Generated 2026-10-09. Repository commit: `5b289cc2`.

Read all three Feedback rows, all three Screenshots rows, the Export Details sheet and all three full-size PNGs. Export Details reports 3 records and 3 screenshots, with no category/platform/device/screen restriction. Every entry is actionable and still represented in the current source; none is a duplicate, already resolved, out of scope or awaiting the reporter.

All reports were seen in Capture on Android mobile, app 1.0.0, production, locale `en`, compact portrait, light theme, text scale 1, online. Viewport: 393×886 logical pixels at 2.75× density; display: 393×886. Normalized screen: Projects › [project] › Capture. Normalized route: `/projects/:projectId/capture`; route name: `capture`; Page URL: absent. Project names/identifiers, account details, device identifiers, addresses and user-agent values are intentionally omitted. The observed platform is a sample; the implementation prompt carries shared changes to every applicable supported surface.

Source analysis covered the root instructions, all frontend rule files, the plan's task/dependency index, owning context/capture/design-system contracts and acceptance, previous guidance decisions, tracker, current router/shell, settings, localization, guide derivation, widgets, caption persistence and relevant tests. No backend work is required.

## Run order
| Prompt | Item | Title | Feedback | Type | Priority | After |
| --- | --- | --- | --- | --- | --- | --- |
| [001](001-resolve-capture-guidance-feedback.md) | W1 | Remove the movement confirmation | FBK0000213 | Improvement | P2 | — |
| [001](001-resolve-capture-guidance-feedback.md) | W2 | Label the photo-caption save action | FBK0000215 | Improvement | P3 | — |
| [001](001-resolve-capture-guidance-feedback.md) | W3 | Show photo guidance without a toggle | FBK0000214 | Improvement | P3 | 001 W2 |

One prompt covers this archive; no split reason applies. The entries share a screen but have distinct causes, so they retain separate work items.

## Coverage
| Feedback ID | Category | Screen | Outcome |
| --- | --- | --- | --- |
| FBK0000215 | General feedback | Capture | **001 W2 — Improvement.** Clarify the action that saves a caption to photos. The image shows one photo, Caption entry and an "Add to the photo" button. Current evidence: `frontend/lib/features/capture/presentation/capture_screen.dart:721`, `frontend/lib/core/copy/l10n/app_en.arb:4163`. |
| FBK0000214 | General feedback | Capture | **001 W3 — Improvement.** Replace the guide toggle with direct photo-content guidance. The image shows the toggle, photo/caption lists and a second caption-help panel. Current evidence: `frontend/lib/features/capture/presentation/capture_guide_card.dart:33`, `frontend/lib/features/capture/presentation/capture_screen.dart:677`. |
| FBK0000213 | General feedback | Capture | **001 W1 — Improvement.** Remove the movement confirmation. The image shows the modal covering Capture. Current evidence: `frontend/lib/features/context/presentation/context_maintenance.dart:251`, `frontend/lib/app/nav_shell.dart:82`. |

## Open questions
- **001 D1 (W1):** Retire the movement reminder and its controls application-wide, retaining stored keys as inert compatibility data, versus suppressing it only on Capture/edit routes. **Default: (a), application-wide retirement.** This removes an existing optional feature/settings surface and stops its location activity; execution requires the decision before implementation.
- **001 D2 (W3):** Remove both caption-guidance presentations versus retaining the contextual caption-help panel while simplifying the top guideline. **Default: (a), a single photo guideline and no caption-help panel.** The existing task 076 D14 contract explicitly provided both presentations, so the approved supersession must be recorded.
- **001 D3 (W2/W3):** Allow narrowly scoped temporary visual PNGs with verified external archiving and exact cleanup versus deferring visual acceptance. **Default: (a), scoped temporary visual verification following tasks 146/157.** No delivered test PNGs, broad restoration, ignore-policy change or guardrail change is authorized.

There are no additional reporter questions. "Proceed" when executing prompt 001 selects all three defaults; generating these files does not approve them.

Known verification limits are carried into the prompt: task 146 removed test images; tests are ignored locally and need an explicit acceptance-source patch/manifest; task 162 records a pre-existing Windows Chrome production-shell startup failure; task 150 owns separate guardrail gaps. Required checks remain open when blocked. No application tests, builds, baseline generations or tracker updates were run during this prompt-only generation.

Only this output folder was written. Application code, tests, plan, specification, tracker, source workbook/screenshots and the user's existing deletions were preserved.
