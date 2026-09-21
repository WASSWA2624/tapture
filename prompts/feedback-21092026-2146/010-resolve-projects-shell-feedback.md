# 010 — Resolve projects shell feedback

**Feedback:** FBK0000022, FBK0000023, FBK0000024, FBK0000025, FBK0000026, FBK0000027, FBK0000006 · **Work items:** 7 · **Depends on:** none

Do not run `003` through `009`. They are the previous draft of this same remaining work. `001` and `002` already shipped.

## Goal
Projects, Storage and launch behave as the open reports ask: the expanded list stays inside its pane, create appears once, the Projects destination has no count, Storage shows volume figures and a chosen root, and a cold start returns to the last route. Light, dark and outdoor; compact, medium and expanded; both orientations.

## Run order
| Item | Title | Feedback | Type | Priority | Effort | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| W1 | Clip the project list pane | FBK0000006 | Defect | P3 | S | — |
| W2 | Space page actions | FBK0000022, FBK0000023 | Defect | P4 | S | — |
| W3 | Keep one create control | FBK0000022, FBK0000024 | Improvement | P5 | S | — |
| W4 | Remove the projects nav count | FBK0000025, FBK0000006 | Improvement | P5 | S | — |
| W5 | Show storage volume totals | FBK0000026 | Gap | P5 | M | — |
| W6 | Set the storage root path | FBK0000026 | Gap | P5 | M | W5 |
| W7 | Restore the last route | FBK0000027 | Gap | P5 | M | — |

## Decisions
⛔ Stop here. Get an answer to every decision before step 1 of any work item. "Proceed" means the default.
- D1 (W3): FBK0000023 wants space between the title-row add control and the more control. FBK0000024 wants the duplicate Create a project removed. FE-SIMP-01 puts the primary in the lower third. Options: (a) compact and medium keep the footer `AppPrimaryAction` and drop the title-row add; expanded keeps the pane button only; an empty list has that one control and not a second; (b) keep the title-row add and the pane button, and remove the footer wherever another create is visible. Default: (a), because FE-SIMP-01 and FBK0000024 outweigh keeping two create controls. W2 still separates any action that remains beside an overflow menu.
- D2 (W4): Task 328 paints the project total on the Projects destination. Two reports say that number is read as pending or new work. Options: (a) remove the badge, the tooltip suffix and `_NavCountLive`; (b) keep the number for assistive tech and hide the badge. Default: (a), because both reports reject the visible number.
- D3 (W6): FBK0000026 asks to manage the default storage path from Storage. Options: (a) that path is `StorageRoot`; show it, persist a chosen folder for later resolves, and leave existing files where they are; (b) that path is only where exports are written, and the evidence root stays fixed. Default: (a), because the screen is Storage and the root is the folder the app already uses. Do not relocate files in this prompt.
- D4 (W7): FBK0000027 asks for the last screen. Options: (a) restore the last internal path and query; (b) restore only the last project home. Default: (a). Scroll position and unsaved text stay out of this prompt.

## Rules
- FE-CONS-01, FE-STR-09: change the shared widget once.
- FE-L10N-01, FE-TEST-01, FE-FLOW-08: `Copy` for new strings, tests with the change, a dev-plan task per area.
- FE-RESP-10, FE-A11Y-03: layout items cover compact, medium and expanded, both orientations, light, dark and outdoor, and 200 percent text.

## Before the work items
1. Record each area with `cd frontend && dart run tool/new_task.dart <phase-folder> <slug> "<title>"` when that area has no open task. Extend the owning task when one exists (FE-FLOW-08). Use `06-app-shell` for W1–W4 and W7, and `05-file-storage` for W5 and W6.

## W1 — Clip the project list pane
**Feedback:** FBK0000006 · **Type:** Defect · **Priority:** P3 · **Effort:** S · **After:** —

### Evidence
- FBK0000006: the project list under the search field runs into the detail area. `prompts/TAPTURE-21092026-2151/screenshots/FBK0000006.png` shows the expanded pane beside the project home. Web, expanded, landscape, dark. The count is W4. The border and the back control already shipped (`frontend/lib/core/widgets/app_overflow_menu.dart:19`, `frontend/lib/app/widgets/status_line.dart:108`).
- Root cause: the pane is a `SizedBox(width: Sizes.listPane)` with no clip (`frontend/lib/app/nav_shell.dart:98`). `AppListTile` is a `Row` plus a full-bleed `Divider` (`frontend/lib/core/widgets/app_list_tile.dart:71`, `:133`).

