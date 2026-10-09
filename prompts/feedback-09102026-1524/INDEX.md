# Feedback prompts — TAPTURE-09102026-1524.xlsx

3 entries → 1 prompt, 4 work items. Generated 2026-10-09. Repository commit: `0a51ed74`.

The repository was accessible. All three Feedback rows, all three external screenshots, the Screenshots sheet and the export filter/counts were inspected. Current-source evidence is cited below; existing test bodies were inspected, not freshly executed. This generation changes only this output folder and does not implement the proposed work, approve its decisions, modify the plan and certify application verification.

## Run order

| Prompt | Item | Title | Feedback | Type | Priority | After |
| --- | --- | --- | --- | --- | --- | --- |
| [001](001-resolve-capture-setup-feedback.md) | W1 | Expose the existing searchable choice sheet | FBK0000207 | Improvement | P4 | — |
| 001 | W2 | Add reusable primary and secondary header text | FBK0000208 | Improvement | P4 | — |
| 001 | W3 | Move Capture target selection into overflow | FBK0000207, FBK0000208 | Improvement | P5 | W1, W2 |
| 001 | W4 | Move Capture context values into overflow | FBK0000207 | Improvement | P5 | W3 |

One prompt covers the archive. Shared picker/header work precedes the two independent Capture placement changes. No split condition applies.

## Coverage

| Feedback ID | Category | Screen | Outcome |
| --- | --- | --- | --- |
| FBK0000207 | General feedback | Capture | Improvement: 001 W1, W3, W4. Move context and target selectors into overflow; preserve their existing behavior. |
| FBK0000208 | General feedback | Capture | Improvement: 001 W2, W3. Use project name as primary header text and selected template as secondary text. |
| FBK0000209 | General feedback | Capture | *Already resolved*: level/pin chips already open editable pickers (`frontend/lib/features/context/presentation/context_bar.dart:220`, `:287`); current value is prefilled (`context_picker_sheet.dart:108`), committed through the existing repository/cascade path (`:238`, `:269`, `:304`), and pins share it (`pinned_fields_sheet.dart:44`). Existing behavioral test bodies cover two-tap recent selection (`frontend/test/features/context/presentation/context_screens_test.dart:234`), no-op current selection (`:279`) and recent/dataset/free-text/failure paths (`:318`). No independent implementation is generated for this entry. W4 must preserve this capability while relocating its entry point. |

## Inventory

Every entry was seen at `/capture`, route name `capture`, on Android mobile in production, app 1.0.0, locale `en`, compact portrait, light theme, 100 percent text, viewport 393×886 at 2.75 device scale, display 393×886, online. These observations describe the reporting surface, not the implementation limit. Identity, device-ID, IP and user-agent columns are deliberately excluded.

| Feedback ID | Message paraphrase | Image inspected | Image evidence |
| --- | --- | --- | --- |
| FBK0000207 | Put context, project selection and template selection behind the three-dot menu to free Capture space. | `prompts/TAPTURE-09102026-1524/screenshots/FBK0000207.png` | Overflow is open with Manual form and Import document; context trails and two target selectors remain in the body above guidance, photo/caption controls and both save actions. |
| FBK0000208 | Identify the active project in the Capture title and show the template with less emphasis. | `prompts/TAPTURE-09102026-1524/screenshots/FBK0000208.png` | The header says Capture; the project/template names appear in selectors below two context trails. Menu is closed. |
| FBK0000209 | Make existing context values easy to change. | `prompts/TAPTURE-09102026-1524/screenshots/FBK0000209.png` | The same Capture composition shows unset context-level chips and pinned-field chips; no failed edit, disabled picker and persistence error is shown. Source inspection confirms that the chips already open editable pickers. |

The export declares three records and three screenshots, with category/platform/device/screen filters set to All, screenshot filter Any, no search and no date restriction. Counts match the workbook rows and external images. All reports are accounted for; no duplicate, out-of-scope entry and reporter clarification is required.

## Reach and ownership

- Shared Dart causes apply to Android, iOS, web, Windows, macOS and Linux; layout verification covers compact/medium/expanded, both orientations, light/dark/outdoor and 100/200 percent text, with narrow/keyboard, pseudo-locale and RTL cases.
- Relocation applies to the Capture branch's new-record routes `/capture` and `/projects/:projectId/capture`. Other branches retain their context bar. Saved-record Capture edit routes retain their existing title and locked project/template/context ownership; reassigning saved evidence is outside these reports.
- W1 reuses the current searchable choice-sheet body. W2 extends existing page-to-shell publication. W3 preserves target resolution and durable per-project sessions. W4 delegates value writes to current context/pin pickers and repositories; it adds no second editing engine.
- The runner records one new archive task in step 24. Existing tasks 003/006/011/012/153 remain partially complete where their unrelated verification is open. Approved presentation supersessions update stable owning contracts without transferring old completion claims.
- Tasks 146/155/157 require preservation of external image evidence, zero delivered test PNGs, unchanged test ignore policy and reviewable delivery of ignored acceptance sources. The prompt explicitly carries those requirements forward.

## Open questions

- **001 D1 — Presentation supersession.** Default (a): relocate all three setup controls on every new-Capture surface, use the project/template title hierarchy and keep saved-record targets locked. This changes Capture's context access budget, preserving the normal shutter/save path and other screens' context behavior. Alternative (b) retains the current layout and leaves the two actionable reports unresolved.
- **001 D2 — Additive shared contracts.** Default (a): expose the existing choice-sheet presenter and add optional header title/detail publication plus one shared renderer, preserving existing callers. Alternative (b) keeps current APIs and leaves dependent work unimplemented.

No decision is requested during prompt generation. The implementation runner must obtain answers before W1; no code or plan work has begun under this prompt.
