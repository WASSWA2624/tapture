# Feedback prompts — TAPTURE-20092026-1432.xlsx

3 entries → 7 prompts. Generated 20 Sep 2026. Repository commit: b56d0cc (every `path:line` below was
confirmed against 198e01a; nothing under `frontend/lib`, `backend/` or `dev-plan/` has changed since —
the only later edits are to the generator document itself).

All three entries came from one profile: web on desktop Chrome, expanded (viewport 1280x585 @1.5x,
display 853x480), landscape, light, text scale 1, online, production build 1.0.0, locale `en_US`. Ten
images, all of the Projects area:
- `FBK0000006.png` and `-2` show the Projects destination and a project row's more menu.
- `FBK0000007.png`, `-3`, `-4` and `-6` show the project home with its four count cards; `-2` shows
  Records after tapping one; `-5` and `-7` show the rail with **Settings** selected while the body is an
  unprocessed-queue and an export placeholder.
- `FBK0000008.png` shows the same project home and the four-item rail.

## Reach

One profile reported all three entries, so that profile is a sample, not the scope (section 4). Each
prompt names where its cause lives, fixes it at that layer, and carries the outcome to every surface
that shares it:

| Prompt | Where the cause lives | Carries to | Stated exclusion |
| :--- | :--- | :--- | :--- |
| 001 | Shared Dart + system back | All platforms, all 3 widths; back expressed as each platform expects | None |
| 002 | Size-class branch (`_Pane`) | Every surface ≥1024 dp — desktop, iPad portrait, foldables — not "desktop" | Records pane waits for task 163 |
| 003 | Shared `core/` widget + theme | Every `AppOverflowMenu`, every platform and width | None — a shared widget reaches everything |
| 004 | Shared model + per-platform store | Native `sqlite3` **and** the web database | All visible surfaces (they are 006) |
| 005 | Size-class branch (destinations) | Bar at compact, rail at medium and expanded; inverted rail included | Other three destinations get no badge |
| 006 | Size-class branch + shared widgets | Pane header at expanded, title bar at compact and medium | Long-press and right-click (FE-CONS-10) |
| 007 | `core/` service, per-platform impls | `_io` (chooser on mobile, shell open on desktop), `_web` (download), `_stub` | None dropped; web gets a different outcome |

Three reach findings changed a prompt rather than just its wording:
- **003** originally leaned on hover to make the borderless control noticeable. Hover does not exist on
  touch, so the rest state now has to carry the affordance by itself; the review question says so.
- **004** must prove its migration on the web database as well as the native one, because a half-applied
  upgrade does not fail the same way on both.
- **006** explicitly rules long-press *out*: FE-CONS-10 reserves it for selection, so the three-dot
  control stays the one way into the row menu on pointer and touch alike.

Every prompt's acceptance criteria are written against the surfaces its Reach names, at compact, medium
and expanded, both orientations, in light, dark and outdoor, at 200 percent text, and in RTL where
layout mirrors (FE-RESP-10, FE-A11Y-03, FE-L10N-05, FE-L10N-06).

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