### Scope
- Reach: expanded width, both orientations, light, dark and outdoor, text scale 1 and 2, every platform that shows the pane. Compact and medium have no list pane (`NavShell` sets `pane: false` below expanded); do not force those widths to 280dp.
- Change: the pane in `frontend/lib/app/nav_shell.dart`, and `AppListTile` only where a row can exceed the incoming max width.
- Do not change: `Sizes.listPane`, search, numbering, row actions, and the detail home.

### Rules
- FE-RESP-04, FE-RESP-05, FE-RESP-07: the pane stays 280dp and the detail keeps the rest.
- FE-CONS-06: one `AppListTile`.
- FE-A11Y-01: the trailing menu stays a 48dp target. Title and subtitle ellipsize.
- FE-THEME-01: the existing hairline stays the pane edge.

### Steps
1. Clip the pane with `clipBehavior: Clip.hardEdge` on its `Material`. Keep `BorderDirectional` as the edge against the detail.
2. Keep `AppListTile` title and subtitle on `TextOverflow.ellipsis` inside a row that cannot exceed the parent's max width. The trailing menu stays inside that width.
3. In `frontend/test/app/nav_shell_test.dart`, at 1200dp the project row's right edge is within the pane, in landscape and at text scale 2. At 400dp the row is not forced to 280dp.
4. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] At expanded width the numbered row, its divider and its more control sit entirely inside the list pane, in both orientations, light, dark and outdoor, at text scales 1 and 2.
- [ ] The hairline between pane and detail is unbroken across the row.
- [ ] Compact and medium project lists still show the full row and open the project on tap.
- [ ] The overflow sentence of FBK0000006 is resolved.

## W2 — Space page actions
**Feedback:** FBK0000022, FBK0000023 · **Type:** Defect · **Priority:** P4 · **Effort:** S · **After:** —

### Evidence
- FBK0000023: the create control and the more control need space between them. `prompts/TAPTURE-21092026-2146/screenshots/FBK0000023.png` shows them adjacent in the Projects title row. Android, compact, portrait, dark.
- FBK0000022: the same Projects list, asked for as a layout fix. The duplicate create control is W3. The nav count is W4.
- Root cause: `AppPage` places `actions` and `AppOverflowMenu` in one list with no gap (`frontend/lib/core/widgets/app_page.dart:87`). `StatusLine` does the same for a non-root header (`frontend/lib/app/widgets/status_line.dart:128`). `ProjectListActions.paneToolbar` already uses `Wrap` `spacing: Space.x2` (`frontend/lib/features/projects/presentation/project_list_actions.dart:60`).

### Scope
- Reach: every `AppPage` bar and every shell header that shows an action beside an overflow menu, all platforms, all three widths, both orientations, light, dark and outdoor, 200 percent text.
- Change: `AppPage` `barActions` and the `StatusLine` trailing row. Leave the pane toolbar on `Space.x2`.
- Do not change: which actions exist. W3, per D1, removes the projects title-row add after this gap exists.

### Rules
- FE-THEME-01, FE-CODE-09: `Space.x2` only.
- FE-CONS-01: fix the shared rows once.
- FE-A11Y-01: 48dp targets survive the gap at 200 percent text.

### Steps
1. In `AppPage`, when `actions` is non-empty and `overflow` is non-empty, insert `SizedBox(width: Space.x2)` before the overflow menu.
2. In `StatusLine`, when `chrome.actions` is non-empty and `chrome.overflow` is non-empty, insert `SizedBox(width: Space.x2)` before the overflow menu.
3. Widget test: a page with one icon action and an overflow menu places the menu's left edge at least `Space.x2` to the right of the action, at 400dp and 1200dp, at text scale 2. A page with only an overflow menu has no leading gap.
4. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] Projects on compact shows a gap of `Space.x2` between the add control and the more control, in light, dark and outdoor, until W3 removes that add control per D1.
- [ ] A non-root header with both an action and an overflow menu uses the same gap.
- [ ] The expanded pane toolbar gap stays `Space.x2`.
- [ ] FBK0000023 is resolved. FBK0000022's remaining duplicate-create part is W3.

