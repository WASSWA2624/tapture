# 010 — Add a Save to a folder option

**Feedback:** FBK0000008 · **Type:** Suggestion · **Priority:** P6 · **Effort:** M · **Depends on:** 002, 009

## Goal
On Android, Download feedback offers **Save to a folder**. It opens the system save picker with the
archive's name filled in, so the operator can put it anywhere the picker reaches: internal storage, an
SD card or a cloud provider's folder. Plain Download still saves to `Download/Tapture` (002). The footer
fits at every width and theme, and at 200 percent text.

## Evidence
- FBK0000008: the reporter suggests choosing where the feedback archive is saved when exporting it. No
  image. Android, mobile, compact, portrait, system dark, app 1.0.0.
- Today the folder is fixed. `DownloadService.save` (`frontend/lib/core/files/download_service.dart:28-34`)
  takes only a name, bytes and a type. `download_service_io.dart:19-29` picks the folder, and after 002
  it is always `Download/Tapture`.
- The Download screen has a single action (`frontend/lib/features/feedback/presentation/download_feedback_screen.dart:70-78`).
  009 adds the location line and Open folder.

## Scope
- Change:
  - `download_service.dart`: add `bool get canChooseLocation` and
    `Future<Result<String?>> saveAs({required String fileName, required Uint8List bytes, required String mimeType})`.
    It succeeds with the saved file's display name, or fails with `CancelledFailure` when the picker is
    dismissed. Extend `DownloadService.fake`.
  - `frontend/android/app/src/main/kotlin/com/tapture/app/MainActivity.kt`: add `saveAs` to the
    `com.tapture.app/files` channel. It starts `ACTION_CREATE_DOCUMENT` (`application/zip`,
    `EXTRA_TITLE` = file name). On OK it writes through `contentResolver.openOutputStream` on a background
    thread; on cancel it replies `cancelled`.
  - `download_service_io.dart`: Android calls the channel; every other platform reports
    `canChooseLocation` false. The web and stub files report false.
  - `download_feedback_controller.dart`: `download(matching, {bool chooseLocation = false})`. A cancel
    returns to idle with no error.
  - `download_feedback_screen.dart`: an `AppButton` (text variant) labelled `Copy.feedbackSaveToFolder`
    beside Open folder, shown only when `canChooseLocation` is true.
  - `copy.dart`: add `feedbackSaveToFolder` ("Save to a folder").
- Do not change: the default Download path (002), the archive's name or contents, web downloads, or
  Storage settings. Remember no chosen folder.

## Rules
- FE-STR-11: the picker is reached only through `DownloadService` in `core/files/`.
- FE-SIMP-01: Download stays the one primary action, and Save to a folder is a text button.
- FE-SIMP-12: no stored preference; each save asks.
- FE-CODE-06 and FE-CODE-07: a `Result` for every outcome, and the picker result is awaited.
- FE-PERF-02: the write happens off the main thread.
- FE-FLOW-06: no new package without its own task.
- FE-SEC-10: nothing is sent; the operator picks the place.
- FE-A11Y-01 and FE-A11Y-02: 48 dp and labelled.
- FE-TEST-03: a fake service and a test channel handler.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 23-hardening add-save-to-folder-option "Add a Save to a folder option"`
   (FE-FLOW-08).
2. Extend `DownloadService` and its fake, then add the Android channel method and the Dart call.
3. Add the controller parameter, and the footer button laid out as a wrapping row with Open folder.
4. Tests:
   - `frontend/test/core/files/download_service_test.dart`: `saveAs` returns the handler's name; a
     `cancelled` reply is `CancelledFailure`; an error is `downloadFailure`.
   - `frontend/test/features/feedback/presentation/download_feedback_controller_test.dart`: a cancel
     leaves `busy` false and `error` null; a success returns the name.
   - `download_feedback_screen_test.dart`: the button shows only when `canChooseLocation` is true; a tap
     calls `saveAs`; the footer does not overflow at 360 dp or 200 percent text.
   - `frontend/test/core/copy/copy_test.dart` for the new key.

## Human review
⛔ Stop before step 2 and ask:
- Which platforms get it? (a) Android only, through the system picker, with no new dependency; (b) also
  desktop, through `file_selector` (FE-FLOW-06: its own task and an allowlist entry); or (c) also web,
  through `showSaveFilePicker` where the browser supports it. Recommend (a), because the report came from
  Android. Open (b) or (c) as separate tasks if wanted.
Proceed only with an explicit answer. If the answer is "proceed", do (a).

## Acceptance criteria
- [ ] Android: Save to a folder opens the system picker with `TAPTURE-DDMMYYYY-HHMM.zip` filled in, and
      the zip is written where the operator chose.
- [ ] After a save, the snackbar names the file. Backing out of the picker saves nothing, shows no error
      and keeps the screen open.
- [ ] Plain Download still saves to `Download/Tapture`.
- [ ] Web, iOS and desktop show no Save to a folder (under the default answer).
- [ ] No permission and no dependency are added.
- [ ] The footer fits at 360 dp, in landscape and at 200 percent text, in light, dark and outdoor.
- [ ] FBK0000008 is resolved.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- On an Android phone: Download feedback → Save to a folder → choose Documents; then find the zip there
  in the Files app.
- No goldens change.
