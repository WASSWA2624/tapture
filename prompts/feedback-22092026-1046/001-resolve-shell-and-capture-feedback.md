# 001 — Resolve shell and capture feedback

**Feedback:** FBK0000029, FBK0000030, FBK0000031, FBK0000032, FBK0000033, FBK0000034, FBK0000035, FBK0000036, FBK0000037, FBK0000038, FBK0000039, FBK0000040, FBK0000041, FBK0000042 · **Work items:** 15 · **Depends on:** none

## Goal
On every platform, size class, orientation and theme, the status line names the screen, the empty Site band is gone, Operator opens, and capture can add a photo from the camera and from the library, caption it, resume the open session, and reach templates and context without a status menu.

## Run order
| Item | Title | Feedback | Type | Priority | Effort | After |
| W1 | Open settings screens on the shared database | FBK0000035 | Defect | P1 | S | — |
| W2 | Take or import a photo from capture | FBK0000033, FBK0000042 | Defect | P2 | M | — |
| W3 | Put the screen name in the status line and drop the status menu | FBK0000029, FBK0000034 | Defect | P3 | M | W2 |
| W4 | Hide the empty context band | FBK0000029, FBK0000031, FBK0000032, FBK0000033, FBK0000035, FBK0000036, FBK0000037, FBK0000038, FBK0000039, FBK0000040, FBK0000041, FBK0000042 | Defect | P3 | S | W3 |
| W5 | Remove the plan and specification and show licences in the shell | FBK0000040, FBK0000041 | Improvement | P3 | M | — |
| W6 | Trim the project home menu | FBK0000030 | Improvement | P3 | S | — |
| W7 | Title project capture with the project name | FBK0000033 | Defect | P3 | S | W3 |
| W8 | Say the app-lock state once | FBK0000039 | Defect | P3 | S | — |
| W9 | Make capture settings change on tap | FBK0000036 | Defect | P3 | M | — |
| W10 | Drop the per-project list from storage | FBK0000038 | Improvement | P5 | S | — |
| W11 | Open context setup from the project home | FBK0000032, FBK0000042 | Gap | P5 | S | W4 |
| W12 | Reach templates and choose one in one step | FBK0000031 | Gap | P5 | L | W3 |
| W13 | Resume the open capture session | FBK0000033 | Gap | P5 | M | W2 |
| W14 | Apply a caption to one photo, a selection, or all | FBK0000033 | Gap | P5 | M | W2 |
| W15 | Crop a photo and type on a derived copy | FBK0000033 | Suggestion | P6 | M | W2 |

## Decisions
⛔ Stop here. Get an answer to every decision before step 1 of any work item. "Proceed" means the default.
- D1 (W2): FBK0000033 also asks to browse or download a photo from the internet by URL. Options: (a) camera and the device library only; (b) also a URL field that fetches when offline-by-choice is off. Default: (a), because FE-SEC-03 keeps egress a closed list and the report was taken offline by choice.
- D2 (W13): FBK0000033 asks to keep more than one capture and resume any of them. Options: (a) one session per project in the existing `TextStore` behind `CapturePersistenceImpl.saveSession`; (b) a new drafts index file. Default: (a), because (b) is a new stored format (FE-STATE-07) and the current store already holds one session.
- D3 (W12): where the template-choice mode is stored. Options: (a) optional `templateChoice` on `ProjectSettings` JSON; (b) a new projects column and migration. Default: (a), because missing keys already decode as defaults and an old row keeps working with no migration.

## Rules
- FE-CONS-01, FE-CONS-02, FE-STR-09: reuse `core/` and the capture, context and template widgets that already exist.
- FE-L10N-01: new visible strings go in `frontend/lib/core/copy/copy.dart`.
- FE-TEST-01, FE-FLOW-08: tests and a plan task ship with the change.
- FE-RESP-10, FE-A11Y-03: layout changes hold at compact, medium and expanded, both orientations, light, dark and outdoor, and at 200 percent text.

## Before the work items
1. Record the work in the plan: `cd frontend && dart run tool/new_task.dart 23-hardening resolve-shell-capture-feedback "Resolve shell, settings and capture feedback"` (FE-FLOW-08).

