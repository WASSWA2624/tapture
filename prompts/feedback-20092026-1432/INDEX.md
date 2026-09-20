# Feedback prompts — TAPTURE-20092026-1432.xlsx

3 entries → 7 prompts. Generated 20 Sep 2026. Repository commit: 44174bc (every `path:line` below was
confirmed against 198e01a; 44174bc changes only `prompts/` and no file under `frontend/` or `dev-plan/`).

All three entries came from one profile: web on desktop Chrome, expanded (viewport 1280x585 @1.5x,
display 853x480), landscape, light, text scale 1, online, production build 1.0.0, locale `en_US`. Ten
images, all of the Projects area:
- `FBK0000006.png` and `-2` show the Projects destination and a project row's more menu.
- `FBK0000007.png`, `-3`, `-4` and `-6` show the project home with its four count cards; `-2` shows
  Records after tapping one; `-5` and `-7` show the rail with **Settings** selected while the body is an
  unprocessed-queue and an export placeholder.
- `FBK0000008.png` shows the same project home and the four-item rail.

Because every entry came from one platform and one width, each prompt states the target at compact,
medium and expanded, portrait and landscape, in light, dark and outdoor, and at 200 percent text
(FE-RESP-10, FE-A11Y-03, FE-L10N-06). Where the feedback describes something only desktop can do,
the prompt says what the other platforms do instead rather than leaving them behind: 001 covers Android
Back and browser Back as well as a title-bar control; 002 keeps the list in the body where there is no
pane; 006 moves the pane header's actions into the title bar at compact and medium; 007 falls back to a
download on the web, where no app can be launched.

## Run order
| Prompt | Title | Feedback | Type | Priority | Depends on |
| :--- | :--- | :--- | :--- | :--- | :--- |
| [001](001-fix-count-card-navigation.md) | Fix the project home count navigation | FBK0000007 | Defect | P2 | — |
| [002](002-show-projects-in-list-pane.md) | Show the project list in the expanded list pane | FBK0000006 | Defect | P3 | — |
| [003](003-add-borderless-overflow-control.md) | Add a borderless overflow control | FBK0000006 | Improvement | P4 | — |
| [004](004-add-project-pinning.md) | Add project pinning | FBK0000006 | Gap | P5 | — |
| [005](005-show-project-count-on-destination.md) | Show the project count on the Projects destination | FBK0000006, FBK0000008 | Gap | P5 | — |
| [006](006-add-project-list-actions-and-numbering.md) | Add project list actions and numbering | FBK0000006 | Gap | P5 | 002, 003, 004 |
| [007](007-open-project-files-externally.md) | Open a project's files in an external app | FBK0000006 | Suggestion | P6 | — |

Priorities: P1 crash, data loss, security or privacy; P2 blocks capture or a core flow; P3 correctness
or accessibility defect; P4 shared design-system or `core/` change; P5 gap or improvement; P6 suggestion.

001 is P2 because opening any of the four counts strands the operator on a placeholder with no way back
and leaves the Settings destination showing an empty state instead of settings — two of the four
destinations stop behaving. 003 is P4 and runs before 006, the screen that adopts it. 004 is the schema
half of pinning, split out so the migration is reviewed before any interface depends on it. Every prompt
carries a ⛔ *Human review* stop with a stated default; 004 and 007 forbid the risky step — a schema
bump and a new dependency — until the stop is answered.

## Coverage
| Feedback ID | Category | Screen | Outcome |
| :--- | :--- | :--- | :--- |
| FBK0000006 | General feedback | Projects | Split: list pane, pane heading, body duplication and the conditional create button → 002; borderless row menu → 003 then 006; pin storage → 004; destination count → 005; pane actions, Show archived, numbering, Rename and Pin → 006; "open with" → 007. Its request that a project hold templates that can be created, imported, inherited and deleted is *already resolved*: templates are project-scoped (`frontend/lib/features/templates/presentation/template_list_screen.dart:168-172` watches `watchByProject`), with create, shipped-library copy, duplicate, JSON import and export and delete built by tasks 092, 093 and 100 — 001 makes them reachable again. Its request for live two-way editing with external apps is an open question below. |
| FBK0000007 | General feedback | Projects | 001 |
| FBK0000008 | General feedback | Projects | Partly 005 (the destination count) and 001 (Templates and Unprocessed become reachable without breaking Settings). The rest is *Needs clarification*: what is missing from the four-destination menu, given FE-SIMP-02 fixes it at four. See the open question below. Its second sentence — that changes made for desktop must also apply to mobile and tablet — is *out of scope as a change of its own*: FE-RESP-10, FE-A11Y-03 and FE-L10N-06 already require it, and every prompt's acceptance criteria cover compact, medium and expanded. |

## Open questions
- **What is insufficient about the main menu (FBK0000008)?** The message is one sentence and the image
  shows only the four-item rail, so the intent cannot be read from the archive. FE-SIMP-02 is explicit —
  "Four navigation destinations. A fifth destination requires deleting one" — and it is enforced by a
  guardrail test, so a fifth cannot be added without changing the rule and its test in the same pull
  request (FE-FLOW-07, FE-TEST-06). Three readings are open, and they lead to different work:
  - the destinations carry no state, which 005 begins to answer;
  - Templates, Unprocessed and Exports are buried in the Settings branch, which 001 fixes;
  - a fifth destination is genuinely wanted, which needs the rule changed first.

  Which is it? No prompt should be written for this entry until that is answered. **Recommendation: the
  first two**, since both are already covered and neither costs a rule.
- **Live communication with external apps (FBK0000006).** The reporter asks that a template be opened
  and edited in an external app with "live communication between the app and the external apps". This
  cannot be specified from the archive, and it runs into three hard constraints:
  - *Platform.* The feedback came from the web, where a page cannot watch a file a desktop app is
    editing without the File System Access API, a per-file user grant and a Chromium browser. On iOS
    there is no equivalent at all. Android and desktop can watch a path.
  - *Evidence.* "Raw evidence is never destroyed. Refinement writes beside the original, never over it"
    is the first of the five rules, and task 102 already guarantees an imported workbook is copied once
    and never rewritten. A live two-way sync would have an external app writing over a file Tapture
    owns.
  - *Conflicts.* Two writers need a conflict policy. The app has a merge feature (phase 19) whose rules
    were written for device-to-device merges, not for an external editor.

  Before a prompt can be written: which platforms must this work on; is the external app allowed to
  write back to a Tapture-owned file, or only to a copy that is re-imported on demand; and who wins when
  both sides change a row? **Recommendation: a copy that is re-imported explicitly**, which 007 already
  lays the ground for, rather than a live watch.
- **Route paths (001).** Moving `/queue`, `/exports` and `/templates` under `/more` changes three public
  paths. Confirm whether old links must keep working; 001 recommends redirects and will not proceed past
  its stop without an answer.