## W3 — Keep one create control
**Feedback:** FBK0000022, FBK0000024 · **Type:** Improvement · **Priority:** P5 · **Effort:** S · **After:** —

### Evidence
- FBK0000024: repeated controls, the Create a project button in particular, crowd the screen. `prompts/TAPTURE-21092026-2146/screenshots/FBK0000024.png` shows an add icon in the title row and a full-width Create a project footer. Android, compact, portrait, dark.
- Root cause: compact and medium render `ProjectListActions.barActions` (`frontend/lib/features/projects/presentation/project_list_actions.dart:31`) and, when the list has loaded, `AppPrimaryAction` (`frontend/lib/features/projects/presentation/project_list_screen.dart:57`). The empty list also offers `Copy.projectsCreate` (`frontend/lib/features/projects/presentation/project_list_view.dart:95`).

### Scope
- Reach: compact, medium and expanded, both orientations, all themes, all platforms. Create still exists on each.
- Change: `ProjectListScreen`, `ProjectListActions.barActions`, `ProjectListView` empty state. Per D1.
- Do not change: project row menus, search, numbering, and Show archived.

### Rules
- FE-SIMP-01: one primary, the large lower control on compact and medium.
- FE-SIMP-11: an empty list still offers create, once.
- FE-L10N-01: keep `Copy.projectsCreate`.
- FE-CONS-02: both layouts call `ProjectListActions.create`.

### Steps
1. Per D1. `ProjectListActions.barActions` returns an empty list.
2. Compact and medium keep the footer `AppPrimaryAction` when the list has loaded, with rows and without.
3. Expanded with rows keeps the pane `AppButton` and no footer. Expanded without rows keeps the empty-state action and no footer.
4. The compact and medium empty state does not also set `onAction` for create.
5. Update `frontend/test/features/projects/presentation/project_list_screen_test.dart` and `frontend/test/app/nav_shell_test.dart` so each width finds `Copy.projectsCreate` once, and that control still opens `/projects/new`.
6. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] Compact and medium, with rows and without, show one Create a project control, the footer.
- [ ] Expanded, with rows and without, shows one Create a project control, the pane button when rows exist and the empty-state action when they do not.
- [ ] That control opens `/projects/new`.
- [ ] FBK0000024 is resolved. FBK0000022 is resolved together with W2.

## W4 — Remove the projects nav count
**Feedback:** FBK0000025, FBK0000006 · **Type:** Improvement · **Priority:** P5 · **Effort:** S · **After:** —

### Evidence
- FBK0000025: the count on the Projects destination is easy to read as pending or new projects. `prompts/TAPTURE-21092026-2146/screenshots/FBK0000025.png` shows a badge on that destination. Android, compact, portrait, dark.
- FBK0000006: remove the count from the Projects destination. The expanded web screenshot shows the same badge on the rail.
- Root cause: the Projects `_Destination` sets `count: projectNavCountProvider` (`frontend/lib/app/nav_shell.dart:393`). `_NavIcon` draws `Badge` (`frontend/lib/app/nav_shell.dart:341`).

### Scope
- Reach: compact bar and medium and expanded rail, all platforms, both orientations, light, dark and outdoor, including the inverted rail. Per D2.
- Change: `frontend/lib/app/nav_shell.dart` and `frontend/test/app/nav_shell_test.dart`.
- Do not change: list numbering (`Copy.projectListNumber`), home count cards, and the Projects destination itself.

### Rules
- FE-A11Y-07: removing the live count removes `_NavCountLive` with it.
- FE-CONS-08: the destination keeps its folder icon.
- FE-L10N-01: delete `Copy.navProjectsCount` and `Copy.navProjectsCountBadge` when no reference remains.
- FE-TEST-06: update the badge tests; do not weaken a guardrail.

### Steps
1. Per D2. Stop passing `count` for Projects. Remove badge rendering, the tooltip suffix and `_NavCountLive`.
2. Rewrite `frontend/test/app/nav_shell_test.dart` so Projects finds no `Badge` at compact and at 1200dp, in light, dark and outdoor, with projects present.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] With at least one project, compact and expanded Projects destinations show no numeric badge.
- [ ] The spoken name of the destination is Projects, with no count.
- [ ] Capture, Records and Settings are unchanged. List row numbers remain.
- [ ] FBK0000025 and the count sentence of FBK0000006 are resolved.

