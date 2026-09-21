# Feedback prompts — TAPTURE-21092026-2146.xlsx, TAPTURE-21092026-2151.xlsx

10 entries → 10 prompts, 7 open work items. Generated 2026-09-21. Repository commit: 3c36d9d.

`001` and `002` already ran (`7a07fa3`, `54f70e4`). `003` through `009` are the previous draft of the same remaining work. Do not run them. Run `010`.

## Run order
| Prompt | Item | Title | Feedback | Type | Priority | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 001 | — | Remove overflow menu border | FBK0000020, FBK0000006 | Defect | P3 | already ran |
| 002 | — | Show back and screen title | FBK0000020, FBK0000021, FBK0000006, FBK0000028 | Improvement | P3 | already ran |
| [010](010-resolve-projects-shell-feedback.md) | W1 | Clip the project list pane | FBK0000006 | Defect | P3 | — |
| 010 | W2 | Space page actions | FBK0000022, FBK0000023 | Defect | P4 | — |
| 010 | W3 | Keep one create control | FBK0000022, FBK0000024 | Improvement | P5 | — |
| 010 | W4 | Remove the projects nav count | FBK0000025, FBK0000006 | Improvement | P5 | — |
| 010 | W5 | Show storage volume totals | FBK0000026 | Gap | P5 | — |
| 010 | W6 | Set the storage root path | FBK0000026 | Gap | P5 | W5 |
| 010 | W7 | Restore the last route | FBK0000027 | Gap | P5 | — |

## Split reasons
None. `010` is the one prompt for the work that is still open. `003`–`009` are not a second pass.

## Coverage
| Feedback ID | Category | Screen | Outcome |
| :--- | :--- | :--- | :--- |
| FBK0000020 | General feedback | Projects | Already resolved. Numbering: `frontend/lib/features/projects/presentation/project_list_view.dart:59`. Borderless More: `frontend/lib/core/widgets/app_overflow_menu.dart:19` (`7a07fa3`). Back and screen title: `frontend/lib/app/widgets/status_line.dart:108` (`54f70e4`). Outline stroke stays the hairline at `frontend/lib/app/theme/app_theme.dart:381`. |
| FBK0000021 | General feedback | Records | Already resolved (`frontend/lib/app/widgets/status_line.dart:108`, `54f70e4`). |
| FBK0000022 | General feedback | Projects | 010 W2, 010 W3. No separate redesign: the screenshot is the same Projects list. |
| FBK0000023 | General feedback | Projects | 010 W2. W3, per D1, removes the title-row add that sat against the more control. |
| FBK0000024 | General feedback | Projects | 010 W3 |
| FBK0000025 | General feedback | Projects | 010 W4 |
| FBK0000026 | General feedback | Storage | 010 W5, 010 W6 |
| FBK0000027 | General feedback | Projects | 010 W7 |
| FBK0000006 | General feedback | Projects | Border and back already resolved (see FBK0000020). Open parts: 010 W1, 010 W4. |
| FBK0000028 | General feedback | Projects | Already resolved (`frontend/lib/app/shell_title.dart`, `54f70e4`). |

## Open questions
- 010 D1 (W3): which Create a project control remains. Default: footer on compact and medium, pane button on expanded.
- 010 D2 (W4): remove the Projects badge. Default: remove the badge, the tooltip suffix and the live region.
- 010 D3 (W6): the path in FBK0000026 is the storage root, saved for later resolves, with existing files left in place.
- 010 D4 (W7): restore the last internal path and query. Scroll and unsaved text stay out.
- FBK0000022 does not need a reporter. Anything beyond W2 and W3 was not specified.
