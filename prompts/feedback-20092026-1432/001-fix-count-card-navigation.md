# 001 — Fix the project home count navigation

**Feedback:** FBK0000007 · **Type:** Defect · **Priority:** P2 · **Effort:** M · **Depends on:** —

## Goal
Tapping Review, Process, Export or Share on the project home opens a list that belongs to the open
project and can be left again — Back on Android, the browser Back button on the web, a back control in
the title bar, and the Escape key on desktop all return to the project home. The Settings destination
always shows Settings, whatever was opened from it. True at compact, medium and expanded widths, in
both orientations, in light, dark and outdoor, and at 200 percent text.

## Evidence
- FBK0000007: the reporter taps the four count cards, lands on `/records?filter=needsReview`,
  `/queue?filter=queued`, `/records?filter=approved` and `/exports?filter=share`, finds it confusing and
  sees no way back; afterwards the Settings destination shows "Nothing here yet" instead of its settings.
  `screenshots/FBK0000007.png` and `-3` show the project home and its four cards;
  `-5` and `-7` show the rail with Settings selected while the body is an unprocessed-queue and an
  export placeholder. Web, desktop, expanded (1280x585 @1.5x), landscape, light, text scale 1, online.
- Root causes:
  - `frontend/lib/features/projects/presentation/project_home_screen.dart:362-365` builds the four
    targets from `_recordsRoot`, `_queueRoot` and `_exportsRoot` with only a `filter` query. The open
    project's id is dropped, so the destination cannot scope to the project the counts came from.
  - `_CountCard.onTap` calls `context.go(...)` (`project_home_screen.dart:156-182`). `go` replaces the
    location instead of pushing, so there is nothing to pop.
  - `frontend/lib/app/router.dart:559` and `:565` register `AppRoutes.queue` and `AppRoutes.exports`, and
    `:434` registers `AppRoutes.templates`, as **siblings** of `/more` inside the fourth shell branch.
    Going to one of them makes that branch's stack `[/queue]`: the rail still highlights Settings, the
    settings list is gone, and the branch root is no longer in the stack to pop back to. The settings
    tiles at `router.dart:636` and `:642` reach Templates and Unprocessed the same way.
  - Nothing offers a back affordance: `_RoutePage` sets `showAppBar: false` (`router.dart:619`), and
    `AppPage._compactBack` returns null unless `compactBar`, `showAppBar` and `canPop` are all true
    (`frontend/lib/core/widgets/app_page.dart:144-147`).

## Scope
- Change:
  - `frontend/lib/app/router.dart`: nest `queue`, `exports` and `templates` as child routes of
    `AppRoutes.more` so the Settings root stays in the branch stack; add project-scoped
    `records`, `queue` and `exports` children under `/projects/:projectId`, carrying `metadata:
    _projectScoped`; update the `AppRoutes` helpers and the settings tiles to the new paths.
  - `frontend/lib/features/projects/presentation/project_home_screen.dart`: point the four cards at the
    project-scoped locations, including the open project's id, and open them with `context.push` so the
    home stays beneath. Update the `_recordsRoot`, `_queueRoot` and `_exportsRoot` constants and the
    comment that ties them to `AppRoutes`.
  - `frontend/lib/core/widgets/app_page.dart`: let a pushed shell route show the back control — the
    placeholder pages set `compactBar` and a title bar at every width, or `_RoutePage` grows a
    `leading` back control. Pick one; do not add a second back widget.
  - `frontend/lib/core/copy/copy.dart`: any new string (the back tooltip already comes from
    `MaterialLocalizations`).
  - Tests, listed in the steps.
- Do not change: the placeholder bodies themselves — tasks
  [159](../../dev-plan/13-processing/159-queue-screen.md),
  [163](../../dev-plan/14-records/163-records-list.md) and phase 18 own the real queue, records and
  export screens. Do not add a filter UI, a records query or a fifth destination. Do not change the
  counts or `ProjectRepository.watchHome`.

