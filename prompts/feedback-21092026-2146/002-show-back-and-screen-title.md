# 002 — Show back and screen title

**Feedback:** FBK0000020, FBK0000021, FBK0000006, FBK0000028 · **Type:** Improvement · **Priority:** P3 · **Effort:** M · **Depends on:** 001

## Goal
On every non-root route, the top strip is one row: a back control and that screen's title, with that page's actions at the end. Root destinations keep the wordmark. Light, dark and outdoor; compact, medium and expanded; both orientations; 200 percent text. One header, not a wordmark row plus a second title row.

## Evidence
- FBK0000020: every screen should have a back control. Projects list screenshot has the wordmark and a more control, and no back.
- FBK0000021: replace the title-strip more control with back; when there is nothing to go back to, leave the slot empty. Records (`/records?filter=needsReview`) shows the wordmark and more control over Search and an empty state. Android, compact, portrait, dark.
- FBK0000006: replace the title-strip more control with back when back is possible. Expanded web project home still shows the wordmark and a more control.
- FBK0000028: on every page except the roots, replace the logo and the app name with the screen title and back, to spend less height. Project home shows the wordmark row and, under it, the project name, a second more control, and the count cards.
- Root cause: `StatusLine` always builds `AppBrandLockup` plus the status `AppOverflowMenu` (`frontend/lib/app/widgets/status_line.dart:65`). `AppPage._compactBack` only appears when `canPop` (`frontend/lib/core/widgets/app_page.dart:144`), and project home sets `showAppBar: false` and draws its own title (`frontend/lib/features/projects/presentation/project_home_screen.dart:39`, `:142`). Many routes use `go`, so `canPop` is false even when a parent exists. `_screenName` in `frontend/lib/app/feedback_host.dart:47` labels a project route as Projects, not the project name.

## Scope
- Reach: all platforms and size classes. The four branch roots stay wordmark headers: `/projects`, `/capture`, `/records`, `/more`. System back stays the platform's own behaviour; this prompt adds the in-app control only.
- Change: `StatusLine`, a shared route-title helper used by the shell and `FeedbackHost`, `AppPage` (hide its bar when the shell already shows that title and actions), `ProjectHomeScreen` (drop the duplicate name row; keep the context line and count cards).
- Do not change: root wordmarks, bottom bar or rail destinations, capture flow, or the status commands' destinations (project, templates, settings, queue).

## Rules
- FE-CONS-01, FE-CONS-02, FE-CONS-10: one header widget; the same back result on every non-root route.
- FE-RESP-03, FE-RESP-07, FE-RESP-08, FE-RESP-10, FE-A11Y-01, FE-A11Y-02, FE-A11Y-03: back is 48dp and named; title wraps or ellipsises at 200 percent text; safe areas stay.
- FE-L10N-01: titles come from `Copy` or the project name already on screen. No new sentence built by concatenation.
- FE-STR-04: a scope widget in `core/widgets/` carries the page title and actions up; `core/` does not import `app/`.
- FE-TEST-01, FE-TEST-02.

## Steps
1. Record the work under `06-app-shell`, or `cd frontend && dart run tool/new_task.dart 06-app-shell shell-back-and-title "Shell back and screen title"` (FE-FLOW-08).

## Human review
⛔ Stop before step 2 and ask:
- On the four roots, the status more menu is the only chrome for the open project, template, network and unprocessed queue. FBK0000021 removes it on every screen. FBK0000006 keeps it when back is impossible. FBK0000028 leaves roots as they are.
  - A) Roots keep the wordmark and that menu. Non-roots show back plus the screen title, and that page's own actions move into the same row.
  - B) Remove the menu on every route, including roots, and leave the slot empty when there is no back.
- Recommendation: A. If the answer is "proceed", do A.

2. Add a route-title helper. Roots return null (wordmark). A project route uses the open project's name (`statusProjectLabelProvider` / `currentProjectDetailsProvider`). Settings and other nested routes use the same `Copy` titles `FeedbackHost` already maps. `FeedbackHost` calls this helper instead of its private map.
3. Non-root `StatusLine`: borderless back (`AppIconButton`, `Icons.arrow_back`, the Material back tooltip). If `GoRouter.canPop()`, pop; otherwise `go` to the parent path (last segment removed), so `/more/storage` returns to `/more`, `/projects/:id/capture` to the project, and `/projects/:id` to `/projects`. Title is the helper's text. Trailing slot is the page's actions, including its overflow menu.
4. `AppPage` on a non-root route does not build a second `AppBar`. It publishes title, actions and overflow to the shell scope. Roots still build their page bar under the wordmark.
5. Project home publishes the project name and its existing menu, and removes the in-body name row. Context line and count cards stay.
6. Widget tests in `frontend/test/app/widgets/status_line_test.dart` and the project-home and storage screen tests: root shows the wordmark; storage shows one back and one Storage title; project home shows one back and the project name.

## Acceptance criteria
- [ ] `/projects`, `/capture`, `/records` and `/more` show the wordmark and, under option A, the status menu. They do not show a back control.
- [ ] Storage, project home, Records with a filter, and other nested routes show a single row: back, screen title, that page's actions. No second title row.
- [ ] Back from storage lands on Settings; back from a project home lands on the project list; back from project capture lands on that project.
- [ ] The row is intact at 200 percent text on compact portrait and expanded landscape, in light, dark and outdoor.
- [ ] FBK0000021, FBK0000028 and the back sentences of FBK0000020 and FBK0000006 are resolved.

## Verification
- `cd frontend && dart run tool/verify.dart --fast`, then `dart run tool/verify.dart`.
- `--update-goldens` only for shell or project-home goldens this header change affects. List them.
