# 034 — Fix feedback camera browse

**Phase** 23 · Hardening  |  **Depends on** [026](026-in-app-feedback.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

On Give us feedback, the camera control opens a camera session (webcam on
desktop web) and attaches one photo. It never opens the library file picker.
Where a camera session cannot be opened, the control is hidden and Choose
photo remains.

## Files

- `frontend/lib/core/files/photo_picker.dart`
- `frontend/lib/core/files/photo_picker_io.dart`
- `frontend/lib/core/files/photo_picker_web.dart`
- `frontend/lib/core/files/photo_picker_stub.dart`
- `frontend/lib/core/constants/app_constants.dart`
- `frontend/test/core/files/photo_picker_test.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

## Constraints

- Platform picker stays inside `PhotoPicker` (FE-STR-11).
- Camera and library stay distinct controls (FE-CONS-08).
- Camera is used only on an explicit tap; no new egress or package (FE-SEC-07,
  FE-FLOW-06).
- Tests use fakes; they never open a real camera (FE-TEST-03, FE-TEST-10).

## Definition of done

- [x] Tapping camera opens a camera/webcam session when one exists, not the library file picker.
- [x] When no camera session is possible, `Copy.feedbackTakePhoto` is absent and `Copy.feedbackChoosePhoto` still adds images.
- [x] A refused camera still shows `Copy.photoNoAccess` and adds no shot.
- [x] Tests: a picker that can only browse reports `canTakePhoto: false`; existing Give us feedback camera tests still pass.