## W1 — Open settings screens on the shared database
**Feedback:** FBK0000035 · **Type:** Defect · **Priority:** P1 · **Effort:** S · **After:** —

### Evidence
- FBK0000035: Operator shows the error panel (`Copy` via `ProviderFailure`: "A service this screen uses failed.") with Try again. Android, compact, portrait, dark, text scale 1.
- Root cause: `frontend/lib/main.dart:62` opens the one `AppDatabase` and says a second connection races that file. `frontend/lib/features/settings/presentation/operator_profile_screen.dart:324` calls `AppDatabase.open()` again, and so do `capture_settings_screen.dart:297` and `storage_settings_screen.dart:438`.

### Scope
- Reach: every platform that opens the on-disk database. Tests keep using an in-memory database and never call `AppDatabase.open()` (FE-TEST-03).
- Change: add `appDatabaseProvider` in `frontend/lib/core/db/database_provider.dart`. Override it in `main.dart` with the instance already created there. Operator reads that instance. Capture settings and storage read `offlineStoreProvider` instead of `SettingsStore.open` on a new database.
- Do not change: the operator form fields, validation, and the settings catalogue order.

### Rules
- FE-STATE-09, FE-STATE-10: one long-lived database, fakes in tests.
- FE-CODE-06: a failed read stays a `Failure` the screen can show.

### Steps
1. Add `final Provider<AppDatabase> appDatabaseProvider` that throws `StateError` when read without an override.
2. In `main.dart`, override `appDatabaseProvider` with the existing `database` instance. Do not call `AppDatabase.open()` anywhere else in `lib/`.
3. Point `_OperatorProfile._database` at `ref.read(appDatabaseProvider)`. Point capture settings and storage at `ref.read(offlineStoreProvider)` and delete their private `AppDatabase.open()` paths.
4. Widget-test Operator with `AppDatabase.memory()` and a device profile: the name field is visible and the error panel is absent. Widget-test Capture settings and Storage the same way against `SettingsStore` on that memory database.
5. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] Operator, Capture settings and Storage render their loaded body on a device build that already has the main database open.
- [ ] A production search of `frontend/lib` finds `AppDatabase.open()` only in `app_database.dart` and `main.dart`.
- [ ] FBK0000035's error panel is gone. The empty Site band on that screen is W4.

## W2 — Take or import a photo from capture
**Feedback:** FBK0000033, FBK0000042 · **Type:** Defect · **Priority:** P2 · **Effort:** M · **After:** —

### Evidence
- FBK0000033: the add-photo control does nothing. The reporter wants the device camera and the device library. Android, compact, portrait, dark.
- FBK0000042: the same capture surface, on `/capture`, with no project context shown.
- Root cause: `frontend/lib/features/capture/presentation/capture_screen.dart:59` sets `onAdd: onAddPhoto ?? () {}`.

### Scope
- Reach: every platform `CaptureScreen` builds. Where `PhotoPicker.take` reports no camera, show only the library action. Web is that case when the picker reports no camera. No URL fetch (D1 default).
- Change: `capture_screen.dart`, `PhotoPicker`, `CaptureController.addPhoto`, `GalleryPicker` only as the existing widget if it already calls `PhotoPicker.choose`. New copy keys for the two actions.
- Do not change: save buttons, the caption field, and session storage (W13).

### Rules
- FE-STR-11: the screen calls `PhotoPicker`, never a camera plugin.
- FE-SEC-03, FE-SEC-08: no new network egress; bytes are a new photo file, not an overwrite.
- FE-SIMP-01, FE-SIMP-03: the add control stays in the tray; Save raw remains the primary pair already on the screen.

### Steps
1. Follow D1. The default adds no URL field and no HTTP client.
2. Replace the empty `onAdd` with a sheet of two `AppListTile`s: Take a photo (`PhotoPicker.take`) and Choose from this device (`PhotoPicker.choose`, many files allowed up to the limit `GalleryPicker` already uses). Hide Take a photo when `take` returns the picker's no-camera failure before the sheet closes.
3. For each returned image, build a `PhotoDraft` for the open project and `await controller.addPhoto`. On failure, `showAppSnack` with the failure message.
4. Widget-test the sheet: a fake picker that returns one image adds one tray photo; a fake with no camera omits Take a photo; a failure shows the snackbar and leaves the tray unchanged.
5. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] The add control opens the sheet, and an image returned by that sheet appears in the tray on compact, medium and expanded, both orientations.
- [ ] No code path fetches a URL.
- [ ] FBK0000033's dead button is fixed. Context, captions, drafts and editing are later items.

