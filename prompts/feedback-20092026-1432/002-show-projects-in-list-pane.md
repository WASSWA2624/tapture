# 002 — Show the project list in the expanded list pane

**Feedback:** FBK0000006 · **Type:** Defect · **Priority:** P3 · **Effort:** M · **Depends on:** —

## Goal
On expanded widths the list pane shows the project list under its search bar, the search bar filters it,
and the pane no longer repeats the destination name as a heading. The main body stops repeating the same
list and shows the open project instead; "Create a project" stays in the body only while there are no
projects. Compact and medium keep the list in the body, because they have no pane. Correct in light,
dark and outdoor, in both orientations, and at 200 percent text.

## Evidence
- FBK0000006: the reporter asks that the Projects destination list the projects under the search bar,
  that the "Projects" heading above the search bar go, that the body stop showing the list, and that
  "Create a project" appear in the body only when there are none. `screenshots/FBK0000006.png` shows the
  pane reading "Nothing here yet" while the body lists an existing project — the same destination
  contradicting itself. Web, desktop, expanded (1280x585 @1.5x), landscape, light, text scale 1.
- Root cause: `frontend/lib/app/nav_shell.dart:181-240`. `_Pane` renders the same three things for every
  destination — `_destinations[index].label` as a title, an `AppSearchField` whose `onChanged` is
  `(_) {}`, and an `AppEmptyState`. It never reads any data, so the pane is empty whatever exists.
  Task [073](../../dev-plan/06-app-shell/073-nav-shell.md) step 5 built it as scaffolding and no later
  task fills it.
- The body list is `ProjectListScreen`
  (`frontend/lib/features/projects/presentation/project_list_screen.dart:51-120`), whose
  `AppPrimaryAction` footer shows whenever the list has loaded (`:44-49`).

## Scope
- Change:
  - `frontend/lib/features/projects/presentation/project_list_view.dart` (new): the rows, their
    overflow and their tap behaviour, lifted unchanged out of `ProjectListScreen` so the pane and the
    screen render one widget, not two (FE-CONS-02).
  - `project_list_screen.dart`: render `ProjectListView`; show the footer "Create a project" only when
    the list is empty **or** the size class is not expanded.
  - `project_list_filter.dart`: add a search-query notifier beside `projectListShowArchivedProvider`,
    and a derived provider that narrows the watched rows by a case-insensitive, accent-folded match on
    the project name.
  - `frontend/lib/features/projects/projects.dart`: export `ProjectListView` and the new providers.
  - `frontend/lib/app/nav_shell.dart`: `_Pane` takes its content from the destination instead of always
    building an empty state; drop the heading; wire the search field to the new notifier. Projects
    renders `ProjectListView`. Records keeps today's empty state until task
    [163](../../dev-plan/14-records/163-records-list.md) builds it.
  - `frontend/lib/core/copy/copy.dart`: the pane search hint if `Copy.search` does not fit.
  - Tests, listed in the steps.
- Do not change: the four destinations, `Sizes.listPane`, which destinations own a pane (`hasList`), the
  row's subtitle and counts, project creation, archive or delete, or the compact and medium layouts.
  Do not add pane actions or numbering — 006 owns those.

## Rules
- FE-CONS-01 and FE-CONS-02: one `ProjectListView` used twice, not a forked pane list. Rows stay
  `AppListTile` (FE-CONS-06).
- FE-CONS-04: the pane renders loading, empty, error and offline through `AsyncValueView`, like the
  screen. An empty search result is an empty state that names the next action (FE-SIMP-11).
- FE-STR-04: `core/` never imports `features/`, so the pane's content is wired in `lib/app/`, which
  already imports features. Import through the feature barrel (FE-STR-08).
- FE-RESP-02: no `MediaQuery` width comparison outside `core/widgets/responsive/`; use `context.sizeClass`.
- FE-RESP-03 and FE-RESP-06: a size-class change keeps the search text and the scroll position; the pane
  scrolls and clips nothing at 200 percent text.
- FE-SIMP-01: one primary action per screen — the body keeps exactly one "Create a project" or none.
- FE-L10N-01, FE-L10N-05 and FE-A11Y-01: `Copy` strings, `start`/`end` alignment, 48 dp rows.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 06-app-shell show-projects-in-list-pane "Show the project list in the expanded list pane"`
   (FE-FLOW-08).
2. Extract `ProjectListView` from `ProjectListScreen` with no behaviour change, and prove it with the
   existing `project_list_screen_test.dart` before touching the pane.
3. Add the search-query notifier and the filtered provider; wire the pane's search field to it.
4. Make `_Pane` content per destination, drop the heading, and render `ProjectListView` for Projects.
5. Make the body footer conditional, and confirm the body shows the open project's home on expanded.
6. Tests:
   - `frontend/test/app/nav_shell_test.dart`: at 1200 dp the pane lists projects; typing in the pane
     search narrows them; clearing restores them; a search matching nothing shows the empty state; the
     heading is gone; the Records pane still shows its empty state.
   - `frontend/test/features/projects/presentation/project_list_screen_test.dart`: the body shows
     "Create a project" with zero projects at every width, and at 400 and 800 dp with projects, but not
     at 1200 dp with projects; the list still renders in the body at 400 and 800 dp.
   - A test that a 400 dp → 1200 dp change keeps the typed search text and the selected project
     (FE-RESP-03).
   - Goldens for the pane in light, dark and outdoor at 1200 dp, empty and with three projects.

## Human review
⛔ Stop before step 4 and ask:
- Removing the body list on expanded changes what every desktop and tablet-landscape user sees. Should
  the body then show the open project's home, or an empty state prompting a choice from the pane?
  **Recommendation: the open project's home**, which is where tapping a row already leads, so the pane
  becomes the switcher and the body the workspace.
- Should the pane search also match the project's organisation and description, or only the name?
  **Recommendation: name only**, matching what the reporter asked for; widening it later is cheap.

Proceed only with an explicit answer. If the answer is "proceed", do both recommendations.

## Acceptance criteria
- [ ] At 1200 dp the pane lists every non-deleted, non-archived project under its search bar, with no
      heading above the search bar.
- [ ] Typing in the pane search narrows the list; no match shows an empty state offering "Create a project".
- [ ] At 1200 dp with at least one project, the body shows the open project and no second copy of the list.
- [ ] At 1200 dp with no projects, the body shows "Create a project".
- [ ] At 400 and 800 dp the list and "Create a project" stay in the body exactly as today.
- [ ] Changing width between 400 and 1200 dp loses neither the typed search nor the open project.
- [ ] The pane renders loading, empty, error and offline, and clips nothing at 200 percent text in
      light, dark and outdoor, in both orientations.
- [ ] FBK0000006's list-pane, heading, body-duplication and create-button parts are resolved. Its
      remaining parts are covered by 003, 004, 005, 006 and 007.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- Regenerate goldens with `--update-goldens` only for the navigation pane and the project list screen,
  and list the files regenerated.