## W5 — Show storage volume totals
**Feedback:** FBK0000026 · **Type:** Gap · **Priority:** P5 · **Effort:** M · **After:** —

### Evidence
- FBK0000026: the operator wants available, total and used space. `prompts/TAPTURE-21092026-2146/screenshots/FBK0000026.png` shows Storage with a qualitative free-space line, cache, per-project sizes and retention. Android, compact, portrait, dark. The path is W6.
- Root cause: `StorageGuard` classifies free bytes only (`frontend/lib/core/files/storage_guard.dart:210`). A failed check becomes `HeadroomState.ample` (`frontend/lib/features/settings/presentation/storage_settings_screen.dart:285`).

### Scope
- Reach: Android, Windows and POSIX desktops, both orientations, all themes, 200 percent text. Web is excluded: the storage screen is `dart:io` and device volume stats are not available in the browser sandbox (open task 286). Do not invent totals there.
- Change: `StorageGuard` gains a volume read and `check()` stays. Android adds `volumeStats` on the existing `com.tapture.app/files` channel in `MainActivity.kt` using `StatFs`. No new package. `StorageSettingsScreen` and `Copy` show the three figures.
- Do not change: cache clear, retention, per-project rows, capture blocking, and where files are stored.

### Rules
- FE-STR-11: only `StorageGuard` and the existing files channel touch the volume.
- FE-CONS-09, FE-L10N-01: three figures through `Copy.fileSize`.
- FE-STATE-11, FE-A11Y-05: a failed read is the error state. Ample, low and critical stay as words beside the numbers.
- FE-TEST-03: extend the fake so tests never run `df` and never run PowerShell.
- FE-FLOW-06: no new dependency.

### Steps
1. Add a volume result with total, used and free bytes. POSIX `df -Pk` already has 1024-blocks, used and available. Windows `Get-PSDrive` has `Used` and `Free`; total is their sum. Android uses `StatFs` through `volumeStats`.
2. A failed volume read is a `FailureResult`. Do not substitute `HeadroomState.ample`.
3. Under `Copy.settingsHeadroomHeader`, show total, used and available with `Copy.fileSize`, and keep the ample, low and critical label.
4. Unit-test the parser and the fake with known byte counts. Widget-test the three figures and the failure state in `frontend/test/features/settings/presentation/storage_settings_screen_test.dart`.
5. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] Given a volume of known size, Storage shows that total, used and available on compact portrait and expanded landscape, light, dark and outdoor, at text scale 2.
- [ ] Low and critical volumes still show their existing words beside the numbers.
- [ ] A failed probe shows the error state with retry, not the ample label.
- [ ] Cache, projects and retention rows are unchanged.
- [ ] The path sentence of FBK0000026 stays in W6.

## W6 — Set the storage root path
**Feedback:** FBK0000026 · **Type:** Gap · **Priority:** P5 · **Effort:** M · **After:** W5

### Evidence
- FBK0000026: set the default storage path on the same Storage screen. Android, compact, portrait, dark.
- Root cause: `StorageRoot` always uses shared Documents on Android 11+ or the app documents directory (`frontend/lib/core/files/storage_root.dart:35`). `SettingKeys` has no path key (`frontend/lib/features/settings/domain/setting_keys.dart`).

### Scope
- Reach: Android, Windows, macOS, Linux and iOS, all themes and widths. Per D3. Web is excluded: the browser cannot hold an app-chosen documents folder for the evidence tree.
- Change: a `SettingKey` for the root path, `StorageRoot.resolve` prefers a persisted path that still passes the write probe, and Storage shows the path. W5's volume rows stay.
- Do not change: cache, retention, and file moves. Do not copy the existing tree. Do not delete the existing tree.