## W3 — Put the screen name in the status line and drop the status menu
**Feedback:** FBK0000029, FBK0000034 · **Type:** Defect · **Priority:** P3 · **Effort:** M · **After:** W2

### Evidence
- FBK0000029: the projects root shows the wordmark, a status more button, and a second "Projects" title. The more button should go. The page title belongs in the status line. Android, compact, portrait, dark.
- FBK0000034: the same more button on Projects, Records and Settings. Settings should read Settings. A more button stays only where the page has a command that has no other control.
- Child routes already title themselves: Storage is asserted in `frontend/test/app/widgets/status_line_test.dart:164`. Do not retitle Operator, Appearance, Storage, App lock or About.

### Scope
- Reach: all four shell branches, compact (bottom bar), medium (rail) and expanded (rail plus list pane), both orientations, all three themes, 200 percent text.
- Change: `frontend/lib/app/widgets/status_line.dart`, `frontend/lib/app/nav_shell.dart` (`ownsHeader`), `frontend/lib/app/shell_title.dart`, `frontend/lib/features/projects/presentation/project_list_screen.dart`, `frontend/lib/features/settings/presentation/settings_screen.dart`, `frontend/lib/features/capture/presentation/capture_screen.dart` (after W2 this file wires `onAdd`).
- Do not change: per-row project menus, the project-home menu (W6), the expanded pane's create button, and `AppBrandLockup` itself.

### Rules
- FE-CONS-10, FE-RESP-03, FE-RESP-08: one status row; back only where the route can actually pop.
- FE-SIMP-02: Templates and Unprocessed are rows on Settings, not a fifth destination.
- FE-A11Y-01, FE-A11Y-02: the remaining more button is 48dp and labelled.

### Steps
1. On `ShellTitle.isRoot`, the status line shows `ShellTitle.screen` (Projects, Capture, Records, Settings), no `AppBrandLockup`, no back control, and no `_statusItems` menu. `ownsHeader` is true on those roots so the page does not draw a second bar.
2. On every other route, keep back plus the existing title precedence. Do not mount `_statusItems` there either.
3. Projects root publishes one overflow item, Show archived, into that status row. Records, Capture and Settings roots publish no overflow.
4. Add Settings rows for Templates (`/more/templates`, `Copy.navTemplates`) and Unprocessed (`/more/queue`, `Copy.navQueue`), with new subtitles in `Copy`. Offline stays the existing `OfflineSwitch`.
5. Rebuild `CaptureScreen` on `AppPage` with `showAppBar: false`. It builds no `Scaffold` and no `AppBar`. Keep the W2 add sheet. Leave the inner `ContextBar` for W4 to remove.
6. Update `status_line_test.dart`: roots show the destination name, no `status-overflow`, and no brand lockup. Storage still shows Storage, back, and no brand lockup. Update `nav_shell_test.dart` expectations that required the wordmark on a root.
7. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] Projects, Capture, Records and Settings roots show that name in the status line and no wordmark, at all three widths, both orientations, all three themes, and at 200 percent text.
- [ ] Back is absent on those four roots and present on Operator, Storage and a project home.
- [ ] The status menu's project, template, network and queue commands are gone. Templates and Unprocessed open from Settings. Show archived remains the only projects-root overflow.
- [ ] FBK0000029 and FBK0000034's extra more buttons are gone. The Site band is W4.

## W4 — Hide the empty context band
**Feedback:** FBK0000029, FBK0000031, FBK0000032, FBK0000033, FBK0000035, FBK0000036, FBK0000037, FBK0000038, FBK0000039, FBK0000040, FBK0000041, FBK0000042 · **Type:** Defect · **Priority:** P3 · **Effort:** S · **After:** W3

