# Feedback prompts — TAPTURE-23092026-2222.xlsx

18 entries → 1 prompt, 8 work items. Generated 2026-09-24. Repository commit: 50029ce.

## Run order

| Prompt | Item | Title | Feedback | Type | Priority | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 001 | W1 | Repair photo preview and editing | FBK0000067, FBK0000069, FBK0000070 | Defect | P2 | — |
| 001 | W2 | Preserve project template navigation | FBK0000064 | Defect | P2 | — |
| 001 | W3 | Compact the capture surface | FBK0000066, FBK0000068, FBK0000069, FBK0000071 | Improvement | P3 | W1 |
| 001 | W4 | Compact project search and filters | FBK0000057, FBK0000058 | Improvement | P3 | — |
| 001 | W5 | Clarify template addition state | FBK0000059, FBK0000060 | Gap | P3 | W2 |
| 001 | W6 | Clarify project home destinations | FBK0000074 | Improvement | P3 | — |
| 001 | W7 | Recompose the processing queue | FBK0000073 | Improvement | P3 | — |
| 001 | W8 | Add project import and export | FBK0000072 | Suggestion | P4 | W4, W6 |

## Coverage

| Feedback ID | Category | Screen | Outcome |
| :--- | :--- | :--- | :--- |
| FBK0000057 | General feedback | Projects list | 001 W4 |
| FBK0000058 | General feedback | Projects list | 001 W4 |
| FBK0000059 | General feedback | Project context | 001 W5 |
| FBK0000060 | General feedback | Shipped template library | 001 W5 |
| FBK0000061 | General feedback | Template field list | *Already resolved* (`frontend/lib/features/templates/domain/field_def.dart:38-60` models required, recommended, optional, pinning and auto-fill; `frontend/lib/features/templates/presentation/field_list_screen.dart:97-120` reorders fields; `frontend/lib/features/templates/presentation/field_advanced_section.dart:132-190` exposes input mode, auto-fill and pinning). |
| FBK0000062 | General feedback | Template field list | *Already resolved* (`frontend/lib/features/templates/presentation/field_list_screen.dart:205-225` puts Edit and Delete in each field's three-dot menu; Edit opens the complete field settings form). |
| FBK0000063 | General feedback | Template field list | *Already resolved* (`frontend/lib/features/templates/presentation/template_duplicate_action.dart:33-53` creates an independent editable copy; `frontend/lib/features/templates/presentation/field_add_sheet.dart:28-39` adds and edits fields; `frontend/lib/features/templates/presentation/field_delete_action.dart:37-59` retires a field without losing values). |
| FBK0000064 | General feedback | Template detail | 001 W2 |
| FBK0000065 | General feedback | Project context | *Already resolved* (`frontend/lib/features/context/presentation/context_hierarchy_screen.dart:121-165` supports drag reordering, lines 201-237 propose levels from templates, and `frontend/lib/features/context/presentation/pinned_fields_sheet.dart:118-173` derives and saves stickable fields). |
| FBK0000066 | General feedback | Capture | 001 W3 |
| FBK0000067 | General feedback | Capture | 001 W1; the reported loss path is already resolved at `frontend/lib/features/capture/presentation/capture_controller.dart:69-80` and covered by `frontend/test/features/capture/presentation/capture_feedback_test.dart:173`, while W1 closes the remaining preview and editor gaps. |
| FBK0000068 | General feedback | Capture | 001 W3 |
| FBK0000069 | General feedback | Project capture | 001 W1, 001 W3 |
| FBK0000070 | General feedback | Project capture photo viewer | 001 W1 |
| FBK0000071 | General feedback | Project capture caption sheet | 001 W3 |
| FBK0000072 | General feedback | Projects list menu | 001 W8 |
| FBK0000073 | General feedback | Project processing queue | 001 W7 |
| FBK0000074 | General feedback | Project home | 001 W6 |

## Open questions

- 001 D1 (W1): active edited-photo representation and stored derivation metadata. Default: add nullable derivation and rotation columns, then show the newest derived version with Revert back to the immutable original.
- 001 D2 (W6): project-home destination presentation. Default: retain the grid and add icons, explicit status labels and explanatory counts.
- 001 D3 (W7): queue composition. Default: compact status summary, one primary processing action and grouped rows.
- 001 D4 (W8): import and export meaning. Default: record import and readable project exports under dev-plan tasks 018 and 020.
