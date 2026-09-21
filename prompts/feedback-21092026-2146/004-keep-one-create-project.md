# 004 — Keep one create project

**Feedback:** FBK0000022, FBK0000024 · **Type:** Improvement · **Priority:** P4 · **Effort:** S · **Depends on:** none

## Goal
Each Projects surface shows one Create a project control. Compact and medium use the footer primary. Expanded uses the pane button. The empty state does not add a second one.

## Evidence
- FBK0000024: repeated controls, the Create a project button in particular, crowd the screen. `prompts/TAPTURE-21092026-2146/screenshots/FBK0000024.png` shows an add icon in the title row and a full-width Create a project footer. Android, compact, portrait, dark.
- FBK0000022: the same Projects screen, asked for as a layout fix. Spacing of the title-row pair is prompt 003. The nav count is prompt 005.
- Root cause: compact and medium render `ProjectListActions.barActions` (`frontend/lib/features/projects/presentation/project_list_actions.dart:31`) and, when the list has loaded, `AppPrimaryAction` (`frontend/lib/features/projects/presentation/project_list_screen.dart:57`). The empty list also offers `Copy.projectsCreate` (`frontend/lib/features/projects/presentation/project_list_view.dart:95`). Expanded with rows already hides the footer (`!expanded` is false).

## Scope
- Reach: compact, medium and expanded, both orientations, all themes, all platforms. The create action still exists on each of them.
- Change: `ProjectListScreen`, `ProjectListActions`, `ProjectListView` empty state.
- Do not change: project row menus, search, numbering, or the expanded pane's show-archived action.

## Rules
- FE-SIMP-01: one primary, the large lower control on compact and medium.
- FE-SIMP-11: an empty list still offers create, once.
- FE-L10N-01: keep `Copy.projectsCreate`.
- FE-CONS-02: both layouts call `ProjectListActions.create`.
- FE-TEST-01, FE-TEST-02.

## Steps
1. Record the work under `06-app-shell`, or `cd frontend && dart run tool/new_task.dart 06-app-shell one-create-project "One create-project control"` (FE-FLOW-08).

## Human review
⛔ Stop before step 2 and ask:
- FBK0000023 (prompt 003) wants the title-row add control and the more control spaced apart. FBK0000024 wants the duplicate create removed. FE-SIMP-01 puts the primary in the lower third.
  - A) Compact and medium: footer `AppPrimaryAction` only; remove the title-row add. Expanded: pane button only. Empty list: one create (the footer on compact and medium, the empty-state action on expanded), never both.
  - B) Keep the title-row add and the pane button; remove the footer whenever another create is visible.
- Recommendation: A. If the answer is "proceed", do A. Prompt 003's gap stays in `AppPage` either way.

2. Apply the chosen option in `ProjectListScreen.footer`, `ProjectListActions.barActions` and `ProjectListView._empty`.
3. Update `frontend/test/features/projects/presentation/project_list_screen_test.dart` and `frontend/test/app/nav_shell_test.dart` (`at 1200 dp with no projects the body keeps Create a project`) so each width finds `Copy.projectsCreate` once.

## Acceptance criteria
- [ ] Compact and medium, with rows and without, show one Create a project control.
- [ ] Expanded, with rows and without, shows one Create a project control, in the pane or the empty state, not both.
- [ ] Choosing that control still opens `/projects/new`.
- [ ] FBK0000024 is resolved. FBK0000022 is resolved together with prompt 003.

## Verification
- `cd frontend && dart run tool/verify.dart --fast`, then `dart run tool/verify.dart`.
- `--update-goldens` only for projects-list goldens that showed two create controls. List the files.