## Rules
- FE-STR-02 and FE-CODE-09: every path is declared once in `lib/app/router.dart`; feature files keep
  their local constants and never import `router.dart`, as `project_home_screen.dart` already does.
- FE-RESP-03: switching size class keeps the branch stack, so a push must survive a rail-to-bar change.
- FE-RESP-07: both orientations.
- FE-SIMP-02: still four destinations. Nesting changes paths, not the menu.
- FE-SIMP-09 and FE-A11Y-06: leaving a list discards nothing, and the back control is reachable by
  keyboard in traversal order.
- FE-A11Y-01 and FE-A11Y-02: 48 dp back control with a semantic label and a tooltip.
- FE-CONS-01: reuse `AppPage` and `AppIconButton`; build no new title bar.
- FE-L10N-01 and FE-L10N-05: `Copy` strings, `start`/`end` alignment so the control mirrors in RTL.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 06-app-shell fix-count-card-navigation "Fix the project home count navigation"`
   (FE-FLOW-08).
2. Move `queue`, `exports` and `templates` under `/more` in the route table and update every
   `AppRoutes` helper and call site, including the two settings tiles.
3. Add the project-scoped `records`, `queue` and `exports` children under `/projects/:projectId`,
   rendering the existing `_RoutePage` placeholders unchanged.
4. Point the four count cards at the new locations with the open project's id, and open them with
   `push`.
5. Give the pushed pages a back control at every width, and confirm the web browser's Back button and
   the Android system Back both return to the project home.
6. Tests:
   - `frontend/test/app/router_test.dart`: `/more/queue`, `/more/exports` and `/more/templates`
     resolve; the Settings root is still beneath them; an unknown path still renders `AppErrorState`;
     a project-scoped list path with no open project still diverts to the picker and resumes.
   - `frontend/test/features/projects/presentation/project_home_screen_test.dart`: each card opens the
     project-scoped location with the project id and the right filter; popping returns to the home with
     the counts intact, at 400, 800 and 1200 dp and in both orientations.
   - `frontend/test/app/nav_shell_test.dart`: after opening a list from a count card, the rail and the
     bar still select Projects; after opening Templates from the settings list, Settings is selected and
     tapping Settings returns to the settings root.
   - The back control meets the accessibility matchers (label, tooltip, 48 dp) at 200 percent text.

## Human review
⛔ Stop before step 2 and ask:
- Moving `/queue`, `/exports` and `/templates` under `/more` changes three public paths, so existing
  deep links and bookmarks break. Add redirects from the old paths, change them without redirects, or
  keep the paths and fix only the stack? **Recommendation: move them and add a redirect from each old
  path**, which keeps old links working and costs three lines.
- Should the count cards open project-scoped paths (`/projects/<id>/records?filter=…`), or keep the
  global paths and carry the project as a query parameter? **Recommendation: project-scoped paths**,
  matching `/projects/<id>/capture`, so the rail stays on Projects and the scope survives a deep link.

Proceed only with an explicit answer. If the answer is "proceed", do both recommendations.

## Acceptance criteria
- [ ] Each of the four count cards opens a location that names the open project and the filter.
- [ ] From each of those lists, Android Back, browser Back, the title-bar back control and Escape all
      return to the project home with its counts unchanged.
- [ ] After opening any of them, the rail and the bottom bar still select Projects.
- [ ] Opening Templates or Unprocessed from the settings list leaves Settings selected, and tapping
      Settings returns to the settings list rather than a placeholder.
- [ ] The above hold at 400, 800 and 1200 dp, portrait and landscape, in light, dark and outdoor, and at
      200 percent text without clipping.
- [ ] Old `/queue`, `/exports` and `/templates` links still resolve (or the review answer says otherwise).
- [ ] FBK0000007 is resolved in full.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- Regenerate goldens with `--update-goldens` only for the placeholder pages that gain a title bar, and
  list the files regenerated.