### Evidence
- Those entries show a Site chip in its own band on projects, capture and every settings child. FBK0000029 and FBK0000033 say the band is obsolete on every screen.
- Root cause: `frontend/lib/features/projects/data/project_repository_impl.dart:567` inserts a Site level with no value, and `ContextBar` renders a chip for a level whose value is empty (`context_bar.dart:56`). `CaptureScreen` also mounts a second `ContextBar`.

### Scope
- Reach: every screen under `NavShell`, all widths, orientations and themes. A level with a value still shows. A pin with a value still shows.
- Change: `ContextBar`, `_insertDefaultContext`, and the `ContextBar` left in `CaptureScreen` after W3.
- Do not change: stored context rows, the hierarchy editor, and chips that display a real value. Leave `context_bar_golden_test.dart` goldens in place while every chip in them still has a value.

### Rules
- FE-CONS-02: one `ContextBar`, the one in `NavShell`.
- FE-SEC-08: no delete of stored levels.

### Steps
1. Stop inserting the default Site level in `_insertDefaultContext`. Leave existing rows in place.
2. In `ContextBar`, skip a level whose value is empty and a pin whose value is empty. When nothing remains, return `SizedBox.shrink`.
3. Remove the `ContextBar` from `CaptureScreen`.
4. Widget-test a project with a Site level and an empty value: the shell has no Site chip. Widget-test a level value "Lab": one chip reads the level and that value. Widget-test capture: `find.byType(ContextBar)` finds one.
5. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] A project with only empty context values shows no context band on Projects, Capture, Records, Settings and a settings child, at all three widths and both orientations.
- [ ] A set level value still shows one chip, and tapping it still opens `showContextPickerSheet`.
- [ ] New projects are created with zero context levels.

## W5 — Remove the plan and specification and show licences in the shell
**Feedback:** FBK0000040, FBK0000041 · **Type:** Improvement · **Priority:** P3 · **Effort:** M · **After:** —

### Evidence
- FBK0000040: remove the plan row and the specification row from About.
- FBK0000041: the licences page is the framework licence list, with a second back bar, and the package names are not readable as a page of this app. Android, compact, portrait, dark.

### Scope
- Reach: About and the licences page on every platform, width, orientation and theme, including 200 percent text.
- Change: `frontend/lib/features/settings/presentation/about_screen.dart`, `Copy.settingsAboutSubtitle`, a licences body that uses `LicenseRegistry` inside `AppPage`.
- Do not change: version, build, and the Settings row that opens About.

### Rules
- FE-CONS-01, FE-CONS-04: `AppPage`, `AppListTile`, `AsyncValueView`.
- FE-L10N-01, FE-A11Y-03: copy keys; the list scrolls at 200 percent text.

### Steps
1. Delete the plan tile, the specification tile, and their `openUrl` calls. Set `Copy.settingsAboutSubtitle` to a line that mentions version and licences only. Delete `Copy.settingsPlan`, `Copy.settingsSpecification` and the URL constants when nothing else reads them, and update `about_screen_test.dart` and `copy_test.dart`.
2. Replace `showLicensePage` with a route-local `AppPage` titled `Copy.settingsLicences`. Collect `LicenseRegistry`. One `AppListTile` per package. The title is the package name. The subtitle is the first of BSD, MIT, Apache and ISC that the text contains. When none of those words appear, the subtitle is the first sentence. Tapping a row shows the full licence text in the same page body. The page adds no second app bar.
3. Widget-test About: plan and specification are absent; Licences opens a list that contains a known package from a test `LicenseEntry`; the shell back is the only back control.
4. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] About shows Version, Build and Licences on all three widths and both orientations. The plan row is absent. The specification row is absent.
- [ ] Licences uses the shell title Licences and one back control, and each row names a package in `AppListTile`.

## W6 — Trim the project home menu
**Feedback:** FBK0000030 · **Type:** Improvement · **Priority:** P3 · **Effort:** S · **After:** —

### Evidence
- FBK0000030: remove All projects and New project from the project more menu, and give Duplicate an icon. Android, compact, portrait, dark.
- The menu is `_projectHomeMenu` in `frontend/lib/features/projects/presentation/project_home_screen.dart:212`. Duplicate has no `icon`. Template duplicate already uses `Icons.copy_outlined`.

### Scope
- Reach: the project-home overflow on every width, including the in-body menu when the shell does not own the header.
- Change: that menu only.
- Do not change: Project details, Settings, Archive, Delete, Open externally, and the projects-root Show archived item.

