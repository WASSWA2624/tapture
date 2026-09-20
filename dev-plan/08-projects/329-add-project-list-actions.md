# 329 — Add project list actions and numbering

**Phase** 08 · Projects  |  **Depends on** [083](083-project-list.md), [314](314-add-project-management-actions.md), [326](../03-design-system/326-add-borderless-overflow-control.md), [327](327-add-project-pinning.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The project list carries create and a more menu holding Show archived — in the expanded pane
header and in the compact/medium title bar, from one shared list — and each row is numbered in
display order and offers a borderless menu of Rename, Pin, Archive and Delete.

## Files

- `frontend/lib/features/projects/presentation/project_list_actions.dart`
- `frontend/lib/features/projects/presentation/project_rename_action.dart`
- `frontend/lib/features/projects/presentation/project_list_view.dart`
- `frontend/lib/features/projects/presentation/project_list_screen.dart`
- `frontend/lib/features/projects/projects.dart`
- `frontend/lib/app/nav_shell.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/app/nav_shell_test.dart`
- `frontend/test/app/nav_pane_golden_test.dart`
- `frontend/test/features/projects/presentation/project_list_screen_test.dart`
- `frontend/test/features/projects/presentation/project_list_view_test.dart`
- `frontend/test/features/projects/presentation/project_rename_action_test.dart`
- `frontend/test/features/projects/presentation/project_list_golden_test.dart`
- `frontend/test/core/copy/copy_test.dart`

## Constraints

- One actions list feeds the pane and the title bar (FE-RESP-02). No `MediaQuery` width comparison.
- Show archived lives only in the more menu, with its on/off state visible, at every width.
- The filter control is omitted: Show archived is the only filter today.
- Row numbers are the position in the current filtered, sorted list (FE-L10N-04).
- The three-dot control is the only way into the row menu (FE-CONS-10). No "Open with".
- Rename uses the shared dialog API and does not move `folderName`. Pin reuses `setPinned`.
- Catalogue widgets only: `AppOverflowMenu`, `AppIconButton`, `AppButton`, `AppListTile`, `AppPage`.

## Definition of done

- [x] At 1200 dp the pane header offers create and the more menu above search.
- [x] At 400 and 800 dp the same actions are reachable from the list screen title bar.
- [x] Show archived appears only in that menu, reflects its state, and still filters the list.
- [x] Rows are numbered from 1 in display order and renumber when search, filter or pin changes.
- [x] Each row menu is borderless and offers Rename, Pin or Unpin, Archive or Unarchive, and Delete.
- [x] Rename saves without moving the folder and cancels cleanly.
- [x] Pin moves the row to the top.
- [x] New controls meet 48 dp, label, tooltip and contrast matchers.
- [x] Nothing clips at 200 percent text. In RTL the number leads and the menu sits at the end.
- [x] Long-press does not open the row menu.
