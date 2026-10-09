# Feedback prompts — TAPTURE-09102026-2007.xlsx

3 entries → 1 prompt, 3 work items. Generated 2026-10-09. Repository commit: `1bf79f80` (`main`).

## Run order

| Prompt | Item | Title | Feedback | Type | Priority | After |
| --- | --- | --- | --- | --- | --- | --- |
| [001](001-resolve-capture-guidance-feedback.md) | W1 | Retire automatic context confirmation | FBK0000212 | Improvement | P2 | — |
| 001 | W2 | Show each Capture hint once | FBK0000210, FBK0000211 | Defect | P3 | W1 |
| 001 | W3 | Retain complete template guidance | FBK0000210 | Gap | P5 | W2 |

## Coverage

| Feedback ID | Category | Screen | Outcome |
| --- | --- | --- | --- |
| FBK0000210 | General feedback | Global Capture | `001 W2` removes the guide action and places hints; `001 W3` retains complete eligible template guidance. Classification: Improvement. |
| FBK0000211 | General feedback | Project Capture | `001 W2` removes the duplicate caption list and renders it only above the input. Classification: Defect. |
| FBK0000212 | General feedback | Project Capture | `001 W1` retires the shell-wide movement question, its polling and its settings controls. Classification: Improvement. |

## Open questions

All implementation decisions are in [001 — Decisions](001-resolve-capture-guidance-feedback.md#decisions). None is approved by prompt generation; “Proceed” during implementation selects all defaults.

| Prompt / Decision | Question | Default |
| --- | --- | --- |
| 001 D1 | Retire movement confirmation throughout the shared shell? | (a) Remove dialog/polling/controls; retain inert legacy preference values and idle auto-clear. |
| 001 D2 | Keep each hint visible without another control? | (a) Always show the two non-dismissible hints in their respective locations; remove toggle/dismissal state. |
| 001 D3 | Resolve complete guidance versus the six-field limit? | (a) Retain all existing eligible identity/barcode and required/recommended labels without a cap. |
| 001 D4 | Run this scoped task before unfinished earlier acceptance? | (a) Bounded execution-order exception, no verification waivers; archive/hash-verify owned images before exact temporary cleanup. |

No separate reporter clarification is required to prepare this prompt. Alternative decision answers require revising the affected implementation instructions before work starts.

## Inventory and source checks

All three entries were read from the workbook's Feedback sheet; all three full-size PNGs were visually inspected. Screenshots-sheet rows match the same IDs. Common metadata: Android mobile, app 1.0.0, production, English, compact portrait, light, text scale 1, online; viewport 393×886 logical pixels at 2.75 density and display 393×886. Names, project identifiers, account fields, device identifiers, network addresses and user agents are omitted; project routes below are patterns.

| Feedback ID | Submitted at (EAT), 2026-10-09 | Route / route name | Report and image evidence | Current source |
| --- | --- | --- | --- | --- |
| FBK0000210 | 19:59:52 | `/capture` / `capture` | Remove “What to capture”; retain concise active-template hints covering required/important information. Image shows the action above expanded photo and caption guidance. | `frontend/lib/features/capture/presentation/capture_guide_card.dart:31` retains the toggle; `frontend/lib/features/templates/domain/capture_guide.dart:56` and `:59` truncate lists to six. |
| FBK0000211 | 20:02:27 | `/projects/:projectId/capture` / `capture` | Keep caption hints only above the input. Image shows the same caption guidance both near the top and in the focused-caption panel. | `frontend/lib/features/capture/presentation/capture_screen.dart:550` and `:671` mount both components; `frontend/lib/features/capture/presentation/record_caption_field.dart:140` has a second renderer. |
| FBK0000212 | 20:04:48 | `/projects/:projectId/capture` / `capture` | Remove the context-confirmation dialog. Image shows the movement question covering the Capture workspace. | `frontend/lib/features/context/presentation/context_maintenance.dart:299` opens the dialog; `frontend/lib/app/nav_shell.dart:82` mounts the host across shell destinations. |

The source checks confirm that none of these entries is already resolved at the recorded commit. W2 groups FBK0000210/FBK0000211 only for their shared guidance-presentation flow; W3 separates the independent derivation limit. W1 addresses a separate timer/location/settings flow. There is no split reason: all work targets this repository and can be specified together.

Existing verification debt remains explicit: task 158 is Partially complete; tasks 159–162 own the hierarchy, archived-choice, protected-field and Chrome-bootstrap findings. These are neither newly resolved by this prompt nor permission to waive affected acceptance.

Prompt generation changes only this output folder. It does not modify application code, tests, plan progress or the tracker; tracker synchronization is required when the generated implementation task is actually started/updated.