### Rules
- FE-SIMP-12: the control exists because a chosen location is a fact the app cannot infer. An empty key keeps today's `StorageRoot`.
- FE-STR-11, FE-SEC-01: the path is a preference, not a secret. Platform folders stay inside `StorageRoot`.
- FE-SEC-08, FE-STATE-07: do not rewrite evidence and do not delete evidence. Persist the key before confirming.
- FE-L10N-01, FE-L10N-11: the label is `Copy`. The path is user data, shown as stored.
- FE-A11Y-02: the row has a name and shows the current path.
- FE-TEST-03.

### Steps
1. Per D3. Add a nullable string `SettingKey` and include it in `SettingKeys.names`.
2. `StorageRoot.resolve`: when the key is a non-empty directory and the existing write probe succeeds, use it. Otherwise use the current Documents fallback and surface a probe failure as today.
3. Storage gains a row: the current path, and an action that picks a directory through the platform wrapper already used for folders. Confirm only after `SettingsStore.write` succeeds.
4. Tests with `StorageRoot.fake` and `SettingsStore.fake`: an empty key uses the default; a saved path is the one `resolve` returns; a failed probe does not confirm.
5. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] Storage shows the active root path on Android and desktop, compact and expanded, light and dark.
- [ ] Choosing a writable folder, restarting, and resolving the root returns that folder.
- [ ] An empty key still resolves through the current Documents fallback.
- [ ] No existing file is moved. No existing file is deleted.
- [ ] Web does not show the picker.
- [ ] FBK0000026's path sentence is resolved. The figures stay in W5.

## W7 — Restore the last route
**Feedback:** FBK0000027 · **Type:** Gap · **Priority:** P5 · **Effort:** M · **After:** —

### Evidence
- FBK0000027: opening the app should return to the last screen. The screenshot is a project home. Android, compact, portrait, dark.
- Root cause: `GoRouter` uses `initialLocation: AppRoutes.projects` (`frontend/lib/app/router.dart:305`). `CurrentProject.consumeLaunchRestore` (`frontend/lib/features/projects/presentation/current_project.dart:57`) returns only a project id, and `ProjectListScreen._resumeLastProject` then opens that project's home (`frontend/lib/features/projects/presentation/project_list_screen.dart:70`). Storage, Records, Capture and a filtered list are not stored.

### Scope
- Reach: all platforms and size classes. Per D4. The stored value is an internal path and query. `/lock` is never stored. `/lock` is never restored. Web uses the same router.
- Change: a `SettingKey` for the last location, a listener that writes it after a successful navigation, and router startup that reads it once.
- Do not change: `SettingKeys.openProjectId`, app-lock `from`, and `_projectScope` when the project is gone.

### Rules
- FE-STATE-06, FE-STATE-07: one stored location, written through `SettingsStore` before it is treated as current.
- FE-SEC-06: restore only a relative internal path, using the check in `_isInternalLocation` (`frontend/lib/app/route_guards.dart:77`). Reject a scheme, a host, and `//`.
- FE-SEC-01: the value is a route, not a secret.
- FE-TEST-03.

### Steps
1. Per D4. Add a string `SettingKey`, default empty, and register it in `SettingKeys.names`.
2. After navigation commits, persist `state.uri` when it is internal and not `/lock`. Do not persist during a redirect loop.
3. When building `GoRouter`, if the stored location passes `_isInternalLocation` and is not `/lock`, use it as `initialLocation`. Otherwise keep `AppRoutes.projects`.
4. Leave `_resumeLastProject` only for a launch with an empty stored route. Do not navigate twice.
5. Tests with `SettingsStore.fake`: a stored `/more/storage` is the first location; `https://` and `/lock` are ignored; a stored project route whose project is missing still hits `_projectScope` and lands on `/projects`.
6. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] Kill and reopen on Storage, on Records with a filter, and on a project home: each returns to that route.
- [ ] A first launch with an empty key opens `/projects`.
- [ ] A stored external URL opens `/projects`. A stored `/lock` opens `/projects`.
- [ ] App lock still covers the restored route.
- [ ] FBK0000027 is resolved for the route. Scroll and unsaved text are unchanged.

## Verification
- After W7, `cd frontend && dart run tool/verify.dart` is green.
- `--update-goldens` only for visuals an item changes: W1 expanded pane goldens, W2 and W3 projects-list goldens, W4 nav-shell goldens that showed the badge. List the files under the item that regenerates them. W5, W6 and W7 regenerate no goldens unless an existing storage golden shows the new rows.
