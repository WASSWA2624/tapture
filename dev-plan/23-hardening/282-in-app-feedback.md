# 282 — In-app feedback: floating button, capture, download and delete

**Phase** 23 · Hardening  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A draggable floating Feedback control on every shell screen. Desktop hides the label until hover; phone and tablet
stay icon-only. The menu offers Give us feedback, Download feedback and Delete feedback. Give opens a dialog on a
desktop with room and a screen on a phone or tablet: type (General, Improvement, Error, Suggestion, Other with a
name), the written note, and an optional screenshot of the screen Feedback was tapped on. Each entry is stored on
this device with the context the organisation's workbook already names. Download filters the store and writes
`TAPTURE-DDMMYYYY-HHMM.xlsx`. Delete filters, ticks rows, and confirms before the entries are gone.

## Files

- `frontend/lib/core/widgets/app_floating_button.dart`
- `frontend/lib/core/widgets/feedback/app_panel_dialog.dart`
- `frontend/lib/core/widgets/responsive/form_factor.dart`
- `frontend/lib/core/widgets/responsive/viewport_metrics.dart`
- `frontend/lib/core/export/` (existing encoder)
- `frontend/lib/features/feedback/` (domain, data, presentation)
- `frontend/lib/app/feedback_host.dart`
- `frontend/lib/app/nav_shell.dart` (wraps the shell in `FeedbackHost`)
- `frontend/lib/main.dart` (production overrides)

## Constraints

- Reuse the existing feedback domain, workbook layout, copy catalogue and xlsx encoder (FE-CONS-01).
- The shell builds `FeedbackOrigin`; the feature never reads the router (FE-STR-04).
- Default repository and downloads are in-memory / fake so tests never open a folder (FE-TEST-03).
- Presentation does not call `setState` (FE-STATE-01). Tokens only (FE-CONS-02).

## Definition of done

- [x] The floating control is draggable. Desktop shows the label on hover; phone and tablet do not.
- [x] Give, download and delete each open a dialog on desktop and a screen on phone and tablet.
- [x] Give stores the typed note, type (including a named Other) and optional screenshot with the Excel-column context.
- [x] Download writes `TAPTURE-DDMMYYYY-HHMM.xlsx` for the filtered rows.
- [x] Delete filters, selects, confirms, then removes; undo restores what was just deleted.
- [x] Tests: domain unit tests, in-memory repository tests, widget tests for the floating button, panel, form factor
      and viewport metrics, and screen tests for give, download and delete.
