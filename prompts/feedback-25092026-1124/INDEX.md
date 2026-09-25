# Feedback prompts — TAPTURE-25092026-1124.xlsx

14 entries → 1 prompt, 12 work items. Generated 25 September 2026. Repository commit: ccf96ac.

## Run order

| Prompt | Item | Title | Feedback | Type | Priority | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 001 | W1 | Record audio to a playable WAV file | FBK0000129 | Defect | P2 | — |
| 001 | W2 | Remove the doubled top inset in the shell | FBK0000120, FBK0000128 | Defect | P3 | — |
| 001 | W3 | Let full-width buttons fill their slot | FBK0000127, FBK0000119 | Defect | P3 | — |
| 001 | W4 | Group the shipped library into real categories | FBK0000121, FBK0000122 | Defect | P3 | — |
| 001 | W5 | Draw one handle on a sheet sized to its content | FBK0000131 | Defect | P3 | — |
| 001 | W6 | Edit every template field on a captured item | FBK0000131 | Defect | P3 | W5 |
| 001 | W7 | Merge the template add actions | FBK0000123, FBK0000124, FBK0000119 | Improvement | P5 | W3 |
| 001 | W8 | Move pinned fields and contexts into the project menu | FBK0000117 | Improvement | P5 | — |
| 001 | W9 | Unframe the home template list and inset the home | FBK0000126 | Improvement | P5 | W8 |
| 001 | W10 | Pin the project search at the top | FBK0000118 | Improvement | P5 | W2, W9 |
| 001 | W11 | Switch project and template on capture | FBK0000130 | Gap | P5 | W5 |
| 001 | W12 | Space the capture page | FBK0000128 | Improvement | P5 | W2, W3, W11 |

## Coverage

| Feedback ID | Category | Screen | Outcome |
| :--- | :--- | :--- | :--- |
| FBK0000117 | General feedback | Projects › Testing | 001 W8 |
| FBK0000118 | General feedback | Projects › Testing | 001 W10 |
| FBK0000119 | General feedback | Projects › Testing › Templates | 001 W3, 001 W7 |
| FBK0000120 | General feedback | Projects › Testing › Templates | 001 W2 |
| FBK0000121 | General feedback | Projects › Testing › Templates | 001 W4 |
| FBK0000122 | General feedback | Projects › Testing › Templates | 001 W4 |
| FBK0000123 | General feedback | Projects › Testing › Templates | 001 W7 |
| FBK0000124 | General feedback | Projects › Testing › Templates | 001 W7 |
| FBK0000126 | General feedback | Projects › Testing | 001 W9 |
| FBK0000127 | General feedback | Projects › Testing › Capture | 001 W3 |
| FBK0000128 | General feedback | Projects › Testing › Capture | 001 W2, 001 W12 |
| FBK0000129 | General feedback | Projects › Testing › Capture | 001 W1 |
| FBK0000130 | General feedback | Capture | 001 W11 |
| FBK0000131 | General feedback | Projects › Testing | 001 W5, 001 W6 |

## Open questions

- 001 D1, default (a): record audio in the plugin's file mode to a staging file, publish it with `FileWriter.copyIn`, and delete the staging file only after the copy succeeds.
- 001 D2, default (a): group the 23 shipped templates into seven categories held in a pure-Dart map. Shipped assets and the template checker stay as they are.
- 001 D3, default (a): remove the unlabelled kind filter and its "add every template of a kind" behaviour. Categories head the list, and search matches template and category names.
- 001 D4, default (a): editing a field that has no stored row inserts it with the typed text as `valueRaw` and source `TYPED`. Later edits write `valueRefined`.
- 001 D5, default (a): capture shows Project and Template as choice fields that always open a searchable sheet. `TemplatePickerSheet` and its two tests are deleted.
- 001 D6, default (a): capture gets 16dp gaps, an `AppEmptyState` for the empty photo tray, and an audio status block that stays hidden while idle.
- Noticed, not reported: in `screenshots/FBK0000131.png` the captured item's thumbnail shows "Missing photo". No entry asks about it, so no work item covers it. `CapturedItemTile` passes the photo's `relative_path` as `PhotoAsset.thumbPath`. Raise a task with `dart run tool/new_task.dart` if it should be fixed.
- No entry needs the reporter.
