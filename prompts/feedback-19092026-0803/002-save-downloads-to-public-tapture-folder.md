# 002 — Save downloads to a public Tapture folder

**Feedback:** FBK0000009, FBK0000010 · **Type:** Defect · **Priority:** P3 · **Effort:** M · **Depends on:** —

## Goal
On Android 10 and later, Download feedback saves the archive to `Download/Tapture/` in shared storage,
where the Files app shows it and it survives an uninstall. The success message names that place in words
a person can follow. This applies at every width and in every theme.

## Evidence
- FBK0000009: the reporter asks the app to stop saving or downloading into device folders that are
  restricted. No image. Android, mobile, compact, portrait, system dark, app 1.0.0.
- FBK0000010: the reporter asks for downloads to go into a subfolder named after the app at the root of
  the device's Downloads folder. `screenshots/FBK0000010.png` shows only the Projects screen Feedback was
  tapped on. Same device profile.
- Root cause: `frontend/lib/core/files/download_service_io.dart:19-29` uses `getDownloadsDirectory()`.
  On Android, `path_provider_android` 2.2.23 (pinned in `frontend/pubspec.yaml`) resolves that to
  `getExternalFilesDirs(DIRECTORY_DOWNLOADS)`, which is `Android/data/com.tapture.app/files/Download`.
  That folder is app-private: the Files app cannot open it on Android 11+, and uninstalling deletes it.
  `download_feedback_screen.dart:110-119` then shows that raw absolute path in a snackbar.

## Scope
- Change:
  - `frontend/android/app/src/main/kotlin/com/tapture/app/MainActivity.kt`: add a `MethodChannel`
    `com.tapture.app/files` with a `saveToDownloads` method (`fileName`, `mimeType`, `bytes`). On API
    29+, it inserts into `MediaStore.Downloads` with `RELATIVE_PATH` `Download/Tapture` and
    `IS_PENDING`, writes on a background thread, clears `IS_PENDING`, and replies with
    `Download/Tapture/<display name>` (MediaStore numbers a clash). Below API 29 it replies with an
    `unsupported` error.
  - `frontend/lib/core/files/download_service_io.dart`: on Android, call the channel, and fall back to
    the current folder writer on `unsupported` or any error. On Windows, macOS and Linux, write to
    `<Downloads>/Tapture/`. iOS is unchanged. Add a test seam that takes a `MethodChannel` and a fallback.
  - `frontend/lib/core/files/download_service.dart`: doc comments only. `save` still succeeds with
    where the file went.
  - `frontend/test/core/files/download_service_test.dart` (new).
- Do not change: web (the browser decides), iOS, `FeedbackArchive` or the archive name, the Download
  screen layout (prompts 009 and 010), `StorageRoot` (prompt 004), or `AndroidManifest.xml`.

## Rules
- FE-STR-11: native access stays behind `DownloadService` in `core/files/`, and no feature calls the
  channel.
- FE-CODE-06: every failure is a `Result`. FE-CODE-08: never log bytes or file names.
- FE-PERF-02: the native write runs off the main thread.
- FE-SEC-10: nothing leaves the device. Task 235: no new permission.
- FE-L10N-01 and FE-L10N-11: reuse `Copy.feedbackDownloadedTo`, and keep the ASCII file name.
- FE-TEST-03: drive the channel with a test method-call handler. Never touch a real Downloads folder.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 23-hardening save-downloads-to-public-tapture-folder "Save downloads to a public Tapture folder"`
   (FE-FLOW-08).
2. Read `MainActivity.kt` and `download_service_io.dart` as they are now, then take the review below.
3. Add the Kotlin channel handler to `MainActivity.configureFlutterEngine`, and keep it under about 60
   lines.
4. In `download_service_io.dart`, route Android through the channel with its fallback. Make the folder
   writer create a `Tapture` subfolder on desktop, and keep the `.part` then rename, and the numbering.
5. Tests in `download_service_test.dart`:
   - the folder writer saves into `<folder>/Tapture/` and numbers a second file with the same name;
   - the channel path returns the location the handler replies with;
   - an `unsupported` reply and a thrown `PlatformException` both fall back to the folder writer;
   - a write failure returns `downloadFailure(fileName)`.

## Human review
⛔ Stop before step 3 and ask:
- Native code: (a) a small `MethodChannel` in `MainActivity.kt` with no new dependency, or (b) a pub
  package for MediaStore (FE-FLOW-06: its own task and an allowlist entry)? Recommend (a).
- Android 9 and below: (a) keep the current app folder, which file managers can open on those versions,
  or (b) add `WRITE_EXTERNAL_STORAGE` with `maxSdkVersion="28"`? Recommend (a), so no permission is added.
- Desktop: use `Downloads/Tapture/` on Windows, macOS and Linux too? Recommend yes, so one rule holds on
  every device.
Proceed only with an explicit answer. If the answer is "proceed", take every recommendation.

## Acceptance criteria
- [ ] Android 10+: the archive lands in `Download/Tapture/`, and the Files app shows it under Downloads ›
      Tapture.
- [ ] The snackbar reads "Saved to Download/Tapture/TAPTURE-DDMMYYYY-HHMM.zip", not an `Android/data`
      path.
- [ ] A second download in the same minute is saved under a numbered name, and nothing is overwritten.
- [ ] Android 9 and below still save successfully, and the snackbar names where.
- [ ] Windows, macOS and Linux save to `Downloads/Tapture/`. Web and iOS behave as before.
- [ ] A failed write shows the existing download error, and the Download screen stays open.
- [ ] `AndroidManifest.xml` gains no permission.
- [ ] The snackbar text wraps without clipping at compact width and 200 percent text, in light, dark and
      outdoor.
- [ ] FBK0000010 is resolved. FBK0000009 is resolved for downloads, and prompt 004 covers stored files.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- On an Android 11+ device: download feedback, then open Files → Downloads → Tapture and find the zip.
- No goldens change.