### Rules
- FE-CONS-08: Duplicate uses `Icons.copy_outlined`, the same icon as the template list.

### Steps
1. Remove the All projects and New project actions from `_projectHomeMenu`.
2. Set the Duplicate action's `icon` to `Icons.copy_outlined`.
3. Widget-test the menu: those two labels are absent, and Duplicate has that icon. The footer still says Continue capturing.
4. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] The project-home menu has no All projects and no New project, and Duplicate shows `Icons.copy_outlined`.
- [ ] Project details, Settings, Archive and Delete still run.

## W7 — Title project capture with the project name
**Feedback:** FBK0000033 · **Type:** Defect · **Priority:** P3 · **Effort:** S · **After:** W3

### Evidence
- FBK0000033: inside a project, capture's status title should be the project name. The archive build showed Projects.
- `ShellTitle.screen` returns `Copy.navCapture` for any path that ends in `/capture` before it looks up the project (`frontend/lib/app/shell_title.dart:84`). `status_line_test.dart:214` locks that.

### Scope
- Reach: `/projects/:projectId/capture` on every width, orientation and theme. The Capture tab root stays titled Capture (W3).
- Change: `ShellTitle.screen` and `status_line_test.dart`.
- Do not change: project-home titles. They already use `details?.name`.

### Rules
- FE-CONS-02: the status line and `ShellTitle.screen` return the same string, so feedback's screen name matches the bar.

### Steps
1. For a path under `/projects/` that ends in `/capture`, return the name from `currentProjectDetailsProvider`. When that name is null, return `Copy.navProjects`. Keep the exact `/capture` path on `Copy.navCapture`.
2. Update `status_line_test.dart` so `${AppRoutes.project('p1')}/capture` expects `Alpha` in the status line.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] With a project named in the details provider, project capture's status line is that name, with back, and no wordmark.
- [ ] The Capture tab root still reads Capture.

## W8 — Say the app-lock state once
**Feedback:** FBK0000039 · **Type:** Defect · **Priority:** P3 · **Effort:** S · **After:** —

### Evidence
- FBK0000039: App lock repeats "App lock is off. Set a PIN to require it on launch and resume." The page should be simpler. Android, compact, portrait, dark.
- `AppLockScreen.manage` sets that sentence as `subtitle` (`Copy.appLockOff`) and `_manageBody` prints it again (`app_lock_screen.dart:235`).

### Scope
- Reach: the manage page, lock off and lock on, all widths, orientations and themes, 200 percent text.
- Change: `_manageBody` only.
- Do not change: PIN fields, Set PIN, Remove PIN, and the unlock gate.

### Rules
- FE-SIMP-01, FE-CONS-05: one status sentence, the subtitle.

### Steps
1. When the lock is off, delete the body `Text` of `Copy.appLockOff`. Keep one `Copy.appLockRecovery` under the form.
2. When the lock is on, keep `Copy.appLockSetEffect` and `Copy.appLockRemoveEffect` because the subtitle is `Copy.appLockOn`, a different sentence.
3. Widget-test the off state: `Copy.appLockOff` appears once. Widget-test the on state: recovery and the remove effect are present.
4. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] With the lock off, the off sentence appears once, and the recovery sentence appears once.
- [ ] Set PIN still submits both fields.

## W9 — Make capture settings change on tap
**Feedback:** FBK0000036 · **Type:** Defect · **Priority:** P3 · **Effort:** M · **After:** —

### Evidence
- FBK0000036: Capture settings is wrongly laid out. Fill dates automatically is painted as a selected row. Android, compact, portrait, dark. The screen name in the archive is Camera because `ShellTitle` returns `Copy.settingsCamera`.
- `capture_settings_screen.dart:61` writes `view.cameraMode` back unchanged. Line 124 writes `view.namingPattern` back unchanged. Dates and GPS use `AppListTile.selected` (`:70`, `:83`).

### Scope
- Reach: `/more/capture` on every width, orientation and theme, 200 percent text.
- Change: `CaptureSettingsScreen`, `ShellTitle` for `AppRoutes.settingsCapture`, and `Copy` for a naming field label if none exists.
- Do not change: context auto-clear and movement switches lower on the same page, and the stored key names.

