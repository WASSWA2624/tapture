# Feedback prompts — TAPTURE-23092026-1635.xlsx

14 entries → 1 prompt, 9 work items. Generated 2026-09-23. Repository commit: `cfd9429`.

## Run order

| Prompt | Item | Title | Feedback | Type | Priority | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 001 | W1 | Wire durable capture saves | FBK0000054 | Defect | P1 | — |
| 001 | W2 | Fix shell hierarchy and back navigation | FBK0000043, FBK0000047, FBK0000048, FBK0000052 | Defect | P2 | W1 |
| 001 | W3 | Apply template context levels and pins | FBK0000048, FBK0000049, FBK0000050 | Defect | P2 | W1, W2 |
| 001 | W4 | Add reusable project search and filters | FBK0000044 | Gap | P3 | W3 |
| 001 | W5 | Mark pinned projects in the list | FBK0000045 | Improvement | P3 | W4 |
| 001 | W6 | Show project association counts | FBK0000046 | Improvement | P3 | W3, W5 |
| 001 | W7 | Compact the Settings index | FBK0000056 | Improvement | P3 | W2, W6 |
| 001 | W8 | Attach audio evidence to capture | FBK0000054 | Suggestion | P4 | W1, W3 |
| 001 | W9 | Build registry-driven AI settings | FBK0000055 | Suggestion | P4 | W7 |

## Coverage

| Feedback ID | Category | Screen | Outcome |
| :--- | :--- | :--- | :--- |
| FBK0000043 | General feedback | Projects and root shell | 001 W2 |
| FBK0000044 | General feedback | Projects | 001 W4 |
| FBK0000045 | General feedback | Projects | 001 W5 |
| FBK0000046 | General feedback | Project home | 001 W6; left alignment is already present at `frontend/lib/features/projects/presentation/project_home_screen.dart:141` and `:157` |
| FBK0000047 | General feedback | Project home | 001 W2 |
| FBK0000048 | General feedback | Context | 001 W2, 001 W3 |
| FBK0000049 | General feedback | Context | 001 W3 |
| FBK0000050 | General feedback | Context | 001 W3; pin persistence already passes at `frontend/test/features/context/presentation/context_screens_test.dart:359` |
| FBK0000051 | General feedback | Templates | *Already resolved* (`frontend/lib/features/templates/presentation/template_list_screen.dart:52` renders every project template; `frontend/test/features/templates/presentation/template_list_screen_test.dart:109` verifies two templates and their actions) |
| FBK0000052 | General feedback | Settings and Back | 001 W2 |
| FBK0000053 | General feedback | Capture | *Duplicate of FBK0000054* |
| FBK0000054 | General feedback | Capture | 001 W1, 001 W8 |
| FBK0000055 | General feedback | Settings | 001 W9 |
| FBK0000056 | General feedback | Settings | 001 W7 |

## Open questions

- 001 D1: use `Save and process` or the exact phrase `Save processes`. Default: `Save and process`.
- 001 D2: store interrupted sessions in additive Drift schema v17 or native JSON with no browser recovery. Default: Drift schema v17.
- 001 D3: approve `record: ^7.1.1` plus additive attachment ownership, or support imported audio only. Default: approve the recorder and ownership table.
- 001 D4: use a registry-fed organisation catalog or arbitrary user-entered provider endpoints. Default: registry-fed catalog with backend custody.
- 001 D5: remove duplicate and inactive Settings rows from the index or retain them with grouping. Default: remove them from the index while preserving routes.
