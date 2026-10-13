# Feedback prompts — TAPTURE-13102026-0919.xlsx

4 entries → 1 prompt, 3 work items. Generated 2026-10-13 (Africa/Kampala). Repository commit: `b9258cc6`.

**Maintenance note (2026-10-13):** The user subsequently retired the development plan, tracker and one-off task
helpers. References to that tooling below and in the already-run prompt are historical; current repository rules and
scope-specific verification apply. D1(a) and D2(a) were approved, and the UI changes landed. Required acceptance remains
partially complete because the recorded test failures and remaining visual/runtime checks are unresolved. Acceptance
sources are preserved in `acceptance-sources.patch` with `acceptance-sources.manifest.json`; restored/generated test
images were verified, archived outside the repository and removed from the test tree.

All four Feedback rows and all four screenshot files were inspected. Three entries are Improvements with current code evidence; one is a Question. No duplicates, out-of-scope entries or already-resolved reports were identified. The workbook's Export Details reports four records and four screenshots; its filters include all categories, platforms, devices and screens, with no search/date restriction. Only this output folder was written during generation; application code, tests, plan, tracker and source archive were not edited.

## Run order

| Prompt | Item | Title | Feedback | Type | Priority | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| [001](001-resolve-capture-record-controls-feedback.md) | W1 | Fill and equalize shared selection commands | FBK0000222 | Improvement | P4 | — |
| [001](001-resolve-capture-record-controls-feedback.md) | W2 | Remove record-row action outlines | FBK0000221 | Improvement | P5 | W1 |
| [001](001-resolve-capture-record-controls-feedback.md) | W3 | Remove passive Capture photo guidance | FBK0000220 | Improvement | P5 | W2 |

One prompt covers all actionable feedback. Shared selection composition precedes screen changes; the two P5 items have equal coverage and the smaller row change runs first. No section 3, step 6 split condition applies. Decisions belong to the future implementation runner; generation grants no implementation approval.

## Coverage

| Feedback ID | Category | Screen | Outcome |
| :--- | :--- | :--- | :--- |
| FBK0000220 | General feedback | Projects › project › Capture | 001 W3 — Improvement. Passive photo-guidance card still renders at `frontend/lib/features/capture/presentation/capture_screen.dart:525`; removal requires D1. |
| FBK0000221 | General feedback | Projects › project › Records | 001 W2 — Improvement. `RecordsListRow` edit/delete retain outlines at `frontend/lib/features/records/presentation/records_list_row.dart:213` and `frontend/lib/features/records/presentation/record_delete_action.dart:88`. The separate already-borderless `CapturedRecordTile` does not serve the reported route. |
| FBK0000222 | General feedback | Projects › project › Records | 001 W1 — Improvement. Shared selection buttons have equal allocated slots but unequal painted widths and outlined text treatment at `frontend/lib/core/widgets/fields/app_multi_choice_field.dart:159`. |
| FBK0000223 | General feedback | Projects › project › Records | Needs clarification — Question: does the request target the pictured record-detail screen or the recorded values-editor route, and which concrete visual change is wanted? No redesign is specified. |

## Inventory

All reports were seen on Android/mobile, production app 1.0.0, locale `en`, compact portrait, light theme and text scale 1.0. Viewport: 393×886 at 2.75x density; display: 393×886. Each has one PNG. These are observed samples, not the fixes' reach. Project/record identifiers and names are replaced with route placeholders and generic screen labels; personal fields and device-identifying OS/build strings are omitted.

| Entry | Route / route name | Connectivity | Message paraphrase | Screenshot observation |
| :--- | :--- | :--- | :--- | :--- |
| FBK0000220 | `/projects/:projectId/capture` · `capture` | Metered | Remove the passive Photos should show component completely. | Camera guidance card sits above the empty photo tray and caption/photo/voice/audio composer; both save actions remain below. |
| FBK0000221 | `/projects/:projectId/records` · `project` | Online | Remove outlines from record edit/delete buttons. | Records search and one record row with thumbnail/status show two separately outlined trailing action icons. |
| FBK0000222 | `/projects/:projectId/records` · `project` | Online | Make Select all/Clear equally wide horizontally and filled. | Status multi-choice sheet displays search, unequal outlined action buttons and a status option; list remains behind the sheet. |
| FBK0000223 | `/projects/:projectId/records/:recordId/values` · `project` | Online | Improve the pictured UI; no particular change is named. | Read-only detail composition shows record status, approval/review actions, photos, caption, field rows/edit and photo/caption edit footer. It does not show the values form associated with the recorded route. |

Current route mapping: `frontend/lib/app/router.dart:632` selects `RecordsListScreen`; line 1261 selects `RecordDetailScreen`; line 1282 selects `RecordEditScreen` for `/values`. The last report's screenshot matches `frontend/lib/features/records/presentation/record_detail_screen.dart:478` onward, while `frontend/lib/features/records/presentation/record_edit_screen.dart:63` supplies the separate values editor. The mismatch is evidence of ambiguity, not proof of a routing defect. No arbitrary spacing, palette, action or field redesign is added.

## Open questions

- **001 D1, W3:** approve removal of passive Capture guidance across new/saved Capture and the bounded specification/task supersession. Default **(a)** removes the internal presentation while preserving template data, retained domain/copy APIs and all evidence behaviour. **(b)** retains the card and leaves FBK0000220 open.
- **001 D2, W1–W3:** approve verified temporary golden restoration, intended regeneration, external archival and exact temporary-image cleanup under the existing zero-test-image policy. Default **(a)** performs that workflow. **(b)** leaves visual acceptance open and reports Partially complete. No rule/checker/ignore-policy change is authorized.
- **FBK0000223:** identify the target screen (record detail shown in the screenshot; values editor recorded in metadata) and the specific change to layout, spacing, action treatment or information presentation. There is no recommended visual redesign because the report supplies no measurable intent. This question does not block W1–W3.

Current plan cautions: task 003 and task 012 retain independent acceptance gaps; task 165 remains Partially complete and its guide presence is historical once D1 lands. Task 169 records compilation/provenance work; task 162 records unstarted/failed Chrome acceptance. Their current status must be rechecked by the runner. Historical prompt folders referenced by tasks 164/165 are absent; the generated prompt uses extant plan/source paths. Test sources often remain ignored locally, so the prompt requires portable source/hash delivery and preserved visual evidence, plus automatic tracker regeneration and checking after implementation.
