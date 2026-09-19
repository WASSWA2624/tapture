# 313 — Add a Save to a folder option

**Phase** 23 · Hardening  |  **Depends on** [305](305-save-downloads-to-public-tapture-folder.md), [312](312-show-feedback-download-location.md), [282](282-in-app-feedback.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

On Android, Download feedback offers Save to a folder. The system save
picker opens with the archive name filled in, so the operator can put the
zip anywhere the picker reaches. Plain Download still saves to
`Download/Tapture`. Web, iOS and desktop do not show the control.

## Files

- `frontend/lib/core/files/download_service.dart`
- `frontend/lib/core/files/download_service_io.dart`
- `frontend/lib/core/files/download_service_web.dart`
- `frontend/lib/core/files/download_service_stub.dart`
- `frontend/android/app/src/main/kotlin/com/tapture/app/MainActivity.kt`
- `frontend/lib/features/feedback/presentation/download_feedback_controller.dart`
- `frontend/lib/features/feedback/presentation/download_feedback_screen.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/core/files/download_service_test.dart`
- `frontend/test/features/feedback/presentation/download_feedback_controller_test.dart`
- `frontend/test/features/feedback/presentation/download_feedback_screen_test.dart`
- `frontend/test/core/copy/copy_test.dart`

## Constraints

- The picker is reached only through `DownloadService` in `core/files/`
  (FE-STR-11).
- Download stays the one primary action; Save to a folder is a text button
  (FE-SIMP-01).
- No stored preference; each save asks (FE-SIMP-12).
- A `Result` for every outcome; the picker result is awaited (FE-CODE-06,
  FE-CODE-07).
- The write happens off the main thread (FE-PERF-02).
- No new package (FE-FLOW-06). Nothing is sent (FE-SEC-10).
- 48 dp and labelled (FE-A11Y-01, FE-A11Y-02).
- A fake service and a test channel handler (FE-TEST-03).
- Do not change the default Download path, the archive name or contents,
  web downloads, or Storage settings.

## Definition of done

- [x] Android `saveAs` starts `ACTION_CREATE_DOCUMENT` and returns the
      display name; `cancelled` is `CancelledFailure`; other errors are
      `downloadFailure`.
- [x] A cancel leaves the controller idle with no error; a success
      returns the name.
- [x] Save to a folder shows only when `canChooseLocation` is true; a tap
      calls `saveAs`; the footer does not overflow at 360 dp or 200 percent
      text.
- [x] Web, iOS and desktop report `canChooseLocation` false.
- [x] Copy: `feedbackSaveToFolder`.