### Rules
- FE-CONS-01: `AppSwitchTile` and `AppTextField`, already used on this screen and on Operator.
- FE-A11Y-05: a boolean is a switch, not a selected colour.
- FE-L10N-01.

### Steps
1. Set the page title and `ShellTitle.screen` for this route to `Copy.navCapture`. Remove the `AppSectionHeader` that repeats that word. Leave the Context levels header.
2. Render Fill dates automatically and GPS as `AppSwitchTile`. Tapping writes the negated bool.
3. Photo quality and Photo folders keep their existing cycle helpers. Camera cycles `photo` and `document`, and the subtitle uses `Copy.settingsCameraPhoto` for `photo` and a new `Copy` label for `document`.
4. File names opens an `AppTextField` prefilled with `view.namingPattern`. Submitting writes that string through `SettingKeys.namingPattern`.
5. Widget-test: dates flips false to true; camera tap stores `document`; naming submit stores the typed pattern; the selected-row check on dates is absent.
6. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] The status line reads Capture. Dates and GPS are switches. Camera, quality and folders change the stored value on activation. File names saves the typed pattern.
- [ ] The page scrolls at 200 percent text on a compact portrait window.

## W10 — Drop the per-project list from storage
**Feedback:** FBK0000038 · **Type:** Improvement · **Priority:** P5 · **Effort:** S · **After:** —

### Evidence
- FBK0000038: Storage lists projects and the reporter asks for that list to go. Android, compact, portrait, dark.
- The list is the `Copy.settingsProjectsHeader` block in `storage_settings_screen.dart:99`.

### Scope
- Reach: Storage on every width, orientation and theme.
- Change: remove that header and the per-project tiles. Keep headroom, total, used, available, storage folder, clear cache and retention.
- Do not change: those remaining rows and the folder picker.

### Rules
- FE-CONS-04: the screen still has a loaded body when volume stats exist.

### Steps
1. Remove the projects header and the loop over `view.projects`. Delete `_projectUse` when nothing else calls it.
2. Update `storage_settings_screen_test.dart` so a fixture project name is absent and Total, Used, Available and Clear cache remain.
3. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] Storage shows no Projects header and no per-project rows.
- [ ] Total, used, available, the storage folder, clear cache and retention still render.

## W11 — Open context setup from the project home
**Feedback:** FBK0000032, FBK0000042 · **Type:** Gap · **Priority:** P5 · **Effort:** S · **After:** W4

### Evidence
- FBK0000032: there is no way to choose which fields carry into the next capture, such as room and asset category, while another asset on the same visit uses a different category. The project home shows "No context".
- FBK0000042: capture should follow that context.
- The editor already exists at `ContextHierarchyScreen` (`AppRoutes` project `context`) and `showPinnedFieldsSheet`. Nothing on the project home navigates there.

### Scope
- Reach: project home on every width, orientation and theme. Capture keeps using the shell `ContextBar` from W4 once values exist.
- Change: `project_home_screen.dart` and `context_hierarchy_screen.dart`.
- Do not change: cascade rules, presets storage, and the default of zero levels from W4.

### Rules
- FE-SIMP-01: Continue capturing stays the only primary button.
- FE-CONS-01: `AppListTile` into the existing screens.

### Steps
1. On the project home, under the context caption, add an `AppListTile` titled `Copy.contextHierarchyTitle`. `onTap` goes to the open project's `/context` route.
2. On `ContextHierarchyScreen`, add an `AppListTile` titled `Copy.contextPinnedTitle` that calls `showPinnedFieldsSheet` for that project.
3. Widget-test the home tile opens the hierarchy route, and the hierarchy tile calls the pinned sheet.
4. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] From a project home, one tap opens context levels, where template fields can be added, ordered and removed.
- [ ] From that screen, one tap opens pinned fields.
- [ ] Continue capturing is still the primary action on the home.

## W12 — Reach templates and choose one in one step
**Feedback:** FBK0000031 · **Type:** Gap · **Priority:** P5 · **Effort:** L · **After:** W3

