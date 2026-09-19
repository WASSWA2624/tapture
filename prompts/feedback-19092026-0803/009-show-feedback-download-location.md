# 009 — Show the feedback download location

**Feedback:** FBK0000006 · **Type:** Improvement · **Priority:** P5 · **Effort:** M · **Depends on:** 002

## Goal
Download feedback says where archives are saved before anything is downloaded. On Android and desktop it
also offers **Open folder**. The operator can find past downloads without remembering a snackbar. The
screen works at compact, medium and expanded widths, in light, dark and outdoor, and at 200 percent text.

## Evidence
- FBK0000006: the reporter wants a way to see where feedback downloads are saved, or to go straight to
  that folder. `screenshots/FBK0000006.png` shows the Storage screen the reporter was on; nothing there
  mentions downloads. Android, mobile, compact, portrait, system dark.
- Today the only trace is a snackbar, `Copy.feedbackDownloadedTo(path)`, shown as the Download screen
  closes (`frontend/lib/features/feedback/presentation/download_feedback_screen.dart:110-119`). The
  screen itself (`:24-100`) never says where files go, and nothing opens the folder.
- After 002, archives land in `Download/Tapture/` on Android 10+ and `Downloads/Tapture/` on desktop.

## Scope
- Change:
  - `frontend/lib/core/files/download_service.dart`: add `String? get destination` (a short label, null
    where the browser decides), `bool get canOpenFolder` and `Future<Result<void>> openFolder()`. Let
    `DownloadService.fake` take values for these.
  - `download_service_io.dart`:
    - Android calls `openDownloads` on the `com.tapture.app/files` channel.
    - Windows, macOS and Linux run `explorer`, `open` or `xdg-open`, with the folder as a separate
      argument, through an injectable runner.
    - iOS reports `canOpenFolder` false.
  - `download_service_web.dart` and `download_service_stub.dart`: `destination` is null and
    `canOpenFolder` is false.
  - `frontend/android/app/src/main/kotlin/com/tapture/app/MainActivity.kt`: `openDownloads` starts
    `DownloadManager.ACTION_VIEW_DOWNLOADS`.
  - `download_feedback_controller.dart`: an `openFolder()` intent that returns a `Result`.
  - `download_feedback_screen.dart`: above the footer, show `Copy.feedbackDownloadsGoTo(destination)`,
    plus an `AppButton` (text variant) for `Copy.feedbackOpenFolder` when `canOpenFolder` is true.
  - `copy.dart`: add `downloadsTaptureFolder` ("Downloads › Tapture"), `feedbackDownloadsGoTo(place)`,
    `feedbackOpenFolder` ("Open folder") and `feedbackOpenFolderFailed`.
- Do not change: where files are saved (002), the success snackbar's API, Storage settings, or the
  primary Download action.

## Rules
- FE-STR-11: intents and processes live only in `core/files/`. FE-SEC-05: pass the path as an argument,
  never through a shell string.
- FE-STATE-04: the screen calls the controller, and the controller calls the service.
- FE-SIMP-01: Download stays the only primary action, and Open folder is a text button.
- FE-CODE-06 and FE-CONS-11: a failed open is a `Result`, shown as a warning snack.
- FE-L10N-01, FE-L10N-03 and FE-L10N-05: strings from `Copy`, placeholders rather than concatenation,
  and the "›" separator mirrors correctly in right-to-left layouts.
- FE-A11Y-01 and FE-A11Y-02: 48 dp and labelled.
- FE-TEST-03: fakes for the channel and the process runner.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 23-hardening show-feedback-download-location "Show the feedback download location"`
   (FE-FLOW-08).
2. Extend `DownloadService` and its fake, then the IO, web and stub implementations.
3. Add `openDownloads` next to `saveToDownloads` in `MainActivity.kt`.
4. Add the controller intent, and the caption and button on the screen.
5. Tests:
   - `frontend/test/core/files/download_service_test.dart`: desktop runs the right command with the
     folder argument; Android invokes `openDownloads`; a failing runner or channel returns a failure.
   - `frontend/test/features/feedback/presentation/download_feedback_screen_test.dart`: the caption shows
     the destination; Open folder shows only when supported; a tap calls the service; a failure shows
     the warning snack; with a null destination, no caption shows.
   - `frontend/test/core/copy/copy_test.dart` for the new strings.

## Human review
⛔ Stop before step 2 and ask:
- The reporter was on Storage settings. Also add a read-only "Feedback downloads" row there? Recommend
  no, because the Download screen is where downloading happens.
- Add an **Open** action to the success snackbar? That means generalising `showAppSnack`'s `undoLabel`
  and `onUndo`, which is a public `core/` API change. Recommend no; Open folder lives on the screen.
- Android has no reliable intent that opens one subfolder, so `ACTION_VIEW_DOWNLOADS` opens the system
  Downloads view. Accept that? Recommend yes.
Proceed only with an explicit answer. If the answer is "proceed", take every recommendation.

## Acceptance criteria
- [ ] Android and desktop: Download feedback reads "Downloads go to Downloads › Tapture" before anything
      is downloaded.
- [ ] Open folder opens the system Downloads view on Android and the `Downloads/Tapture` folder on
      Windows, macOS and Linux.
- [ ] Web and iOS show no Open folder. Web shows no location line.
- [ ] If the folder cannot be opened, a warning names where to look, and nothing else changes.
- [ ] No clipping at 360 dp, 200 percent text or in landscape, in light, dark and outdoor.
- [ ] FBK0000006 is resolved.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- On Android and Windows: open Download feedback, read the location, and tap Open folder.
- No goldens change.
