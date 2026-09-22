# Feedback prompts — TAPTURE-22092026-1046.xlsx

14 entries → 1 prompt, 15 work items. Generated 22 Sep 2026. Repository commit: 1b1461d.

## Run order
| Prompt | Item | Title | Feedback | Type | Priority | After |
| 001-resolve-shell-and-capture-feedback.md | W1 | Open settings screens on the shared database | FBK0000035 | Defect | P1 | — |
| 001-resolve-shell-and-capture-feedback.md | W2 | Take or import a photo from capture | FBK0000033, FBK0000042 | Defect | P2 | — |
| 001-resolve-shell-and-capture-feedback.md | W3 | Put the screen name in the status line and drop the status menu | FBK0000029, FBK0000034 | Defect | P3 | W2 |
| 001-resolve-shell-and-capture-feedback.md | W4 | Hide the empty context band | FBK0000029, FBK0000031, FBK0000032, FBK0000033, FBK0000035, FBK0000036, FBK0000037, FBK0000038, FBK0000039, FBK0000040, FBK0000041, FBK0000042 | Defect | P3 | W3 |
| 001-resolve-shell-and-capture-feedback.md | W5 | Remove the plan and specification and show licences in the shell | FBK0000040, FBK0000041 | Improvement | P3 | — |
| 001-resolve-shell-and-capture-feedback.md | W6 | Trim the project home menu | FBK0000030 | Improvement | P3 | — |
| 001-resolve-shell-and-capture-feedback.md | W7 | Title project capture with the project name | FBK0000033 | Defect | P3 | W3 |
| 001-resolve-shell-and-capture-feedback.md | W8 | Say the app-lock state once | FBK0000039 | Defect | P3 | — |
| 001-resolve-shell-and-capture-feedback.md | W9 | Make capture settings change on tap | FBK0000036 | Defect | P3 | — |
| 001-resolve-shell-and-capture-feedback.md | W10 | Drop the per-project list from storage | FBK0000038 | Improvement | P5 | — |
| 001-resolve-shell-and-capture-feedback.md | W11 | Open context setup from the project home | FBK0000032, FBK0000042 | Gap | P5 | W4 |
| 001-resolve-shell-and-capture-feedback.md | W12 | Reach templates and choose one in one step | FBK0000031 | Gap | P5 | W3 |
| 001-resolve-shell-and-capture-feedback.md | W13 | Resume the open capture session | FBK0000033 | Gap | P5 | W2 |
| 001-resolve-shell-and-capture-feedback.md | W14 | Apply a caption to one photo, a selection, or all | FBK0000033 | Gap | P5 | W2 |
| 001-resolve-shell-and-capture-feedback.md | W15 | Crop a photo and type on a derived copy | FBK0000033 | Suggestion | P6 | W2 |

## Coverage
| Feedback ID | Category | Screen | Outcome |
| FBK0000029 | General feedback | Projects | 001 W3, 001 W4 |
| FBK0000030 | General feedback | Nothing | 001 W6 |
| FBK0000031 | General feedback | Projects | 001 W4, 001 W12. Project-home title already shows the project name (`frontend/lib/features/projects/presentation/project_home_screen.dart:41`, `frontend/test/app/widgets/status_line_test.dart:196`). |
| FBK0000032 | General feedback | Nothing | 001 W4, 001 W11. Project-home title already shows the project name (same evidence as FBK0000031). |
| FBK0000033 | General feedback | Capture | 001 W2, 001 W3, 001 W4, 001 W7, 001 W13, 001 W14, 001 W15. Internet import follows D1, default (a). Several saved drafts follow D2, default (a). |
| FBK0000034 | General feedback | Projects | 001 W3 |
| FBK0000035 | General feedback | Operator | 001 W1, 001 W4. Child status-line title already reads Operator (`frontend/lib/app/shell_title.dart:66`). |
| FBK0000036 | General feedback | Camera | 001 W4, 001 W9 |
| FBK0000037 | General feedback | Appearance | 001 W4. Child status-line title already reads Appearance (`frontend/lib/app/shell_title.dart:72`, `frontend/lib/features/settings/presentation/appearance_settings_screen.dart:27`). |
| FBK0000038 | General feedback | Storage | 001 W4, 001 W10. Child status-line title already reads Storage (`frontend/test/app/widgets/status_line_test.dart:164`). |
| FBK0000039 | General feedback | App lock | 001 W4, 001 W8. Child status-line title already reads App lock (`frontend/lib/app/shell_title.dart:78`). |
| FBK0000040 | General feedback | About | 001 W4, 001 W5 |
| FBK0000041 | General feedback | About | 001 W4, 001 W5 |
| FBK0000042 | General feedback | Capture | 001 W2, 001 W4, 001 W11 |

## Open questions
- 001 D1 (W2): import a photo from a pasted URL. Default (a): camera and the device library only.
- 001 D2 (W13): more than one saved capture at a time. Default (a): one session per project in the existing session file.
- 001 D3 (W12): where the template-choice mode is stored. Default (a): an optional key on `ProjectSettings`.