### Evidence
- FBK0000031: templates cannot be created, imported or edited from anywhere obvious. Starting a record should pick a template in one or two steps: auto when the project has one template, suggest, or manual. Fields should show which are required, which come from photos, and which are calculated.
- Templates already live at `/more/templates` with create, library, import and the field list. `TemplatePickerSheet` returns nothing when there is one template. `FieldDef.requiredness`, `FieldType.computed` and `TemplateDef.detection` already store the three roles. The settings list has no Templates row until W3 adds one. Capture never opens the picker.

### Scope
- Reach: Settings (W3's row plus the project home), project settings, capture start, and the field list, on every width, orientation and theme.
- Change: `ProjectSettings` (per D3), `project_settings_screen.dart`, `project_home_screen.dart`, `capture_screen.dart` after W3's `AppPage`, `field_list_screen.dart`, `Copy`.
- Do not change: field-add's three questions (label, type, required) and the detection-profile editor's save format.

### Rules
- FE-SIMP-05, FE-SIMP-06: one template is used without a question; further attributes stay on the field list.
- FE-L10N-07: template names and field labels stay user data.
- FE-STATE-07: per D3, an optional JSON key, no migration.

### Steps
1. Follow D3. Default (a): add `templateChoice` to `ProjectSettings` encode and decode. Absent key leaves the field null. Values are `auto`, `suggest` and `manual`. Unknown values decode as null.
2. On project settings, an `AppChoiceField` sets that key. Null is shown as Auto.
3. On the project home, an `AppListTile` titled `Copy.navTemplates` goes to `AppRoutes.templates`. Continue capturing stays the primary.
4. When capture opens, load `templateListProvider`. When `templateChoice` is null, and when it is `auto`, a single template is selected and `TemplatePickerSheet` is not built. More than one template opens the sheet. When `templateChoice` is `suggest`, the sheet opens with a preselected row: the pinned template when one is pinned, the most recently used template when none is pinned, the first template when none has been used. When `templateChoice` is `manual`, the sheet opens with no row selected and the tray ignores add until a row is chosen.
5. On each field row, extend the subtitle with `Copy.fieldRequired` when requiredness is required, a new `Copy` label when `field.type` is `FieldType.computed`, and a new `Copy` label when `template.detection` mentions `field.fieldKey`. The field-list overflow still opens Required columns and Detection profile.
6. Unit-test `ProjectSettings.decode` of an old JSON object without `templateChoice` yields null. Widget-test capture with one template shows no sheet, and with two templates and `manual` shows the sheet before the tray accepts a photo.
7. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] Settings and the project home each open the template list, whose create, library and import actions still work.
- [ ] A project with one template and Auto starts capture on that template with no sheet. Manual with two templates shows the sheet and does not add a photo before a choice.
- [ ] A required field, a computed field and a field named by the detection map each show that role on the field row.
- [ ] An existing project settings JSON without the new key still loads.

## W13 — Resume the open capture session
**Feedback:** FBK0000033 · **Type:** Gap · **Priority:** P5 · **Effort:** M · **After:** W2

### Evidence
- FBK0000033: closing a capture should keep it, and opening it later should continue from the same photos and captions. A new capture can start after that.
- `CapturePersistenceImpl.saveSession` / `loadSession` and `CaptureRecoveryPrompt` already exist. `CaptureScreen` never calls them. Per D2 the store stays one session per project.

### Scope
- Reach: capture on every platform and width. Leaving the route includes switching shell branch and popping.
- Change: `capture_screen.dart` after W2 and W3, using `CaptureController.replaceSession` and `CaptureRecoveryPrompt`.
- Do not change: the session JSON shape. Do not add a drafts list (D2 default).

### Rules
- FE-SEC-08: Start new discards only after the existing confirm dialog.
- FE-STATE-07: write through `saveSession` before the route is gone.

### Steps
1. Follow D2. The default uses the current `loadSession` / `saveSession` slot.
2. On first frame, `loadSession`. When the loaded session has any of a photo, a caption, and a field value, show `CaptureRecoveryPrompt`. Resume calls `replaceSession`. Discard calls the prompt's existing confirm, then clears the slot and starts an empty session.
3. On route dispose, and when the shell branch changes, `saveSession` with the current state when it has any of a photo, a caption, and a field value.
4. Widget-test: a stored session with one photo shows the prompt; Resume shows that photo; Discard after confirm shows the empty tray.
5. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] Leaving capture with a photo and returning to that project offers Resume, and Resume restores the photo and its caption.
- [ ] Start new asks before the stored session is cleared.
- [ ] No second session file is written.

