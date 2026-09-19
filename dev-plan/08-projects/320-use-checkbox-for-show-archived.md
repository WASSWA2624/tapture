# 320 — Use a checkbox for Show archived

**Phase** 08 · Projects  |  **Depends on** [083](083-project-list.md), [087](087-project-archive.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The Projects list filter "Show archived" is a two-state checkbox with its label, not a switch. The
row is inset like other tiles, so the label is not flush with the screen edge.

## Files

- `frontend/lib/features/projects/presentation/project_list_screen.dart`
- `frontend/test/features/projects/presentation/project_list_screen_test.dart`
- `frontend/test/features/projects/presentation/project_archive_action_test.dart`

## Constraints

- Reuse `AppSwitchTile.checkbox`; build no new control (FE-CONS-01).
- A tap on the row or the box toggles it (FE-CONS-10).
- 48 dp, labelled, and the state is shown by the tick as well as colour (FE-A11Y-01, FE-A11Y-02,
  FE-A11Y-05).
- The control sits at the start in both text directions (FE-L10N-05).
- Do not change `projectListShowArchivedProvider`, the filter logic, the copy, or other switches
  in the app.

## Definition of done

- [x] Projects shows a checkbox labelled "Show archived", unticked by default.
- [x] Ticking it lists archived projects, and unticking hides them again.
- [x] The label no longer sits flush against the screen edge, and the row is inset like other tiles.
- [x] Tests: ticking shows archived rows and unticking hides them; the tile passes the 48 dp and
      label matchers; no overflow at 360 dp and 200 percent text.
