# 041 — Dialog, sheet, snackbar and banner services

**Phase** 03 · Design system  |  **Depends on** [031](031-theme-assembly.md), [032](032-breakpoints.md), [034](034-app-button.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The four ways the app interrupts or informs, each behind one API: alert and confirm dialogs, the standard sheet,
queued snackbars with undo, and the persistent banner. A feature never constructs `AlertDialog`,
`showModalBottomSheet`, `SnackBar` or `MaterialBanner` itself.

## Files

- `frontend/lib/core/widgets/feedback/app_dialog.dart` (new)
- `frontend/lib/core/widgets/feedback/app_bottom_sheet.dart` (new)
- `frontend/lib/core/widgets/feedback/app_snackbar.dart` (new)
- `frontend/lib/core/widgets/feedback/app_banner.dart` (new)

## Contract

```dart
Future<bool> showAppConfirm(BuildContext c, {required String title, required String message,
    required String confirmLabel, bool destructive = false});
Future<void> showAppAlert(BuildContext c, {required String title, required String message});
Future<T?> showAppSheet<T>(BuildContext c, {required String title, required WidgetBuilder builder});
enum SnackTone { info, success, warning, error }
void showAppSnack(BuildContext c, String message,
    {SnackTone tone = SnackTone.info, String? undoLabel, VoidCallback? onUndo});
class AppBanner extends StatelessWidget {
  final String message; final IconData icon; final SnackTone tone; final VoidCallback? onDismiss;
}
```

## Steps

1. Dialogs: the destructive variant requires an explicit action label and returns a typed result; cancel is always
   available and always returns false.
2. Sheet: drag handle, title, scrollable body, safe-area padding and the content constraint; on expanded layouts it
   presents as a side panel instead.
3. Snackbar: queue messages so they never overlap, with info, success, warning and error tones and an optional undo
   action.
4. Banner: sits under the app bar for offline and warning states, dismissible, and never takes focus.

## Constraints

- Tokens only, no literal colour, spacing, radius or duration; 48dp minimum target and a semantic label on every
  interactive element; nothing clips at 200 percent text scale (FE-THEME-01, FE-A11Y-01, FE-A11Y-02, FE-A11Y-03).
- All four get a gallery entry covering each tone and state, plus goldens in light, dark and outdoor (FE-CONS-03).
- One dialog API, one sheet API, one snackbar API; a destructive action always pairs a confirm with an undo
  (FE-CONS-05).
- Appearing and dismissing are announced to screen readers rather than left silent (FE-A11Y-07).

## Definition of done

- [ ] Delete flows across the app look and behave identically, and every destructive action can offer undo through one
      call.
- [ ] Pickers and option sheets share one presentation and become a side panel on expanded layouts.
- [ ] Offline state is visible through the banner without stealing focus from the field being edited.
- [ ] Tests: widget tests of the confirm and cancel paths, of undo invoking its callback, of two snacks queueing rather
      than overlapping, and of the sheet at compact and expanded widths; goldens of dialog, sheet, snack and banner in
      light, dark and outdoor.
