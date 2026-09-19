# 312 — Show the feedback download location

**Phase** 23 · Hardening  |  **Depends on** [305](305-save-downloads-to-public-tapture-folder.md), [282](282-in-app-feedback.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Download feedback names where archives land before anything is downloaded.
On Android and desktop it also offers Open folder. The operator can find
past downloads without remembering a snackbar. Web and iOS keep no Open
folder; web has no location line.

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
- `frontend/test/features/feedback/presentation/download_feedback_screen_test.dart`
- `frontend/test/core/copy/copy_test.dart`

## Constraints

- Intents and processes live only in `core/files/` (FE-STR-11). Pass the
  path as an argument, never through a shell string (FE-SEC-05).
- The screen calls the controller; the controller calls the service
  (FE-STATE-04).
- Download stays the only primary action; Open folder is a text button
  (FE-SIMP-01).
- A failed open is a `Result`, shown as a warning snack (FE-CODE-06,
  FE-CONS-11).
- Strings from `Copy`, placeholders rather than concatenation, and the ›
  separator uses start/end layout so it mirrors in RTL (FE-L10N-01,
  FE-L10N-03, FE-L10N-05).
- 48 dp and labelled (FE-A11Y-01, FE-A11Y-02).
- Fakes for the channel and the process runner (FE-TEST-03).
- Do not change where files are saved, the success snackbar's API, Storage
  settings, or the primary Download action.

## Definition of done

- [x] Android and desktop show "Downloads go to Downloads › Tapture" before
      a download.
- [x] Open folder invokes `openDownloads` on Android and `explorer` /
      `open` / `xdg-open` with the folder argument on desktop.
- [x] Web and iOS report no Open folder; web has a null destination.
- [x] A failing runner or channel returns a failure; the screen shows a
      warning that names the folder.
- [x] Tests: desktop command; Android channel; failing runner and channel;
      caption; Open folder visibility; tap; warning snack; null destination;
      copy strings.
