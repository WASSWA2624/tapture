# 007 — Open a project's files in an external app

**Feedback:** FBK0000006 · **Type:** Suggestion · **Priority:** P6 · **Effort:** M · **Depends on:** —

## Goal
A project's more menu offers "Open with", which hands a **copy** of the project's spreadsheet, document
or PDF to whatever app the platform offers: the system chooser on Android and iOS, the shell's open verb
on Windows, macOS and Linux, and a download on the web, where no app can be launched. The original file
is never handed out and never modified. The control names what it will do on the platform it is running
on, and is hidden rather than dead where the platform cannot do it.

## Evidence
- FBK0000006: the reporter asks that the per-project menu offer "open with (to open the project in
  supported apps: excel readers, word readers, pdf reader)". `screenshots/FBK0000006-2.png` shows the
  menu without it. Web, desktop, expanded, landscape, light, text scale 1. The reporter also asks for
  live two-way editing with those apps; that part is not in this prompt — see the open question in
  `INDEX.md`.
- Current code:
  - There is no way to hand a file to another app. `frontend/pubspec.yaml` has no `share_plus`,
    `url_launcher` or `open_file`, and nothing in `frontend/lib/` calls a share or launch API.
  - `DownloadService` (`frontend/lib/core/files/download_service.dart:16-45`) is the one way a feature
    saves a file for someone to open elsewhere (FE-STR-11). It already carries `canOpenFolder` and
    `onOpenFolder`, and the platform triad `download_service_io.dart` /
    `download_service_web.dart` / `download_service_stub.dart` selected by conditional import (`:7-10`).
    This is the seam to extend rather than a new service.
  - The candidate files already exist: the template JSON export (task
    [100](../../dev-plan/09-templates/100-template-export-json.md)), the untouched source workbook copied at
    import (task [102](../../dev-plan/09-templates/102-xlsx-mapping-screen.md)), and the phase 18 export output.

## Scope
- Reach: the cause is a `core/` service (section 4, row 3) — the interface and its callers are shared,
  the implementations are per platform. The ones that change, named:
  `frontend/lib/core/files/download_service_io.dart` gains the capability twice over, as the system
  chooser on Android and iOS and as the shell's open verb on Windows, macOS and Linux;
  `download_service_web.dart` reports `canOpenExternally` false and falls back to a download;
  `download_service_stub.dart` reports false and does nothing. The menu item is shared, so it renders at
  all three widths, both orientations, in light, dark and outdoor, and at 200 percent text.
  This is a suggestion, and a suggestion carries (section 4): it was reported on desktop web but lands
  on Android, iOS and the three desktops as well, within the interaction budget — one menu row, not a
  new screen (FE-SIMP-01, FE-SIMP-02, FE-SIMP-06).
- Excluded: no surface is dropped. The web is served by a *different outcome* — a download rather than a
  chooser, because a browser cannot hand a file to a local app — which is the review's third question,
  not silence.
- Change:
  - `frontend/lib/core/files/download_service.dart` and its `_io`, `_web` and `_stub` implementations:
    an `openExternally` capability with a `canOpenExternally` flag, plus a fake, following the shape
    `canOpenFolder` and `onOpenFolder` already use.
  - `frontend/pubspec.yaml` and `frontend/tool/allowlist.yaml`: the one dependency the review agrees on,
    pinned, with a licence note.
  - `frontend/lib/features/projects/presentation/project_list_view.dart` and
    `project_home_screen.dart`: an "Open with" item in the more menu, shown only when
    `canOpenExternally` is true and the project has an openable file.
  - `frontend/lib/core/copy/copy.dart`: the menu label, the per-platform description, the
    nothing-to-open message and the failure message.
  - Tests, listed in the steps.
- Do not change: the stored file, the project folder tree, `blob_store`, the export writers, the
  template importer's copy-once rule, or `DownloadService.save`. Nothing in this prompt writes to a
  file the app owns.

## Rules
- **Raw evidence is never destroyed** (the first of the five) and FE-SEC-08: hand out a copy in a cache
  area; never pass the stored original's path to another app, which could rewrite it in place.
