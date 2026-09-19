# 004 — Move the storage root to public Documents

**Feedback:** FBK0000009 · **Type:** Defect · **Priority:** P3 · **Effort:** L · **Depends on:** 001, 002

## Goal
On Android 11 and later, the `Tapture/` evidence folder lives in shared storage at `Documents/Tapture/`.
A person can open it in the Files app, as specification §8 and task 065 require, and it survives an
uninstall. Other platforms keep their current location.

## Evidence
- FBK0000009: the reporter asks the app to stop storing files in restricted device folders, not only to
  stop downloading them there. No image. Android, mobile, compact, portrait, system dark, app 1.0.0.
- Root cause: `frontend/lib/core/files/storage_root.dart:93-102` resolves the root on Android with
  `getExternalStorageDirectories(type: StorageDirectory.documents)`. That is
  `Android/data/com.tapture.app/files/Documents/Tapture`, which the Files app cannot open on Android 11+
  and which Android deletes on uninstall.
- This contradicts `app-write-up.md` §8 ("a single app-visible root folder… reach them with a file
  manager or a USB cable") and task 065's Definition of done ("visible in a file manager").
- Today the tree holds only `.cache`: capture (phase 12) and projects (phase 08) are not built. This is
  the cheapest time to move it.

## Scope
- Change:
  - `frontend/android/app/src/main/kotlin/com/tapture/app/MainActivity.kt`: add
    `publicDocumentsPath` to the `com.tapture.app/files` channel from 002. It returns
    `Environment.getExternalStoragePublicDirectory(DIRECTORY_DOCUMENTS)` on API 30+, and an
    `unsupported` error below that.
  - `frontend/lib/core/files/storage_root.dart`: in `_platformDocumentsDirectory`, prefer that path on
    Android. If the channel reports `unsupported`, or the write probe fails, fall back to today's
    app-specific folder, so the root always resolves.
  - `frontend/test/core/files/storage_root_test.dart`: the tests below.
- Do not change: the database location (application support), the feedback `BlobStore`, downloads (002),
  iOS, desktop or web roots, `AndroidManifest.xml`, or any file already under `Android/data`. Nothing is
  moved or deleted.

## Rules
- FE-STR-11: native access stays in `core/files/` behind `StorageRoot`.
- FE-SEC-08 and rule 1 of the standard: raw evidence is never moved or deleted by this change.
- FE-CODE-06: a location that fails the probe is a `StorageFailure` only when the fallback fails too.
- FE-SEC-07 and task 235: no new permission.
- FE-L10N-11: paths stay ASCII.
- FE-TEST-03: seams, and no real shared storage in tests.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 23-hardening move-storage-root-to-public-documents "Move the storage root to public Documents"`
   (FE-FLOW-08).
2. On a test device, list the old root (for example with `adb shell ls` on
   `Android/data/com.tapture.app/files/Documents/Tapture`). Report what is there, then take the review
   below.
3. Add the channel method, and add a `publicDocuments` seam next to `documentsDirectory` so tests choose
   the branch.
4. Resolve in this order: public Documents, probe, and on failure the app-specific folder. Memoise
   whichever one succeeds, as `resolve()` does today.
5. Tests: the public folder is used when it is writable; an `unsupported` reply falls back; an
   unwritable public folder falls back; both unwritable returns `StorageFailure`; resolving twice
   returns the same directory.
6. Update the doc comment on `_platformDocumentsDirectory` to say why shared storage is used.

## Human review
⛔ Stop before step 3 and ask:
- Where should the Android root live? (a) public `Documents/Tapture` through direct file paths on API
  30+, falling back to the app folder below that; (b) keep the app folder and accept that it is hidden;
  (c) a folder the operator picks through the Storage Access Framework, which means rewriting every
  `dart:io` path in `core/files/`; or (d) `MANAGE_EXTERNAL_STORAGE`, which Play policy restricts.
  Recommend (a).
- With (a), after a reinstall the app cannot read the files that the old install created. The database
  lives in private storage and is wiped on uninstall, so no record points at them, and they stay visible
  to the operator. Is that acceptable? Recommend yes, and add a follow-up task if the orphan scanner (070)
  should skip unreadable files.
- If step 2 finds anything other than `.cache` in the old root, stop. Moving evidence needs its own task.
Proceed only with an explicit answer. If the answer is "proceed", do (a) and leave the old folder as it is.

## Acceptance criteria
- [ ] Android 11+: after a fresh install, opening Storage creates `Documents/Tapture/`, and the Files app
      shows it.
- [ ] Android 10 and below: the root resolves to the app folder, as it does today, and Storage works.
- [ ] If shared storage refuses the write, the app still resolves a root and stays usable.
- [ ] No file under `Android/data/com.tapture.app` is moved, changed or deleted.
- [ ] No permission is added, and no permission prompt appears.
- [ ] The Storage screen is unchanged in layout at every width and theme.
- [ ] FBK0000009 is resolved for stored files. 002 covers downloads.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- On an Android 11+ device: open Settings → Storage, then find Documents › Tapture in the Files app.
- No goldens change.
