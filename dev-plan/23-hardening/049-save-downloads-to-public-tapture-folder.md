# 049 — Save downloads to a public Tapture folder

**Phase** 23 · Hardening  |  **Depends on** [026](026-in-app-feedback.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

On Android 10 and later, Download feedback saves the archive to
`Download/Tapture/` in shared storage, where the Files app shows it and it
survives an uninstall. The success message names that place. Desktop writes
to `Downloads/Tapture/`. Android 9 and below keep the app folder, with no
new permission.

## Files

- `frontend/android/app/src/main/kotlin/com/tapture/app/MainActivity.kt`
- `frontend/lib/core/files/download_service.dart`
- `frontend/lib/core/files/download_service_io.dart`
- `frontend/test/core/files/download_service_test.dart`

## Constraints

- Native access stays behind `DownloadService` in `core/files/` (FE-STR-11).
- Every failure is a `Result`; never log bytes or file names (FE-CODE-06,
  FE-CODE-08).
- The native write runs off the main thread (FE-PERF-02).
- Nothing leaves the device; add no permission (FE-SEC-10, task 235).
- Reuse `Copy.feedbackDownloadedTo`; keep the ASCII file name (FE-L10N-01,
  FE-L10N-11).
- Drive the channel with a test handler; never touch a real Downloads
  folder (FE-TEST-03).
- Do not change web, iOS, `FeedbackArchive`, the Download screen layout,
  `StorageRoot`, or `AndroidManifest.xml`.

## Definition of done

- [x] Android 10+ saves through MediaStore to `Download/Tapture/` and
      returns that display path.
- [x] The folder writer saves into `<folder>/Tapture/` and numbers a clash.
- [x] An `unsupported` reply and a `PlatformException` both fall back to the
      folder writer.
- [x] A write failure returns `downloadFailure(fileName)`.
- [x] Tests: folder writer Tapture + numbering; channel location;
      unsupported and exception fallback; write failure.