- FE-FLOW-06: a new package needs its own task, an allowlist entry with a pinned version, a licence
  check and a note on what it replaces.
- FE-STR-11, FE-CONS-01: extend `DownloadService` — one `core/` service with an interface and a fake.
  No feature calls the plugin directly, and no parallel share service.
- FE-CONS-04, FE-CONS-11: failure renders through `AppErrorState` from a typed `Failure`.
- FE-SIMP-10, FE-SIMP-11: plain language; the item says what it will do — "Download a copy" on the web,
  "Open with" elsewhere.
- FE-SEC-01 to FE-SEC-11: no new network egress; check Android's storage permission before writing the
  copy, and leave nothing readable behind if the hand-off fails.
- FE-TEST-03, FE-TEST-05, FE-TEST-10: a hand-written fake, no real plugin in tests, and the denied,
  no-app-installed and cancelled paths tested as carefully as success.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 05-file-storage open-project-files-externally "Open a project's files in an external app"`
   (FE-FLOW-08), and a second task for the dependency (FE-FLOW-06).
2. **Stop for the review below.** Do not add a package, and do not touch `pubspec.yaml` or
   `allowlist.yaml`, before an answer.
3. Extend `DownloadService` with `canOpenExternally` and `openExternally`, plus the fake, and implement
   the three platform variants — web falls back to a download and reports `canOpenExternally` false.
4. Add the menu item, hidden where the capability is false or there is no openable file.
5. Tests:
   - `frontend/test/core/files/download_service_test.dart`: the fake reports the capability, receives a
     copy and never the original path; a cancelled chooser and a missing handler both return a typed
     failure and leave no file behind.
   - `frontend/test/features/projects/presentation/project_list_view_test.dart`: the item is absent when
     the capability is false and when the project has no openable file; present otherwise; the failure
     renders `AppErrorState`.
   - A test asserting the stored original's bytes and modified time are unchanged after a hand-off.
   - The menu item meets the 48 dp, label and tooltip matchers at 400, 800 and 1200 dp, light, dark and
     outdoor, at 200 percent text.

## Human review
⛔ Stop before step 3 and ask:
- Which file does "open the project" mean? A project is a folder, not a document. **Recommendation: the
  project's template workbook where one was imported, otherwise its most recent export**, and hide the
  item when neither exists — rather than inventing a document to open.
- Which dependency? `share_plus` gives the Android and iOS chooser and a desktop fallback;
  `url_launcher` opens a `file:` URI on desktop only; `open_file` is narrower and less maintained.
  **Recommendation: `share_plus`**, pinned, because it covers the three platforms that can do this at
  all with one allowlist entry.
- On the web, no app can be launched. **Recommendation: show the item as "Download a copy"** and route
  it through the existing `DownloadService.save`, rather than hiding it and leaving web users with no
  way out of the app.

Proceed only with an explicit answer. If the answer is "proceed", do all three recommendations.

## Acceptance criteria
- [ ] On Android and iOS the item opens the system chooser with a copy of the file.
- [ ] On Windows, macOS and Linux the item opens the copy in the platform's default handler.
- [ ] On the web the item downloads a copy and no chooser is attempted.
- [ ] The item is hidden when the platform cannot open a file and when the project has no openable file;
      it is never shown as a dead control.
- [ ] The stored original is byte-identical after a hand-off, and after a cancelled one.
- [ ] A cancelled chooser, a missing handler and a denied storage permission each render `AppErrorState`
      from a typed `Failure` and leave no copy behind.
- [ ] The new package is in `allowlist.yaml` with a pinned version and a licence note.
- [ ] The item meets the 48 dp, label, tooltip and contrast matchers at 400, 800 and 1200 dp, in light,
      dark and outdoor, at 200 percent text.
- [ ] FBK0000006's "open with" part is resolved. Its live-external-editing part is not; see `INDEX.md`.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
  The dependency checker must pass with the new entry.
- Regenerate goldens with `--update-goldens` only for the project row and project home menus, and list
  the files regenerated.
