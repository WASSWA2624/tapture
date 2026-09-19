# 317 — Fix navigation icons and the Capture tab state

**Phase** 06 · Application shell  |  **Depends on** [073](073-nav-shell.md), [075](075-status-line.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Navigation uses widely recognised icons: a folder for Projects everywhere a project is meant. Only the
destination that is actually selected looks selected. Capture stays larger than its neighbours but no
longer wears the selected colour when another tab is active.

## Files

- `frontend/lib/app/nav_shell.dart`
- `frontend/lib/app/widgets/status_line.dart`
- `frontend/lib/app/router.dart`
- `frontend/test/app/nav_shell_test.dart`
- `frontend/test/app/widgets/status_line_test.dart`
- `dev-plan/06-app-shell/073-nav-shell.md`

## Constraints

- One icon per concept, from one family, at token sizes (FE-CONS-08, FE-THEME-08).
- Selection is shown by colour, the filled icon and the bar's indicator (FE-A11Y-05, FE-THEME-05).
- Still exactly four destinations (FE-SIMP-02).
- Tokens only; outdoor changes contrast, not shape (FE-THEME-01, FE-THEME-03).
- Do not change the four destinations, their order or labels, the rail inversion rules, the list pane,
  or Capture's size.

## Definition of done

- [x] Projects shows a folder in the bar and the rail, and the status line's project item shows the same
      folder.
- [x] With any tab other than Capture selected, the camera is larger but not accent-coloured.
- [x] With Capture selected, it is accent-coloured and filled.
- [x] Tests at 400, 800 and 1200 dp: Capture size dominance; accent only when Capture is selected;
      Projects `folder_outlined` / `folder`; the status line project item is the folder.
