# Feedback prompts — TAPTURE-18092026-1958.xlsx

1 entry → 4 prompts. Generated 2026-09-18. Repository commit: a656263.

## Run order
| Prompt | Title | Feedback | Type | Priority | Depends on |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 001 | Enable AppDatabase on web | FBK0000003 | Defect | P1 | — |
| 002 | Fix storage settings on web | FBK0000003 | Defect | P1 | 001 |
| 003 | Dock feedback panel beside app | FBK0000003 | Defect | P3 | — |
| 004 | Rename More nav to Settings | FBK0000003 | Improvement | P5 | — |

## Coverage
| Feedback ID | Category | Screen | Outcome |
| :--- | :--- | :--- | :--- |
| FBK0000003 | Error in the app | Operator | 001, 002, 003, 004 |

## Open questions
- 001: persist the web database with Drift's wasm worker and `sqlite3.wasm` (recommended), or an in-memory database that dies on reload?
- 002: on web, show storage usage as empty (no `dart:io` tree) while retention still saves through the store, or build a full web file tree?
- 004: change only the visible label (recommended), or also rename `/more` routes to `/settings`?