## W14 — Apply a caption to one photo, a selection, or all
**Feedback:** FBK0000033 · **Type:** Gap · **Priority:** P5 · **Effort:** M · **After:** W2

### Evidence
- FBK0000033: a caption may apply to one photo, a subset, every photo, or a mix.
- `CaptionScope` (`thisPhoto`, `selected`, `all`) and `CaptionScopeSelector` exist. `PhotoCaptionSheet` edits one string. `PhotoTray` has `onLongPress` for selection but `CaptureScreen` does not pass it.

### Scope
- Reach: the capture tray on every width and orientation, 200 percent text.
- Change: `capture_screen.dart`, `photo_caption_sheet.dart`, `caption_scope_selector.dart`. The record caption field stays the record caption.
- Do not change: `CaptionApplyMode` and caption storage keys.

### Rules
- FE-CONS-01: use `CaptionScopeSelector`.
- FE-L10N-03: counts use the existing `Copy.captionScopeThis` helpers.

### Steps
1. Long-press a tray photo toggles `selectedIds`. Pass `onTap` to open `PhotoCaptionSheet` for that photo.
2. Put `CaptionScopeSelector` in the sheet. This photo writes that id. Selected writes each id in `selectedIds`, and is disabled at count 0. All writes every photo id in the session.
3. Save uses `CaptureController` caption writes so each targeted photo gets the same text. A failure snackbar leaves the previous captions in place.
4. Widget-test three photos: All sets three captions; Selected sets two; This photo sets one.
5. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] From a photo, captioning that photo, the current selection, and every photo in the session each writes those targets, and the tray shows the caption mark on each target.
- [ ] The record caption field still edits only the record caption.

## W15 — Crop a photo and type on a derived copy
**Feedback:** FBK0000033 · **Type:** Suggestion · **Priority:** P6 · **Effort:** M · **After:** W2

### Evidence
- FBK0000033: edit a photo by cropping and by typing on it.
- `PhotoViewerScreen` has `onCrop` and `PhotoCropScreen` is a placeholder that prints the id (`photo_crop_screen.dart:39`). Capture does not open the viewer. No annotation writer exists. `dart:ui` is already used to encode PNGs in `frontend/lib/core/files/compressed_copy.dart`.

### Scope
- Reach: the viewer and the crop screen on every width and orientation, including 200 percent text. No new package.
- Change: wire `PhotoTray.onTap` to `PhotoViewerScreen`, implement crop and a type action, and save a derived file through `CaptureController` without replacing the original path.
- Do not change: delete, retake, and the original file bytes.

### Rules
- FE-SEC-08: the original stays; crop and type write a derived copy beside it.
- FE-FLOW-06: no new dependency. Draw text with `dart:ui`.
- FE-THEME-01: no new literal colours in the crop chrome; use tokens.

### Steps
1. Tray tap opens `PhotoViewerScreen` for the session photos. Its crop action opens `PhotoCropScreen`.
2. `PhotoCropScreen` paints the photo. The user drags a rectangle inside the image. Save encodes that region to a new PNG, attaches it as a derived `PhotoDraft` linked to the source id, and leaves the source path unchanged. Revert drops that derived link.
3. Add a type action on the viewer. An `AppTextField` accepts the words. Save paints them on a copy of the current image with `dart:ui` and stores that PNG as another derived draft. The source file is unchanged.
4. Widget-test with a fake image: crop save adds a derived draft and the source path is the same; type save does the same; revert removes the derived link.
5. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] Cropping stores a new image and the original path is unchanged.
- [ ] Typing stores a new image that contains the typed words, and the original path is unchanged.
- [ ] Revert removes the derived link and the original still opens.

## Verification
- After the last item, `cd frontend && dart run tool/verify.dart` is green.
- Regenerate goldens with `--update-goldens` only if a golden fails because W3 changed a root status line or W4 changed a context chip that already had a value. List each regenerated file under the item that caused it. Do not regenerate the widget-gallery brand lockup goldens.
