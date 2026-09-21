# Feedback prompts — TAPTURE-21092026-2146.xlsx, TAPTURE-21092026-2151.xlsx

10 entries → 9 prompts. Generated 2026-09-21. Repository commit: 2ed33ff.

Both archives are in this folder. Prompt order follows submission time. Entries that share a root cause sit on the earliest entry. Nothing outside this folder was changed.

## Run order
| Prompt | Title | Feedback | Type | Priority | Depends on |
| :--- | :--- | :--- | :--- | :--- | :--- |
| [001](001-remove-overflow-menu-border.md) | Remove overflow menu border | FBK0000020, FBK0000006 | Defect | P3 | — |
| [002](002-show-back-and-screen-title.md) | Show back and screen title | FBK0000020, FBK0000021, FBK0000006, FBK0000028 | Improvement | P3 | 001 |
| [003](003-space-page-actions.md) | Space page actions | FBK0000022, FBK0000023 | Defect | P4 | — |
| [004](004-keep-one-create-project.md) | Keep one create project | FBK0000022, FBK0000024 | Improvement | P4 | — |
| [005](005-remove-projects-nav-count.md) | Remove projects nav count | FBK0000025, FBK0000006 | Improvement | P4 | — |
| [006](006-show-storage-totals.md) | Show storage totals | FBK0000026 | Gap | P4 | — |
| [007](007-set-storage-root-path.md) | Set storage root path | FBK0000026 | Gap | P5 | 006 |
| [008](008-restore-last-route.md) | Restore last route | FBK0000027 | Gap | P3 | — |
| [009](009-clip-project-list-pane.md) | Clip project list pane | FBK0000006 | Defect | P3 | — |

## Coverage
| Feedback ID | Category | Screen | Outcome |
| :--- | :--- | :--- | :--- |
| FBK0000020 | General feedback | Projects | 001, 002. List numbering already resolved (`frontend/lib/features/projects/presentation/project_list_view.dart:59`). Border stroke is already the hairline (`frontend/lib/app/theme/app_theme.dart:381`); 001 removes the More box that makes it look heavy. |
| FBK0000021 | General feedback | Records | 002 |
| FBK0000022 | General feedback | Projects | 003, 004. No separate redesign: the screenshot is the same Projects list, and a broader visual pass was not specified. |
| FBK0000023 | General feedback | Projects | 003 |
| FBK0000024 | General feedback | Projects | 004 |
| FBK0000025 | General feedback | Projects | 005 |
| FBK0000026 | General feedback | Storage | 006, 007 |
| FBK0000027 | General feedback | Projects | 008 |
| FBK0000006 | General feedback | Projects | 001, 002, 005, 009 |
| FBK0000028 | General feedback | Projects | 002 |

## Open questions
- 002: On root routes, keep the status menu (recommendation) or remove it on every screen.
- 003 / 004: FBK0000023 keeps the title-row add control; FBK0000024 and FE-SIMP-01 point at a single lower primary. 004 asks which create control remains. Recommendation: footer on compact and medium, pane button on expanded.
- 005: Remove the Projects badge added in task 328 (recommendation), or keep it for assistive tech only.
- 007: The path in FBK0000026 is the storage root (recommendation), not a separate export folder. This prompt saves the folder and does not move existing files.
- 008: Restore the last route (recommendation). Scroll position and unsaved text stay out of scope.
- FBK0000022 does not block a prompt. Anything beyond 003 and 004 needs a behaviour named on its own.
