# 008 — Restore last route

**Feedback:** FBK0000027 · **Type:** Gap · **Priority:** P3 · **Effort:** M · **Depends on:** none

## Goal
A cold start opens the last in-app route, on every platform, instead of always starting at the project list. Lock, guards and a deleted project still behave as they do now.

## Evidence
- FBK0000027: opening the app should return to the last screen. The screenshot is a project home, sent from `/projects/:id`. Android, compact, portrait, dark.
- Root cause: `GoRouter` uses `initialLocation: AppRoutes.projects` (`frontend/lib/app/router.dart:305`). `CurrentProject.consumeLaunchRestore` (`frontend/lib/features/projects/presentation/current_project.dart:57`) only returns a project id, and only after the list resolves; `ProjectListScreen._resumeLastProject` then `go`s to that project's home (`frontend/lib/features/projects/presentation/project_list_screen.dart:70`). Storage, Records, Capture and a filtered list are not stored.

## Scope
- Reach: all platforms and size classes. The stored value is an internal path and query, not scroll position or field text. `/lock` is never stored or restored. Web uses the same router; include it.
- Change: a `SettingKey` for the last location, a listener that writes it after a successful navigation, and router startup that reads it once.
- Do not change: `SettingKeys.openProjectId`, app-lock `from`, or `_projectScope` when the project is gone.

## Rules
- FE-STATE-06, FE-STATE-07: one stored location; write it through `SettingsStore` before treating it as current.
- FE-SEC-06: restore only a relative internal path, reusing the idea of `_isInternalLocation` in `frontend/lib/app/route_guards.dart:77`. Reject a scheme, a host, or `//`.
- FE-SEC-01: the value is a route, not a secret.
- FE-L10N-01: no new user-facing string unless a failure needs one; prefer the existing not-found page.
- FE-TEST-01, FE-TEST-02, FE-TEST-03.

## Steps
1. Record the work under `06-app-shell`, or `cd frontend && dart run tool/new_task.dart 06-app-shell restore-last-route "Restore the last route"` (FE-FLOW-08).

## Human review
⛔ Stop before step 2 and ask:
- FBK0000027 asks for the last screen. Scroll offsets and half-typed fields are not in the report.
  - A) Restore the last internal path and query only.
  - B) Restore only the last project home (the behaviour `_resumeLastProject` already attempts).
- Recommendation: A. If the answer is "proceed", do A.

2. Add a string `SettingKey`, default empty, and register it in `SettingKeys.names`.
3. After navigation commits, persist `state.uri` when it is internal and not `/lock`. Do not persist during a redirect loop.
4. When building `GoRouter`, if the stored location passes `_isInternalLocation` and is not `/lock`, use it as `initialLocation`. Otherwise keep `AppRoutes.projects`.
5. Leave `_resumeLastProject` in place only if a stored route is absent; do not navigate twice on launch.
6. Tests with `SettingsStore.fake`: a stored `/more/storage` is the first location; `https://` and `/lock` are ignored; a stored project route whose project is missing still hits `_projectScope` and lands on `/projects`.

## Acceptance criteria
- [ ] Kill and reopen on Storage, on Records with a filter, and on a project home: each returns to that route.
- [ ] A first launch with an empty key opens `/projects`.
- [ ] A stored external URL or `/lock` opens `/projects`.
- [ ] App lock still covers the restored route.
- [ ] FBK0000027 is resolved for the route. Scroll and unsaved text are unchanged.

## Verification
- `cd frontend && dart run tool/verify.dart --fast`, then `dart run tool/verify.dart`.
- No goldens.
