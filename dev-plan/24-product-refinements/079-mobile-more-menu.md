# 079 — Show a mobile More menu in the bottom navigation

**Implementation step:** 24.54

**Phase** 24 · Product refinements  |  **Depends on** [006](../06-app-shell/006-application-shell.md), [032](032-rename-more-nav-to-settings.md), [060](060-borderless-overflow-menus.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Replace the compact bottom navigation's Settings action with a labelled, horizontal three-dot **More** control
that opens an anchored menu above the bar (§83.1). Keep Projects, Capture and Records, and use the fourth branch
for existing secondary destinations. Each menu row has its established icon and label: Templates, Unprocessed,
Recycle bin and Settings. Opening or dismissing the menu must not navigate or reset the current branch.

Retain the medium/expanded Settings rail. Expose Documentation later in task 083 when it has a working route;
do not add a dead Documentation or export placeholder to this change.

## Files

- `frontend/lib/app/nav_shell.dart`, `frontend/lib/app/shell_destination.dart`
- `frontend/lib/core/widgets/app_overflow_menu.dart`, `frontend/lib/core/copy/copy.dart`
- `frontend/.rules/06-simplicity.md` and enforcing navigation tests
- `frontend/test/app/nav_more_menu_test.dart`, `frontend/test/app/nav_shell_test.dart`
- Existing destination goldens and shared overflow widget tests

## Constraints

- Reuse the shared overflow menu and destination metadata. Compact label/icon changes must not rename the desktop
  Settings control. Exactly four mobile controls; no fifth tab.
- Square corners, shared spacing/theme tokens, 48 dp targets, icons plus text, safe-area scrolling and accessible
  labels. Preserve selected branch, current project, draft input and search across dismissal and resizing.
- Selecting an entry closes the menu and uses the canonical route; reopening adds no duplicate route.

## Definition of done

- [x] Compact More opens a square menu with four working icon-labelled secondary destinations.
- [x] Each menu choice navigates to its existing destination and secondary screens select the fourth branch.
- [x] Dismissal preserves the active primary branch, project and search state; an open popup remains usable across
      a width change, and the existing desktop Settings rail is retained.
- [x] Focused widget/golden tests cover all four routes, icon/copy consistency, shared overflow behaviour, narrow
      phone layout at 200 percent text and light/dark/outdoor themes: 21 passed.
- [ ] The standard Flutter gate completes successfully, including analysis and `dart run tool/verify.dart --fast`.

## Verification status

Implemented and focused tests passed on 2026-09-28; targeted analysis of the six changed source/test files reported
no issues. The broader navigation/copy run reported 67 passes and one failure in the expanded project-pane no-match
test: its assertion expects **Create a project**, while the current empty pane supplies no create action. The
project-pane implementation was not changed by this task, but a separate baseline run has not established the
failure's age.

The full fast gate was attempted and is not green: plan and template checks passed; formatting, full analysis,
dependency allowlist, structure, strict test presence and guardrails reported failures. The pre-unit diagnostics
did not name this task's edited source paths: full analysis reported 14 issues elsewhere, formatting identified
40 other files, the allowlist lacked `integration_test`, and structure rejected existing `core/assets` and
`core/backend`. Guardrails reported 372 passes and 20 failures. The long unit/widget stage was stopped after about
10 minutes 50 seconds, at 3,163 passes and 9 failures, so that suite is incomplete. Its failures included the pane
assertion and processing tests. No unrelated files were changed to silence these results.

This task and its index entry remain open until the standard gate is satisfied; the 21 passing focused tests and
clean targeted analysis verify the menu change without claiming that the whole repository passes.
