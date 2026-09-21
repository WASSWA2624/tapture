# 005 — Remove projects nav count

**Feedback:** FBK0000025, FBK0000006 · **Type:** Improvement · **Priority:** P4 · **Effort:** S · **Depends on:** none

## Goal
The Projects destination in the bottom bar and the rail shows the folder icon and the word Projects. It does not show a number. The project list itself is unchanged.

## Evidence
- FBK0000025: the count on the Projects destination is easy to read as pending or new projects. `prompts/TAPTURE-21092026-2146/screenshots/FBK0000025.png` shows a badge on that destination. Android, compact, portrait, dark.
- FBK0000006: remove the count from the Projects destination. The expanded web screenshot shows the same badge on the rail.
- Root cause: the Projects `_Destination` sets `count: projectNavCountProvider` (`frontend/lib/app/nav_shell.dart:386`). `_NavIcon` draws `Badge` (`frontend/lib/app/nav_shell.dart:334`). `_destinationTooltip` and `_NavCountLive` speak the count (`:196`, `:279`). Task 328 added this.

## Scope
- Reach: compact bar and medium or expanded rail, all platforms, both orientations, light, dark and outdoor, including the inverted rail.
- Change: `frontend/lib/app/nav_shell.dart` and `frontend/test/app/nav_shell_test.dart`.
- Do not change: list numbering (`Copy.projectListNumber`), home count cards, or `projectNavCountProvider` if something else still reads the list length. Do not remove the Projects destination.

## Rules
- FE-A11Y-05, FE-A11Y-07: a count that remains must not be colour alone; this prompt removes the visible count rather than restyling it.
- FE-CONS-08: the destination keeps its folder icon.
- FE-L10N-01: delete `Copy.navProjectsCount` and `Copy.navProjectsCountBadge` only when no reference remains.
- FE-TEST-01, FE-TEST-02, FE-TEST-06: update the badge tests; do not weaken a guardrail to keep them.

## Steps
1. Record the work: extend task 328's area, or `cd frontend && dart run tool/new_task.dart 06-app-shell remove-projects-nav-count "Remove the projects nav count"` (FE-FLOW-08).

## Human review
⛔ Stop before step 2 and ask:
- Task 328 shows the project total on the destination. Two reports say that number is mistaken for pending or new work.
  - A) Remove the badge, the tooltip suffix and `_NavCountLive`.
  - B) Keep the number for assistive tech only, with no visible badge.
- Recommendation: A. If the answer is "proceed", do A.

2. Stop passing `count` for Projects. Remove badge rendering, the tooltip suffix and `_NavCountLive` when no destination passes `count`.
3. Rewrite `frontend/test/app/nav_shell_test.dart` so Projects finds no `Badge` at compact and at 1200dp, in light, dark and outdoor, with projects present. Drop `_expectBadgeContrast`.
4. Remove unused `Copy` helpers and their tests if nothing else calls them.

## Acceptance criteria
- [ ] With one or more projects, compact and expanded Projects destinations show no numeric badge.
- [ ] The spoken name of the destination is Projects, with no count.
- [ ] Capture, Records and Settings are unchanged. List row numbers remain.
- [ ] FBK0000025 and the count sentence of FBK0000006 are resolved.

## Verification
- `cd frontend && dart run tool/verify.dart --fast`, then `dart run tool/verify.dart`.
- `--update-goldens` only for nav-shell or projects goldens that included the badge. List the files.
