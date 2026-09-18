# 296 — Add other window screenshot

**Phase** 23 · Hardening  |  **Depends on** [282](282-in-app-feedback.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Give us feedback can attach one still of another window the operator picks
in the browser display picker. The control is hidden where the platform
cannot share a display.

## Files

- `frontend/lib/core/files/screen_capture.dart`
- `frontend/lib/core/files/screen_capture_web.dart`
- `frontend/lib/core/files/screen_capture_io.dart`
- `frontend/lib/core/files/screen_capture_stub.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/features/feedback/presentation/feedback_providers.dart`
- `frontend/lib/features/feedback/presentation/give_feedback_controller.dart`
- `frontend/lib/features/feedback/presentation/feedback_shots.dart`
- `frontend/lib/main.dart`
- `frontend/test/core/files/screen_capture_test.dart`
- `frontend/test/core/copy/copy_test.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

## Constraints

- Display APIs live only in the core service; tests use a fake
  (FE-STR-11, FE-TEST-03).
- No new pub package. Web uses `dart:js_interop` like the download
  service (FE-FLOW-06).
- Local, on an explicit tap; stop every media track after one frame;
  never log or upload the pixels (FE-SEC-04, FE-SEC-07, FE-SEC-10).
- `AppIconButton` with a different icon from Add this screen
  (FE-CONS-01, FE-CONS-08).
- Cap with `FeedbackShotFit.cap` (FE-PERF-04).
- Hide the control when `canCapture` is false. Do not change Add this
  screen, camera, library, max shots or the workbook.

## Definition of done

- [x] On a capture-capable fake, one labelled control attaches a still
      and turns attach on.
- [x] The stream is not left running after the still, cancel or refusal.
- [x] Where `canCapture` is false, the control is absent; Add this
      screen, camera and Choose photos still work.
- [x] Compact 360 dp does not overflow the shots row.
- [x] Tests: fake one frame, cancel, refusal, hidden; widget tap adds
      one shot; refusal shows copy and adds nothing.
