# 24 — Product refinements

Complete the field-feedback, storage, template, capture and navigation refinements that extend the core app before
Documentation is built. The backend is available before task 077; project packages from task 076 support document
archive inputs, and task 079 applies compact More navigation after the earlier Settings-label change. The final
whole-app hardening pass follows every feature in [step 27](27-hardening/).

## 026 — In-app feedback: floating button, capture, download and delete

### Implement

A draggable floating Feedback control on every shell screen. Desktop hides the label until hover; phone and tablet
stay icon-only. The menu offers Give us feedback, Download feedback and Delete feedback. Each item opens a screen on
every form factor: type (General, Improvement, Error, Suggestion, Other with a name), the written note, and an
optional screenshot of the screen Feedback was tapped on. Each entry is stored on this device with the context the
organisation's workbook already names. Download filters the store and writes `TAPTURE-DDMMYYYY-HHMM.zip` containing
the spreadsheet and the matching screenshot files. Delete filters, ticks rows, and confirms before the entries and
their screenshots are gone.

### Files

- `frontend/lib/core/widgets/app_floating_button.dart`
- `frontend/lib/core/widgets/feedback/app_panel_dialog.dart`
- `frontend/lib/core/widgets/responsive/form_factor.dart`
- `frontend/lib/core/widgets/responsive/viewport_metrics.dart`
- `frontend/lib/core/export/` (existing encoder)
- `frontend/lib/features/feedback/` (domain, data, presentation)
- `frontend/lib/app/feedback_host.dart`
- `frontend/lib/app/nav_shell.dart` (wraps the shell in `FeedbackHost`)
- `frontend/lib/main.dart` (production overrides)

### Constraints

- Reuse the existing feedback domain, workbook layout, copy catalogue and xlsx encoder (FE-CONS-01).
- The shell builds `FeedbackOrigin`; the feature never reads the router (FE-STR-04).
- Default repository and downloads are in-memory / fake so tests never open a folder (FE-TEST-03).
- Presentation does not call `setState` (FE-STATE-01). Tokens only (FE-CONS-02).

### Definition of done

- [x] The floating control is draggable. Desktop shows the label on hover; phone and tablet do not.
- [x] Give, download and delete each open a screen on every form factor.
- [x] Give stores the typed note, type (including a named Other) and optional screenshot with the Excel-column context.
- [x] Download writes `TAPTURE-DDMMYYYY-HHMM.zip` with the spreadsheet and matching screenshot files.
- [x] Delete filters, selects, confirms, then removes the entries and their screenshots; undo restores what was just deleted.
- [x] Tests: domain unit tests, in-memory repository tests, widget tests for the floating button, panel, form factor
      and viewport metrics, and screen tests for give, download and delete.

## 027 — Feedback screens: compact layout, dictation and reopen safety

**Depends on** [012](12-capture.md), [026](24-product-refinements.md)

### Implement

Closing Give us feedback and opening it again crashed into the recovery screen: the form's notifier was
kept alive and invalidated on reopen, so Riverpod ran `build()` again on the same instance and its
`late final` text controllers threw. The form now owns its text, every feedback controller is
`autoDispose`, and async work stops writing once its screen has closed.

The four feedback-related screens become compact. Give us feedback offers General, Error, Suggestion
and Other as one horizontal radio row, puts the screenshot switch directly above its preview, and pins
Save feedback while the form scrolls. Download and Delete lead with search and a horizontal type row,
fold the remaining facets behind More filters, and keep their action pinned. The recovery screen shows
Restart, Export log and Recycle bin in one row that wraps only when it must.

Every free-text `AppTextField` gains a microphone at its end. Speech is reached through
`core/ai/stt_service.dart` (the 131 contract), the transcript is tidied (spacing, punctuation,
capitals) before it lands at the caret, and a field stops its session when it is disposed. The
offline switch keeps dictation on the device or refuses it (FE-SEC-04).

#### Second pass: a persistent feedback workspace

Give us feedback is a draft that outlives the form. The form is the overlay's workspace, never a route:
a side panel beside a usable app on expanded windows, the whole screen elsewhere, and a one-line bar
(type or speak) while the operator moves around. Back and "Continue later" fold it; Discard asks first.
Screenshots of any screen ("Add this screen"), camera photos and library photos attach up to eight
images: one fills the width at its own aspect ratio, several share a balanced grid, each opens a larger
preview and has a remove control. Photos come through `core/files/photo_picker.dart`
(`image_picker`) and are capped to the feedback long edge without distortion. Dictated words appear
in the field as they are heard; typing mid-listen keeps both. Inputs share the buttons' radius and
in-field controls carry no outline. Save, the headers and the attach checkbox (control first) are
compact. Download and delete share one browser: search with a filter toggle that counts hidden
facets, type checkboxes, the rest paired side by side where there is room, and select-all as a
checkbox.

### Files

- `frontend/lib/core/ai/stt_service.dart` (new, 131 contract), `frontend/lib/core/normalise/spoken_text.dart` (new)
- `frontend/lib/core/widgets/fields/dictation_scope.dart`, `dictation_session.dart` (new)
- `frontend/lib/core/widgets/fields/app_text_field.dart`, `app_radio_group.dart`, `app_switch_tile.dart`
- `frontend/lib/core/widgets/app_icon_button.dart`, `app_page.dart`, `forms/app_form.dart`
- `frontend/lib/app/app.dart`, `frontend/lib/app/widgets/global_error_page.dart`, `frontend/lib/main.dart`
- `frontend/lib/features/feedback/` (presentation, `FeedbackCategory.offered`)
- `frontend/lib/core/files/photo_picker.dart` (new), `frontend/lib/core/widgets/fields/choice_layout.dart` (new)
- `frontend/lib/features/feedback/presentation/` (`feedback_draft*`, `feedback_overlay`, `feedback_shots`, `feedback_browser`, `feedback_filter_panel`)
- `frontend/pubspec.yaml`, `frontend/tool/allowlist.yaml` (`speech_to_text`, `image_picker`), platform microphone, camera, photo and speech usage strings
- `frontend/android/gradle.properties` (`kotlin.incremental=false`: these are the first Kotlin plugins, and
  they compile from the pub cache on another drive, which Kotlin's incremental caches cannot handle)

### Constraints

- `speech_to_text` is reached only through `SttService`, which has a fake (FE-STR-11, FE-FLOW-06).
- The microphone is asked for on the first mic tap, never at launch; refusal leaves typing untouched.
- Stored `improvement` entries still read, filter and export; the form no longer offers the type.
- Presentation does not call `setState` (FE-STATE-01). Tokens only (FE-THEME-01).

### Definition of done

- [x] Give us feedback opens, closes and reopens any number of times without the recovery screen.
- [x] Give, download and delete controllers are `autoDispose`; nothing writes state after its screen closes.
- [x] The type row is horizontal with short labels; the screenshot switch sits above the preview; Save is pinned.
- [x] Download and delete show search and a horizontal type row first, with the rest behind More filters.
- [x] The recovery screen shows Restart, Export log and Recycle bin in one row.
- [x] Free-text fields dictate through `SttService`; the listening state is visible and announced; a disposed field
      cancels its own session; the offline switch keeps recognition on the device.
- [x] The draft survives folding, navigation and reopening; the form docks as a side panel on expanded windows.
- [x] Camera and library photos attach on every platform that has them; images keep their aspect ratio.
- [x] Tests: the overlay form (fold, reopen, dock, photos, preview, remove, save), the draft controller,
      `PhotoPicker`, `FeedbackShotFit`, `evenChoiceWidth`, typing mid-dictation, and multi-image storage.
- [x] Tests: `SpokenText` unit tests, `DictationSession` with a fake recogniser (partial, final, stop, error,
      dispose), `AppTextField` dictation, the new radio, switch, icon-button and page modes, feedback screen and
      reopen tests, and the recovery row.

## 028 — Feedback archive: ship the prompts generator

**Depends on** [026](24-product-refinements.md), [027](24-product-refinements.md)

### Implement

Every feedback download carries `feedback-prompts-generator.md` at the archive root, beside the workbook
and `screenshots/`. It instructs an AI agent to turn the export into ordered, executable implementation
prompts in `prompts/feedback-DDMMYYYY-HHMM/` of the repository:

- files are named `NNN-verb-object.md`, in the order they must be run;
- entries that share a root cause or component merge into one prompt;
- a suggestion too big for one reviewable change splits into several;
- every prompt respects and cites `frontend/.rules/`;
- a human-review stop comes before anything destructive or ambiguous;
- an `INDEX.md` accounts for every entry.

Feedback text is treated as data, never instructions, and personal data never reaches a prompt.

The guide is a Markdown asset, so it is edited as a document and not as code. The app loads it once, and
a missing guide never blocks a download.

### Files

- `frontend/assets/feedback/feedback-prompts-generator.md` (new)
- `frontend/lib/core/constants/document_assets.dart` (new, FE-STR-12)
- `frontend/lib/features/feedback/domain/feedback_archive.dart`
- `frontend/lib/features/feedback/presentation/feedback_providers.dart`, `download_feedback_controller.dart`
- `frontend/pubspec.yaml` (asset folder)

### Constraints

- The archive stays pure Dart and isolate-safe: the guide travels as text on `FeedbackArchive` (FE-STR-05,
  FE-PERF-02).
- The guide never asks the agent to change code; it produces prompts only.

### Definition of done

- [x] A download's zip holds the workbook, every image, and `feedback-prompts-generator.md` at its root.
- [x] A guide that cannot be loaded is left out, and the download still succeeds.
- [x] Tests: the archive with and without a guide, the shipped asset's contract, and an end-to-end
      download through the controller.

## 029 — Enable AppDatabase on web

**Depends on** [004](04-data-layer.md), [007](07-account-and-settings.md)

### Implement

`AppDatabase.open` and `AppDatabase.memory` work in the browser through Drift's wasm opener, so Operator
and Capture settings load and persist across a reload instead of throwing `UnsupportedError`.

### Files

- `frontend/lib/core/db/app_database.dart` (conditional import)
- `frontend/lib/core/db/app_database_web.dart` (new)
- `frontend/lib/core/db/app_database_stub.dart`
- `frontend/web/sqlite3.wasm`, `frontend/web/drift_worker.js` (new)
- `frontend/lib/features/settings/presentation/operator_profile_screen.dart`

### Constraints

- Native WAL/encryption in `app_database_io.dart` does not change.
- No new pub package if `drift` 2.31 and `sqlite3` 2.9.4 already provide wasm (FE-FLOW-06).
- Writes persist (FE-STATE-07). In-memory-only is not enough.
- Encryption remains native (064); `encryptionKey` on web is ignored.

### Definition of done

- [x] On web, Operator and Capture settings load and save; a reload restores them.
- [x] Operator's error state offers Try again.
- [x] Native open/memory tests still pass.
- [x] Tests: retry on Operator failure; the web opener is wired and `web/sqlite3.wasm` plus `web/drift_worker.js` are present.

## 030 — Fix storage settings on web

**Depends on** [007](07-account-and-settings.md), [029](24-product-refinements.md)

### Implement

Storage settings loads on web instead of `ProviderFailure`. Usage that needs a `dart:io` tree is empty;
retention still reads and writes through `SettingsStore`. Cache clear does not throw and does not
touch originals.

### Files

- `frontend/lib/features/settings/presentation/storage_settings_screen.dart`
- `frontend/test/features/settings/presentation/storage_settings_screen_test.dart`

### Constraints

- Platform file access stays in `core/files/` (FE-STR-11).
- Clearing cache never deletes originals (FE-SEC-08).
- Native usage totals stay as they are.

### Definition of done

- [x] On web, Storage is not `AppErrorState`; retention can be cycled.
- [x] Native empty, failure and cache-original tests still pass.
- [x] Tests: a failed `StorageRoot` still shows usage chrome (retention), not the generic provider error.

## 031 — Dock feedback panel beside app

**Depends on** [027](24-product-refinements.md)

### Implement

On expanded windows, Give us feedback is a trailing column beside the app. The screen in action is not
covered by the panel. Compact and medium still fill the overlay.

### Files

- `frontend/lib/features/feedback/presentation/feedback_overlay.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

### Constraints

- Size class from `context.sizeClass` (FE-RESP-02). Trailing edge, not left/right (FE-L10N-05).
- Panel width from `AppConstants.userFeedback.panelWidth` (FE-CODE-09).
- Screenshots still capture the app child only.

### Definition of done

- [x] Expanded: the app's right edge is at or left of the panel; taps on the app hit the app.
- [x] Compact and medium still fill with the form; the FAB hides while expanded.
- [x] Tests: `App screen` aligned to the trailing edge must sit beside, not under, the form.

## 032 — Rename More nav to Settings

**Depends on** [006](06-app-shell.md)

### Implement

The fourth shell destination, already a settings cog, is labelled Settings. Routes stay `/more`.

### Files

- `frontend/lib/core/copy/copy.dart`
- `frontend/.rules/06-simplicity.md`
- `frontend/lib/app/nav_shell.dart`, `frontend/lib/app/router.dart`, `frontend/lib/app/feedback_host.dart`
- `frontend/lib/features/settings/presentation/settings_screen.dart`
- `frontend/test/app/nav_shell_test.dart`

### Constraints

- Four destinations, no fifth (FE-SIMP-02). Visible strings on `Copy` (FE-L10N-01).
- Do not rename `AppRoutes.more` or `/more/…` paths.

### Definition of done

- [x] Compact bar, medium rail and expanded rail say Settings for destination 3.
- [x] `/more/operator` and the settings root still resolve.
- [x] Tests: `nav_shell_test` still matches `Copy.navMore`, now `'Settings'`.

## 033 — Fix feedback search remount

**Depends on** [026](24-product-refinements.md)

### Implement

Typing in Download feedback and Delete feedback Search keeps the query visible and filters the
list. Clearing filters still empties the field.

### Files

- `frontend/lib/core/widgets/app_search_field.dart`
- `frontend/lib/features/feedback/presentation/feedback_filter_panel.dart`
- `frontend/test/core/widgets/app_search_field_test.dart`
- `frontend/test/features/feedback/presentation/download_feedback_screen_test.dart`

### Constraints

- Do not remount Search when `FeedbackFilter.isEmpty` becomes false (FE-SIMP-09).
- Size-class rebuilds must not drop the query (FE-RESP-03).
- Debounce stays `AppConstants.interaction.debounce` (FE-CODE-09).
- Other screens' search fields stay unchanged.

### Definition of done

- [x] After one debounce, Search still shows the typed query and hides non-matching rows.
- [x] Clear filters empties Search and shows the full list.
- [x] Tests: download screen types "crash", pumps the debounce, then clears; `AppSearchField` clears only when parent `text` becomes empty.

## 034 — Fix feedback camera browse

**Depends on** [026](24-product-refinements.md)

### Implement

On Give us feedback, the camera control opens a camera session (webcam on
desktop web) and attaches one photo. It never opens the library file picker.
Where a camera session cannot be opened, the control is hidden and Choose
photo remains.

### Files

- `frontend/lib/core/files/photo_picker.dart`
- `frontend/lib/core/files/photo_picker_io.dart`
- `frontend/lib/core/files/photo_picker_web.dart`
- `frontend/lib/core/files/photo_picker_stub.dart`
- `frontend/lib/core/constants/app_constants.dart`
- `frontend/test/core/files/photo_picker_test.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

### Constraints

- Platform picker stays inside `PhotoPicker` (FE-STR-11).
- Camera and library stay distinct controls (FE-CONS-08).
- Camera is used only on an explicit tap; no new egress or package (FE-SEC-07,
  FE-FLOW-06).
- Tests use fakes; they never open a real camera (FE-TEST-03, FE-TEST-10).

### Definition of done

- [x] Tapping camera opens a camera/webcam session when one exists, not the library file picker.
- [x] When no camera session is possible, `Copy.feedbackTakePhoto` is absent and `Copy.feedbackChoosePhoto` still adds images.
- [x] A refused camera still shows `Copy.photoNoAccess` and adds no shot.
- [x] Tests: a picker that can only browse reports `canTakePhoto: false`; existing Give us feedback camera tests still pass.

## 035 — Mark required optional fields

**Depends on** [003](03-design-system.md), [007](07-account-and-settings.md)

### Implement

Operator (and any field that opts in) shows which inputs are required and
which are optional before Save. Unmarked fields look as they do today.

### Files

- `frontend/lib/core/widgets/fields/app_text_field.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/features/settings/presentation/operator_profile_screen.dart`
- `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart`
- `frontend/test/core/widgets/fields/app_text_field_test.dart`
- `frontend/test/core/copy/copy_test.dart`
- `frontend/test/features/settings/presentation/operator_profile_screen_test.dart`
- `frontend/test/design_system/app_text_field/gallery_golden_test.dart`

### Constraints

- Extend `AppTextField`; do not fork a label widget (FE-CONS-01).
- `Copy.fieldRequired` / `Copy.fieldOptional` are their own strings; never
  concatenate them into the label (FE-L10N-01, FE-L10N-03).
- Semantics announce required/optional; not colour alone (FE-A11Y-02,
  FE-A11Y-05, FE-A11Y-07).
- Tokens only (FE-THEME-01). Gallery shows both marks (FE-CONS-03).
- Do not change validation rules or other screens' labels.

### Definition of done

- [x] On Operator, Name and Initials read as required and Contact as optional before Save, in light, dark and outdoor, at 100 and 200 percent text, without clipping.
- [x] Unmarked fields elsewhere look as they do today.
- [x] Tests: gallery + goldens include both marks; Operator shows the marks before Save; a11y matcher on the field; `copy_test.dart` lists the new keys.

## 036 — Add email phone fields

**Depends on** [003](03-design-system.md), [035](24-product-refinements.md)

### Implement

The catalogue has reusable email and phone fields that compose
`AppTextField`: correct keyboard, no dictation, optional by default. They
appear in the widget gallery. Operator still uses a single Contact field.

### Files

- `frontend/lib/core/widgets/fields/app_email_field.dart`
- `frontend/lib/core/widgets/fields/app_phone_field.dart`
- `frontend/lib/core/widgets/fields/app_text_field.dart`
- `frontend/lib/core/widgets/widgets.dart`
- `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart`
- `frontend/test/core/widgets/fields/app_email_field_test.dart`
- `frontend/test/core/widgets/fields/app_phone_field_test.dart`
- `frontend/test/design_system/app_email_field/gallery_golden_test.dart`
- `frontend/test/design_system/app_phone_field/gallery_golden_test.dart`
- `frontend/test/design_system/catalogue_golden_test.dart`

### Constraints

- Compose `AppTextField`; do not fork a field (FE-CONS-01).
- One public type per file, documented (FE-STR-06, FE-CODE-12).
- Caller passes the label; widgets do not decide validation (FE-L10N-01).
- Contact, not secrets: no obscure, no secure storage (FE-SEC-01).
- Tokens, 48dp, labelled, 200 percent text (FE-THEME-01, FE-A11Y-01–03).
- Do not change Operator storage or the Contact field.

### Definition of done

- [x] Gallery shows email and phone in empty, filled, error and disabled, light, dark and outdoor, at 100 and 200 percent text without clipping.
- [x] Neither field offers a microphone.
- [x] Operator Contact is unchanged.
- [x] Tests: keyboard type, no microphone under `DictationScope`, 48dp, semantic label; goldens in light, dark and outdoor.

## 037 — Add feedback close control

**Depends on** [026](24-product-refinements.md)

### Implement

Give us feedback, Download feedback, Delete feedback, and the folded draft
bar each have one labelled Close. Form Close folds and keeps the draft.
Bar Close confirms discard. Download and Delete Close pop the route.

### Files

- `frontend/lib/features/feedback/presentation/give_feedback_screen.dart`
- `frontend/lib/features/feedback/presentation/download_feedback_screen.dart`
- `frontend/lib/features/feedback/presentation/delete_feedback_screen.dart`
- `frontend/lib/features/feedback/presentation/feedback_draft_bar.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`
- `frontend/test/features/feedback/presentation/download_feedback_screen_test.dart`
- `frontend/test/features/feedback/presentation/delete_feedback_screen_test.dart`

### Constraints

- One close, not back and close both (FE-SIMP-01).
- Discarding the draft still uses `showAppConfirm` with
  `Copy.feedbackDiscardDraft` (FE-SIMP-07, FE-CONS-05).
- Close on Give must not drop typed text unless discard was confirmed
  (FE-SIMP-09).
- `AppIconButton` with `Copy.close`; 48dp (FE-A11Y-01, FE-A11Y-02).
- Do not change Save / Download / Delete primary actions.

### Definition of done

- [x] Give us feedback, Download feedback and Delete feedback each show a labelled Close; one tap leaves that surface.
- [x] Closing Give us feedback keeps the message and shots unless discard was confirmed.
- [x] The draft bar can be dismissed; cancel on the confirm leaves it open.
- [x] Tests: Give close folds with the message on the bar and no discard dialog; Download/Delete close pops; bar close + confirm clears the draft, cancel leaves the bar.

## 038 — Split operator contact fields

**Depends on** [007](07-account-and-settings.md), [035](24-product-refinements.md), [036](24-product-refinements.md)

### Implement

Operator collects optional Email and optional Phone. A stored
`operatorContact` with `@` becomes email, otherwise phone, and saves
stop writing the old key. Feedback still gets one derived contact string.

### Files

- `frontend/lib/core/constants/app_constants.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/core/widgets/forms/app_form.dart`
- `frontend/lib/features/settings/domain/operator_profile.dart`
- `frontend/lib/features/settings/data/settings_store.dart`
- `frontend/lib/features/settings/presentation/operator_profile_screen.dart`
- `frontend/lib/features/feedback/presentation/feedback_context_capture.dart`
- `frontend/test/core/app_constants_test.dart`
- `frontend/test/core/copy/copy_test.dart`
- `frontend/test/core/db/tables/device_profile_test.dart`
- `frontend/test/core/widgets/forms/app_form_test.dart`
- `frontend/test/features/settings/domain/operator_profile_test.dart`
- `frontend/test/features/settings/presentation/operator_profile_screen_test.dart`

### Constraints

- Use `AppEmailField` and `AppPhoneField`; do not invent Operator inputs
  (FE-CONS-01).
- Migrate beside the old value on read; a save writes the new keys and
  removes `operatorContact`; never drop unknown preference keys
  (FE-STATE-07, FE-SEC-08).
- Email and phone are not secrets; they stay on the device-profile row
  (FE-SEC-01, FE-SEC-07).
- Empty email and empty phone are valid; format-check a non-empty email
  for `@` only (FE-SIMP-08).
- Do not add email or phone columns to the feedback workbook.

### Definition of done

- [x] Operator shows optional Email and optional Phone, no Contact field.
- [x] Save with only a name and initials still succeeds.
- [x] A stored `ada@x` contact becomes email after one load/save; a
      phone-like contact becomes phone.
- [x] New feedback entries still populate `operatorContact` (email if
      set, else phone).
- [x] Tests: migrate/save at the domain layer; widget tests for the two
      fields, optional marks, name-and-initials-only save, and invalid
      email copy.

## 039 — Include feedback UI screenshot

**Depends on** [031](24-product-refinements.md)

### Implement

Give us feedback can attach a screenshot of the visible workspace (docked
panel or full-screen form). Default Add this screen is still the app
without the feedback UI.

### Files

- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/features/feedback/presentation/feedback_draft.dart`
- `frontend/lib/features/feedback/presentation/feedback_draft_controller.dart`
- `frontend/lib/features/feedback/presentation/feedback_overlay.dart`
- `frontend/lib/features/feedback/presentation/feedback_shots.dart`
- `frontend/test/core/copy/copy_test.dart`
- `frontend/test/features/feedback/presentation/feedback_draft_controller_test.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

### Constraints

- One Add this screen action; including the UI is opt-in, default off
  (FE-SIMP-01, FE-SIMP-05).
- Reuse `AppIconButton` for the opt-in; no new shot widget (FE-CONS-01).
- Capture the overlay as laid out: trailing panel on expanded, full form
  on compact and medium (FE-L10N-05, FE-RESP-10).
- Cap to `AppConstants.userFeedback.screenshotLongEdge` (FE-PERF-04,
  FE-CODE-09).
- Do not include the floating button; it is already hidden while expanded.
- Do not change camera, library, the first menu capture, or the workbook
  screenshot sheet.

### Definition of done

- [x] Default Add this screen is the app without the feedback form, on
      compact and expanded.
- [x] With the opt-in on, the new shot is the Give us feedback UI (docked
      panel on expanded, full form on compact).
- [x] The control is labelled and 48dp; 200 percent text does not clip
      the shots row.
- [x] Tests: default capture is app-only; opt-in capture differs and is
      wider on expanded.

## 040 — Add other window screenshot

**Depends on** [026](24-product-refinements.md)

### Implement

Give us feedback can attach one still of another window the operator picks
in the browser display picker. The control is hidden where the platform
cannot share a display.

### Files

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

### Constraints

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

### Definition of done

- [x] On a capture-capable fake, one labelled control attaches a still
      and turns attach on.
- [x] The stream is not left running after the still, cancel or refusal.
- [x] Where `canCapture` is false, the control is absent; Add this
      screen, camera and Choose photos still work.
- [x] Compact 360 dp does not overflow the shots row.
- [x] Tests: fake one frame, cancel, refusal, hidden; widget tap adds
      one shot; refusal shows copy and adds nothing.

## 041 — Warn before closing the tab with a draft

### Implement

On the web, closing or reloading the tab while a feedback draft holds work
shows the browser's own leave prompt. Cancelling it keeps the draft. Form
Close still folds in one tap.

### Files

- `frontend/lib/features/feedback/presentation/feedback_draft.dart`
- `frontend/lib/core/lifecycle/leave_guard.dart`
- `frontend/lib/core/lifecycle/leave_guard_web.dart`
- `frontend/lib/core/lifecycle/leave_guard_stub.dart`
- `frontend/lib/core/lifecycle/lifecycle.dart`
- `frontend/lib/main.dart`
- `frontend/lib/features/feedback/presentation/feedback_overlay.dart`
- `frontend/test/core/lifecycle/leave_guard_test.dart`
- `frontend/test/features/feedback/presentation/feedback_draft_controller_test.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

### Constraints

- Browser access only through the core service with a fake (FE-STR-11).
- No new package; web uses `dart:js_interop` (FE-FLOW-06).
- `hasWork` is derived, never stored (FE-STATE-06).
- Release on dispose (FE-STATE-09). `core/` never imports `features/`
  (FE-STR-04).
- Exactly one prompt, and it is the browser's own (FE-SIMP-07, FE-SIMP-09).
- One-line docs on the new public API (FE-CODE-12). Fakes, not mocks
  (FE-TEST-01, FE-TEST-03).
- Do not persist drafts, and do not change native or desktop exit.

### Definition of done

- [x] Web: typed text, a named Other type or shots arm the browser leave
      prompt, including while the draft is folded or docked.
- [x] After a successful Save or a confirmed discard, closing the tab
      shows no prompt.
- [x] No prompt when no draft has been started, including after only
      opening the Feedback menu.
- [x] Native builds compile; the stub only records owners.
- [x] Tests: fake hold/release across two owners; `hasWork` false for a
      closed or empty open draft and true for text, Other name or a shot;
      typing arms the fake guard, Save and confirmed discard release it.

## 042 — Confirm desktop exit with a draft

**Depends on** [041](24-product-refinements.md)

### Implement

On desktop, closing the window while a feedback draft holds work shows the
same Discard draft confirmation as the bar. Cancel keeps the app open and
the draft. Form Close still folds in one tap. Runners are unchanged: the
engine already forwards window close to `didRequestAppExit`.

### Files

- `frontend/lib/core/lifecycle/lifecycle_observer.dart`
- `frontend/lib/features/feedback/presentation/feedback_overlay.dart`
- `frontend/test/core/lifecycle/lifecycle_observer_test.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

### Constraints

- Exit handling stays on the one core observer (FE-STR-11).
- Reuse `showAppConfirm` and the existing discard copy (FE-CONS-05,
  FE-SIMP-07). Cancel never loses the draft (FE-SIMP-09).
- The check is awaited (FE-CODE-07) and removed on dispose (FE-STATE-09).
- Drive `LifecycleObserver.fake()` directly (FE-TEST-03).
- Do not change web, Android, iOS, fold-on-Close, or desktop runners.

### Definition of done

- [x] A window-close request with typed feedback shows Discard draft;
      Cancel keeps the text, Confirm returns exit and clears the draft.
- [x] No draft, or `hasWork` false, returns exit with no dialog.
- [x] The check still runs while the draft is folded into the bar.
- [x] Tests: no checks exit; a false check cancels; a removed check no
      longer runs; overlay cancel/confirm/no-draft as above.

## 043 — Align the feedback shot controls

### Implement

Give us feedback stacks Attach and Include the feedback UI as matching
checkboxes, then a start-aligned row of capture buttons. The capture names
are Screenshot current screen and Screenshot external window, including on
the Feedback menu.

### Files

- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/features/feedback/presentation/feedback_shots.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

### Constraints

- Reuse `AppSwitchTile.checkbox` and `AppIconButton` (FE-CONS-01).
- Strings stay in `Copy`; keys keep their meaning (FE-L10N-01, FE-L10N-02).
- No width checks; stacking works at every width (FE-RESP-02).
- 48dp targets, labelled (FE-A11Y-01, FE-A11Y-02). Spacing uses `Space.*`
  (FE-THEME-01).
- Do not change capture behaviour, the include-UI default, `maxShots`, the
  gallery, `AppSwitchTile`, or `AppIconButton`.

### Definition of done

- [x] Include the feedback UI is a checkbox like Attach N images, off by
      default; ticking it still captures the feedback chrome.
- [x] Tooltips and labels read Screenshot current screen and Screenshot
      external window; the still is labelled External window.
- [x] At 360 dp, neither checkbox label wraps; at 200 percent text the
      section does not overflow.
- [x] The docked panel shows both checkboxes above the capture row.
- [x] Tests: include-UI found by text; one-line labels at 360 dp; no
      overflow at 360 dp / 200 percent; docked order.

## 044 — Soften input placeholder text

### Implement

Add `onSurfaceMuted` so empty-field hints and resting labels read quieter
than typed text in every theme, while still clearing 4.5:1. Floating
labels and typed values stay on `onSurface`. Field widgets are unchanged.

### Files

- `frontend/lib/app/theme/color_tokens.dart`
- `frontend/lib/app/theme/app_theme.dart`
- `frontend/lib/app/theme/color_swatches.dart`
- `frontend/test/design_system/tokens/color_tokens_test.dart`
- `frontend/test/app/theme/app_theme_test.dart`

### Constraints

- One new semantic role in all three palettes (FE-THEME-02, FE-THEME-04,
  FE-THEME-11). Style Material centrally (FE-THEME-07).
- Reuse `_outlineLight` and `_outlineDark`; outdoor uses `0xFF3B4A54`
  (FE-THEME-03, FE-THEME-10).
- Do not change field widgets or anything under `lib/features/`.
- Extend the token contrast guardrail; do not weaken it (FE-TEST-06).

### Definition of done

- [x] Hint text and resting labels use `onSurfaceMuted` in light, dark
      and outdoor. Floating labels and typed text stay on `onSurface`.
- [x] `onSurfaceMuted` meets 4.5:1 on every surface in every mode.
- [x] Tests: role present; muted contrast; theme hint/label vs floating
      and typed ink.

## 045 — Number feedback rows with their message

### Implement

Number Download feedback and Delete feedback rows in list order, and put
the Feedback ID and the start of the message on the same title line.

### Files

- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/features/feedback/presentation/feedback_browser.dart`
- `frontend/lib/features/feedback/presentation/feedback_entry_tile.dart`
- `frontend/lib/features/feedback/presentation/download_feedback_screen.dart`
- `frontend/lib/features/feedback/presentation/delete_feedback_screen.dart`
- `frontend/test/core/copy/copy_test.dart`
- `frontend/test/features/feedback/presentation/download_feedback_screen_test.dart`
- `frontend/test/features/feedback/presentation/delete_feedback_screen_test.dart`

### Constraints

- Rows stay `AppListTile` (FE-CONS-06). No new row widget (FE-CONS-01).
- The title is built by `Copy` with placeholders (FE-L10N-01, FE-L10N-03).
- The list position is formatted with `intl` (FE-L10N-04, FE-CONS-09).
- The message is user data; collapse whitespace only (FE-L10N-07).
- One line with an ellipsis; no clipping at 200 percent (FE-RESP-06,
  FE-RESP-10, FE-A11Y-03). The title is the semantic label (FE-A11Y-02).
- Do not change the facts subtitle, selection, filters, paging, actions,
  or the workbook.

### Definition of done

- [x] Both screens show "1. FBK… · <message>", then "2. …", in list order.
- [x] A long message ellipsises on the ID line at 360, 768 and 1280 dp.
- [x] At 200 percent text the title stays one line and nothing overflows.
- [x] Numbers continue across Show more and restart at 1 after a filter.
- [x] Tests: numbered titles; ellipsis; collapsed line breaks; tick keeps
      the number; filter restarts at 1; the new Copy key.

## 046 — Add a window share session to screen capture

### Implement

Replace the one-shot display picker with a session: one `start`, any
number of `still`s, then `stop`. Give us feedback still takes one still
and stops at once.

### Files

- `frontend/lib/core/files/screen_capture.dart`
- `frontend/lib/core/files/screen_capture_web.dart`
- `frontend/lib/core/files/screen_capture_io.dart`
- `frontend/lib/core/files/screen_capture_stub.dart`
- `frontend/lib/features/feedback/presentation/give_feedback_controller.dart`
- `frontend/test/core/files/screen_capture_test.dart`

### Constraints

- Display APIs stay in this core service, with a fake (FE-STR-11).
- `dart:js_interop` only; no new package (FE-FLOW-06).
- Stills only on an explicit call; no frame data in logs (FE-SEC-07,
  FE-SEC-10, FE-CODE-08).
- Public methods return `Result`; no raw exception crosses the boundary
  (FE-CODE-06). Awaited promises use the camera-ready timeout (FE-CODE-07).
- `stop` removes the video and the `ended` listener (FE-STATE-09).
- Do not change shot controls, copy, camera, library, or the workbook.

### Definition of done

- [x] One `start` and three `still`s return three PNGs from one picker.
- [x] After `stop` or the browser's Stop sharing, `isSharing` is false and
      `ended` has fired.
- [x] Give us feedback still adds one still per tap and leaves no stream.
- [x] Native `canCapture` is false and `start` returns false.
- [x] Tests: successive frames; cancel; refusal; `stop` fires `ended`;
      native hidden.

## 047 — Add repeat external window screenshots

**Depends on** [046](24-product-refinements.md)

### Implement

On the web, one display picker starts a share; later taps add stills of
that window until Stop sharing, Save, discard, or the browser stops it.
The folded bar can take another still. The draft still caps at eight
images.

### Files

- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/features/feedback/presentation/feedback_window_share_controller.dart`
- `frontend/lib/features/feedback/presentation/give_feedback_controller.dart`
- `frontend/lib/features/feedback/presentation/feedback_shots.dart`
- `frontend/lib/features/feedback/presentation/feedback_draft_bar.dart`
- `frontend/test/core/copy/copy_test.dart`
- `frontend/test/features/feedback/presentation/feedback_window_share_controller_test.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

### Constraints

- Sharing lives in its own notifier; images stay on the draft (FE-STATE-02,
  FE-STATE-04, FE-STATE-06). Kept alive for the bar (FE-STATE-09).
- A still is taken only on a tap (FE-SEC-07). Pixels are never logged
  (FE-SEC-10, FE-CODE-08).
- Reuse `AppIconButton` (FE-CONS-01, FE-CONS-08). 48dp, labelled, snacks
  (FE-A11Y-01, FE-A11Y-02, FE-A11Y-07). Caption is the non-colour signal
  (FE-A11Y-05).
- No overflow at 360 dp or 200 percent text (FE-RESP-06, FE-A11Y-03).
- Do not change `maxShots`, current-screen capture, camera, library,
  native platforms, or the workbook.

### Definition of done

- [x] One picker, then N taps add N stills, up to eight, with no picker
      in between.
- [x] The bar offers another still while sharing; typing still works.
- [x] Sharing ends on Stop sharing, Save, discard, or the browser's stop.
- [x] When full, `feedbackShotsFull` is shown and sharing stays live.
- [x] Tests: two stills from one start; cancel; ended; Save/discard stop;
      full; bar still; stop hides; no overflow at 360 dp / 200 percent.

## 048 — Fix the storage root on Android

**Depends on** [005](05-file-storage.md), [007](07-account-and-settings.md)

### Implement

On Android, `StorageRoot.resolve()` creates and returns the `Tapture/` folder
without asking for any permission. Storage settings then shows the real cache
and per-project totals, and Clear cache works.

### Files

- `frontend/lib/core/files/storage_root.dart`
- `frontend/test/core/files/storage_root_test.dart`
- `frontend/test/features/settings/presentation/storage_settings_screen_test.dart`

### Constraints

- Platform folders stay behind `StorageRoot` in `core/files/` (FE-STR-11).
- An unwritable or missing folder is still a `StorageFailure` with a recovery
  action (FE-CODE-06).
- Docs on `StorageRoot()` and `resolve()` no longer say it asks
  `PermissionsService` (FE-CODE-12).
- Tests use fakes and keep the unwritable-location failure (FE-TEST-03,
  FE-TEST-10).
- Clear cache still prunes `.cache` only (FE-SEC-08).
- Add no permission to the manifest (task 235).
- Do not move the root (prompt 004), change `AppPermission.storage`, drop
  the `_usageOnly` fallback, or change the database location.

### Definition of done

- [x] Resolving the root never asks for a permission and still creates
      `Tapture/` plus `Tapture/.cache`.
- [x] With a resolvable root, Storage shows the real cache size, not 0 B.
- [x] A read-only or missing location still returns a `StorageFailure` with a
      recovery action.
- [x] Tests: never-asks-permission create; existing idempotence and
      missing/read-only `StorageFailure` tests; Storage shows the seeded
      cache size.

## 049 — Save downloads to a public Tapture folder

**Depends on** [026](24-product-refinements.md)

### Implement

On Android 10 and later, Download feedback saves the archive to
`Download/Tapture/` in shared storage, where the Files app shows it and it
survives an uninstall. The success message names that place. Desktop writes
to `Downloads/Tapture/`. Android 9 and below keep the app folder, with no
new permission.

### Files

- `frontend/android/app/src/main/kotlin/com/tapture/app/MainActivity.kt`
- `frontend/lib/core/files/download_service.dart`
- `frontend/lib/core/files/download_service_io.dart`
- `frontend/test/core/files/download_service_test.dart`

### Constraints

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

### Definition of done

- [x] Android 10+ saves through MediaStore to `Download/Tapture/` and
      returns that display path.
- [x] The folder writer saves into `<folder>/Tapture/` and numbers a clash.
- [x] An `unsupported` reply and a `PlatformException` both fall back to the
      folder writer.
- [x] A write failure returns `downloadFailure(fileName)`.
- [x] Tests: folder writer Tapture + numbering; channel location;
      unsupported and exception fallback; write failure.

## 050 — Keep the feedback bar above the keyboard

**Depends on** [026](24-product-refinements.md), [027](24-product-refinements.md)

### Implement

When Give us feedback is folded into its bar, typing or dictating in the bar
keeps the bar in view, just above the on-screen keyboard. With no keyboard
the resting place is unchanged.

### Files

- `frontend/lib/features/feedback/presentation/feedback_overlay.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

### Constraints

- No layout assumes the keyboard is closed (FE-RESP-06).
- Insets are handled once, in the shell-level overlay (FE-RESP-08).
- Portrait, landscape, and 200 percent text (FE-RESP-07, FE-A11Y-03).
- No literal offsets; reuse `Sizes.minTapTarget` and the theme navigation
  bar height (FE-THEME-01, FE-CODE-09).
- No `setState`; `MediaQuery` drives the rebuild. Only the positioned bar
  depends on the inset (FE-STATE-01, FE-PERF-05).
- Pump to a condition; never a fixed delay (FE-TEST-07).
- Do not change the unfolded form, the docked panel, the floating button,
  `FeedbackDraftBar` content, `AndroidManifest.xml`, or the navigation bar.

### Definition of done

- [x] The folded bar's `bottom` is the larger of the resting offset and the
      keyboard inset.
- [x] Phone, medium, expanded, landscape, and 200 percent text keep the bar
      fully above the keyboard, with a hit-testable field.
- [x] Closing the keyboard returns the compact bar above the navigation bar.
- [x] Typed text survives opening and closing the keyboard.
- [x] Tests: the cases above, pumped through `FakeViewPadding`.

## 051 — Move the storage root to public Documents

**Depends on** [005](05-file-storage.md), [048](24-product-refinements.md), [049](24-product-refinements.md)

### Implement

On Android 11 and later, the `Tapture/` evidence folder lives in shared
storage at `Documents/Tapture/`. A person can open it in the Files app, and
it survives an uninstall. Android 10 and below, and a failed write probe,
keep the app-specific folder. Other platforms keep their current location.
Nothing already under `Android/data` is moved or deleted.

### Files

- `frontend/android/app/src/main/kotlin/com/tapture/app/MainActivity.kt`
- `frontend/lib/core/files/storage_root.dart`
- `frontend/test/core/files/storage_root_test.dart`

### Constraints

- Native access stays in `core/files/` behind `StorageRoot` (FE-STR-11).
- Raw evidence is never moved or deleted (FE-SEC-08).
- A location that fails the probe is a `StorageFailure` only when the
  fallback fails too (FE-CODE-06).
- No new permission (FE-SEC-07, task 235).
- Paths stay ASCII (FE-L10N-11).
- Seams only; no real shared storage in tests (FE-TEST-03).
- Do not change the database location, downloads, iOS, desktop, web,
  `AndroidManifest.xml`, or the feedback `BlobStore`.

### Definition of done

- [x] Android 11+ prefers public `Documents/Tapture` through the files
      channel.
- [x] `unsupported` and an unwritable public folder fall back to the app
      folder.
- [x] Both locations unwritable is a `StorageFailure`.
- [x] Resolving a writable public folder twice returns the same directory.
- [x] Tests: public used when writable; unsupported fallback; unwritable
      public fallback; both fail; existing missing/read-only tests.

## 052 — Unify the confirmation dialog design

**Depends on** [003](03-design-system.md), [026](24-product-refinements.md)

### Implement

Every confirmation uses one catalogue design at every width: capped at
`Sizes.dialogMaxWidth` on tablets and desktops, and full width less the
standard inset on phones. Destructive confirmations carry a warning icon as
well as colour. The feedback feature defines its discard-draft confirmation
once.

### Files

- `frontend/lib/app/theme/sizes.dart`
- `frontend/lib/core/widgets/feedback/app_dialog.dart`
- `frontend/lib/features/feedback/presentation/feedback_confirmations.dart`
- `frontend/lib/features/feedback/presentation/feedback_draft_bar.dart`
- `frontend/lib/features/feedback/presentation/feedback_overlay.dart`
- `frontend/lib/features/feedback/presentation/give_feedback_screen.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/core/copy/copy_test.dart`
- `frontend/test/core/widgets/feedback/app_dialog_test.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`
- `frontend/test/design_system/tokens/dimensions_test.dart`

### Constraints

- One dialog API; confirmations look the same in every feature (FE-CONS-05).
- Tokens only; the new width is `Sizes.dialogMaxWidth` (FE-THEME-01).
- Danger carries an icon and text as well as colour (FE-THEME-05, FE-A11Y-05).
- Name the consequence and the count; Cancel is the safe default (FE-SIMP-07).
- New strings live in `Copy`; plurals use ICU (FE-L10N-01, FE-L10N-03).
- Capped width, 48 dp buttons, no clipping at 200 percent (FE-RESP-04,
  FE-A11Y-01, FE-A11Y-03).
- Do not change the `showAppConfirm` and `showAppAlert` signatures, the
  delete confirmation copy, the browser leave-page prompt, `AppPanelDialog`,
  or undo.

### Definition of done

- [x] At 1280 dp every confirmation is at most 560 dp wide and centred. At
      360 dp it fills the width less 24 dp each side.
- [x] Destructive confirmations show `Icons.warning_amber_outlined` in
      `danger` beside the title. Buttons stay an end-aligned wrapping row.
- [x] Discard draft (bar, form, desktop exit) uses
      `confirmDiscardFeedbackDraft` with title "Discard this feedback?" and
      a counted message.
- [x] Tests: width and inset; 200 percent; destructive icon present and
      absent; copy at zero, one and many; the three discard surfaces.
- [x] Dialog goldens regenerated in light, dark and outdoor.

## 053 — Add screenshot help for other screens

**Depends on** [026](24-product-refinements.md), [037](24-product-refinements.md)

### Implement

On a phone or tablet, the folded feedback bar offers Screenshot current
screen in one tap, and the form explains both routes when the platform
cannot capture other windows. No MediaProjection plugin is added.

### Files

- `frontend/lib/features/feedback/presentation/feedback_draft_bar.dart`
- `frontend/lib/features/feedback/presentation/feedback_overlay.dart`
- `frontend/lib/features/feedback/presentation/feedback_shots.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/core/copy/copy_test.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

### Constraints

- Reuse `AppIconButton` and the menu's screenshot icon (FE-CONS-01,
  FE-CONS-08).
- Plain language that names the next action (FE-SIMP-10, FE-SIMP-11).
- Strings in `Copy`, with room for 35 percent longer text (FE-L10N-01,
  FE-L10N-06).
- 48 dp and labelled; the result is announced by the existing snack
  (FE-A11Y-01, FE-A11Y-02, FE-A11Y-07).
- A still is taken only when the operator taps (FE-SEC-07).
- The bar calls a callback and keeps no capture logic (FE-STATE-04).
- No overflow at 360 dp (FE-RESP-06).
- Do not change Close, the floating menu, web window sharing, the image
  cap, `Copy.feedbackContinueLater`, or `Copy.feedbackDraftBarHint`.

### Definition of done

- [x] The folded bar's Screenshot current screen adds one image and shows
      `Copy.feedbackShotAdded`.
- [x] Both tips show when `canCapture` is false; neither shows when it is
      true.
- [x] The bar has no overflow at 360 dp with an image count, at 100 and
      200 percent text.
- [x] The new control meets the 48 dp and label matchers.

## 054 — Persist the theme mode in the settings store

**Depends on** [003](03-design-system.md), [007](07-account-and-settings.md)

### Implement

The chosen appearance is stored in the settings store as
`appearance.themeMode`. A one-time read of the old temp-dir file keeps an
upgraded device's choice; that file is never deleted. Nothing on screen
changes.

### Files

- `frontend/lib/features/settings/domain/setting_keys.dart`
- `frontend/lib/app/theme/settings_text_store.dart`
- `frontend/lib/main.dart`
- `frontend/test/app/theme/settings_text_store_test.dart`
- `frontend/test/app/theme/theme_controller_test.dart`

### Constraints

- One source of truth, the settings store (FE-STATE-06). Persist before the
  interface confirms (FE-STATE-07).
- `app/` may read the settings barrel; `core/` must not (FE-STR-04,
  FE-STR-08).
- One public type, named for what it is (FE-STR-06, FE-CODE-03).
- The key name lives in `SettingKeys` only (FE-CODE-09).
- Tests use `SettingsStore.fake()` and `TextStore.memory()` (FE-TEST-03).
- Do not change `AppThemeMode`, how `TaptureApp` resolves the theme,
  `TextStore` itself, the widget gallery's local theme switch, or any
  screen.

### Definition of done

- [x] A written mode round-trips through a new store instance over the
      same fake.
- [x] With the key unset, the legacy value is used once and then written
      through on the next `setMode`.
- [x] A stored value wins over a different legacy value.
- [x] An unknown stored string still decodes to `AppThemeMode.system`.
- [x] Existing geometry and theme tests still pass.

## 055 — Add the Appearance settings screen

**Depends on** [003](03-design-system.md), [007](07-account-and-settings.md), [054](24-product-refinements.md)

### Implement

Settings gains an Appearance entry after Language. The screen offers System,
Light, Dark and Outdoor. The app re-themes at once and keeps the choice
through the settings store (task 310).

No system setting can pick the outdoor high-contrast theme, and field work
needs it in direct sun (FE-SIMP-12, FE-THEME-02).

### Files

- `frontend/lib/app/router.dart`
- `frontend/lib/app/feedback_host.dart`
- `frontend/lib/features/settings/presentation/appearance_settings_screen.dart`
- `frontend/lib/features/settings/presentation/presentation.dart`
- `frontend/lib/features/settings/presentation/settings_screen.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/features/settings/presentation/appearance_settings_screen_test.dart`
- `frontend/test/features/settings/presentation/settings_screen_test.dart`
- `frontend/test/app/router_test.dart`
- `frontend/test/core/copy/copy_test.dart`

### Constraints

- Reuse `AppPage`, `AppRadioGroup` and `AppListTile` (FE-CONS-01).
- The screen calls `setMode` and holds no logic (FE-STATE-04).
- Every mode uses one token set; outdoor changes contrast only
  (FE-THEME-02, FE-THEME-03).
- Default stays System (FE-SIMP-05).
- Labels live in `Copy` (FE-L10N-01, FE-L10N-02).
- The change applies live without losing in-progress input (FE-L10N-10).
- 48 dp, labelled, selection shown by the radio mark (FE-A11Y-01,
  FE-A11Y-02, FE-A11Y-05).
- Three widths, two orientations, 200 percent text (FE-RESP-10, FE-A11Y-03).
- Do not change `AppThemeMode`, token values or themes, persistence, the
  gallery switch, or any other settings section.

### Definition of done

- [x] Settings shows Appearance after Language, and tapping it opens the
      screen.
- [x] Four options; System is selected by default; choosing Dark updates
      `themeModeProvider` and a new controller over the same memory store
      restores it.
- [x] No overflow at 360, 700 and 1280 dp, portrait and landscape, 100 and
      200 percent text; 48 dp and label matchers pass.
- [x] `/more/appearance` builds the screen. Feedback names it Appearance
      with route name `settingsAppearance`.

## 056 — Show the feedback download location

**Depends on** [026](24-product-refinements.md), [049](24-product-refinements.md)

### Implement

Download feedback names where archives land before anything is downloaded.
On Android and desktop it also offers Open folder. The operator can find
past downloads without remembering a snackbar. Web and iOS keep no Open
folder; web has no location line.

### Files

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

### Constraints

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

### Definition of done

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

## 057 — Add a Save to a folder option

**Depends on** [026](24-product-refinements.md), [049](24-product-refinements.md), [056](24-product-refinements.md)

### Implement

On Android, Download feedback offers Save to a folder. The system save
picker opens with the archive name filled in, so the operator can put the
zip anywhere the picker reaches. Plain Download still saves to
`Download/Tapture`. Web, iOS and desktop do not show the control.

### Files

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

### Constraints

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

### Definition of done

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

## 058 — Show a collapse icon on the feedback form

**Depends on** [037](24-product-refinements.md)

### Implement

The control that folds Give us feedback into its bar looks and reads as collapse, not close. The bar's
control that discards the draft says so. An X then means one thing across the feedback surfaces.

### Files

- `frontend/lib/features/feedback/presentation/give_feedback_screen.dart`
- `frontend/lib/features/feedback/presentation/feedback_draft_bar.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`
- `frontend/test/core/copy/copy_test.dart`

### Constraints

- One icon per concept: collapse and expand are a pair, and X means close or discard (FE-CONS-08).
- The semantic label says what the control does (FE-A11Y-02).
- Plain language; labels live in `Copy` (FE-SIMP-10, FE-L10N-01).
- 48 dp, unchanged (FE-A11Y-01).
- Icons from the one Material family at token size (FE-THEME-08).
- Do not change fold, expand or discard behaviour; the discard confirmation; the Close controls of
  Download feedback and Delete feedback; or the floating menu.

### Definition of done

- [x] The form's top-start control shows a collapse icon, and a screen reader hears "Continue later".
- [x] Tapping it folds the form into the bar with the text and images kept.
- [x] The bar's X is announced as "Discard draft" and still confirms before clearing.
- [x] The tip on the form names "Continue later".
- [x] Tests: the form's leading control has the label "Continue later", uses `Icons.close_fullscreen`,
      and folds the draft with its text kept; the bar's X has the label "Discard draft" and still asks
      before discarding; Download and Delete Close finders stay as they are.

## 059 — Show a single feedback image as a thumbnail

**Depends on** [026](24-product-refinements.md), [027](24-product-refinements.md)

### Implement

In Give us feedback, one attached image is a square thumbnail, the same kind of tile several
images use, instead of filling the form's width. A tap still opens the full preview.

### Files

- `frontend/lib/features/feedback/presentation/feedback_shots.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

### Constraints

- Thumbnails in the form, and full images only in the viewer. Decode at the drawn size
  (`cacheWidth`), as the tile already does (FE-CONS-06, FE-PERF-04).
- Ratios and `BoxFit.cover`, not pixel sizes. Nothing stretches edge to edge
  (FE-RESP-09, FE-RESP-04).
- Start alignment mirrors in right-to-left (FE-L10N-05).
- The tile and its remove control keep 48 dp targets and labels (FE-A11Y-01, FE-A11Y-02).
- Tokens only; `galleryTile` already exists in `AppConstants` (FE-THEME-01).
- Do not change the preview dialog, the remove control, the image cap, the attach and
  include-UI checkboxes, or how several images lay out.

### Definition of done

- [x] One attached image shows as a thumbnail of about 160 dp, not a full-width picture.
- [x] Tapping the thumbnail opens the large preview, and its X removes it.
- [x] Two or more images look as they do today.
- [x] Tests: with one image, at 393 dp and at the 420 dp docked panel width, the tile is
      square and no wider than `galleryTile`; tapping it opens the preview at full width;
      with three images, the layout is unchanged; no overflow at 200 percent text.

## 060 — Borderless overflow menus

### Implement

The three-dot More control has no box unless a caller asks for one. Title bars,
the status line, project home and the expanded pane use that default. The gallery
keeps an explicit outlined specimen, and outdoor outline weight stays `Space.x0`.

### Files

- `frontend/lib/core/widgets/app_overflow_menu.dart`
- `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart`
- `frontend/test/core/widgets/app_overflow_menu_test.dart`
- `frontend/test/design_system/app_overflow_menu/gallery_golden_test.dart`

### Constraints

- Change the shared menu once (FE-CONS-01). Both variants stay in the gallery
  (FE-CONS-03).
- No new colour or width. Outdoor keeps the heavier outline (FE-THEME-01,
  FE-THEME-03, FE-THEME-10).
- The control stays 48 dp, named, and shows a token fill on hover, focus and
  press (FE-A11Y-01, FE-A11Y-02, FE-A11Y-06).
- Do not outline `StatusLine`, `AppPage`, `ProjectHomeScreen` or
  `ProjectListActions.paneToolbar`. Do not change `AppIconButton`, divider
  thickness, menu shape or menu contents.

### Definition of done

- [x] A default `AppOverflowMenu` has no border and still opens its labelled
      actions, at 48 dp, in light, dark and outdoor.
- [x] `outlined: true` still draws the theme outline, at `Space.x0 / 2` in light
      and dark and `Space.x0` outdoors.
- [x] Status line, page bar, project home and the expanded pane toolbar are
      borderless. List-row menus stay borderless.
- [x] Tests: default has no side; outlined width in all three themes; open and
      select for both variants; 200 percent text at 400, 800 and 1200.
- [x] Goldens regenerated only where a default More control lost its box.

## 061 — Resolve shell, settings and capture feedback

### Implement

Close the 22 Sep 2026 feedback archive: one database for settings screens, a status line that names the screen, no empty Site band, capture that can add a photo, caption it, resume one session, and reach templates and context.

The executable prompt is `prompts/feedback-22092026-1046/001-resolve-shell-and-capture-feedback.md`. Defaults taken: no URL photo fetch, one capture session per project, template choice stored on `ProjectSettings`.

### Files

- `frontend/lib/app/widgets/status_line.dart`
- `frontend/lib/app/shell_title.dart`
- `frontend/lib/core/db/database_provider.dart`
- `frontend/lib/features/capture/presentation/capture_screen.dart`
- `frontend/lib/features/settings/presentation/`
- `frontend/lib/features/projects/`
- `frontend/lib/features/context/presentation/`

### Definition of done

- [x] Tests: operator, capture settings, storage, status line, capture add, captions, resume, crop, context chip, template choice.

## 062 — Resolve feedback archive 23092026-1635

**Depends on** [011](11-context.md), [012](12-capture.md), [013](13-processing.md), [061](24-product-refinements.md)

### Implement

Close the 23 Sep 2026 feedback archive: durable capture saves and recovery, source-preserving shell navigation, template-driven context, reusable project search and filters, visible project pins and association counts, a compact Settings index, attached audio evidence, and registry-driven AI provider settings.

The executable prompt is `prompts/feedback-23092026-1635/001-resolve-capture-projects-settings-feedback.md`. Defaults taken: `Save and process`; Drift capture sessions; `record` plus additive attachment ownership; registry-fed AI providers with backend custody; duplicate and inactive Settings rows removed from the index.

### Files

- `frontend/lib/app/`
- `frontend/lib/core/ai/`
- `frontend/lib/core/audio/`
- `frontend/lib/core/db/`
- `frontend/lib/features/capture/`
- `frontend/lib/features/context/`
- `frontend/lib/features/projects/`
- `frontend/lib/features/settings/`
- `frontend/lib/features/templates/`
- `frontend/test/`

### Definition of done

- [x] Durable Save raw and Save and process persist evidence, raw values and context before success.
- [x] Project routes expose accessible icons and breadcrumbs and Back returns to the source screen.
- [x] Context levels and pinned fields are proposed from template metadata and inherited by capture.
- [x] Project search, filters, pin indicators and association counts work at all size classes.
- [x] Settings contains only active settings destinations; legacy routes remain valid.
- [x] Audio is stored as raw evidence and linked to its record and selected photos.
- [x] AI provider and model selection is registry-driven and keeps credentials in secure storage.
- [x] Tests: migrations, repositories, controllers, routes, widgets, failures, semantics and intended goldens.

### Verification

- `dart analyze`: clean.
- Focused capture, context, AI, reference and template suites: 59 tests passed.
- Projects, Settings and processing worker suites: 240 tests passed.
- Architecture layering and raw-evidence safety suites: 28 tests passed.
- Schema migration suite: 11 tests passed, including populated v17 and v18 upgrades.
- Intended golden suites: 45 images passed comparison.
- `flutter build apk --debug`: built `build/app/outputs/flutter-apk/app-debug.apk`.
- `dart run tool/verify.dart --fast`: analyzer, dependency allowlist, structure, plan,
  templates, and all unit/widget tests passed. The aggregate gate remains red on
  repository-wide pre-existing debt: 72 one-file-per-test entries, 11 naming
  violations, existing state/token literals, and their related guardrail tests.
- Android emulator-only back, permission, and process-death exercises were not run:
  no Android device or AVD is installed in the verification environment.

#### Regenerated intended goldens

- `frontend/test/app/goldens/nav_pane_empty_dark.png`
- `frontend/test/app/goldens/nav_pane_empty_light.png`
- `frontend/test/app/goldens/nav_pane_empty_outdoor.png`
- `frontend/test/app/goldens/nav_pane_header_text2_dark.png`
- `frontend/test/app/goldens/nav_pane_header_text2_light.png`
- `frontend/test/app/goldens/nav_pane_header_text2_outdoor.png`
- `frontend/test/app/goldens/nav_pane_projects_dark.png`
- `frontend/test/app/goldens/nav_pane_projects_light.png`
- `frontend/test/app/goldens/nav_pane_projects_outdoor.png`
- `frontend/test/features/projects/presentation/goldens/project_home_open_with_menu_dark.png`
- `frontend/test/features/projects/presentation/goldens/project_home_open_with_menu_light.png`
- `frontend/test/features/projects/presentation/goldens/project_home_open_with_menu_outdoor.png`
- `frontend/test/features/projects/presentation/goldens/project_home_open_with_menu_text2_dark.png`
- `frontend/test/features/projects/presentation/goldens/project_home_open_with_menu_text2_light.png`
- `frontend/test/features/projects/presentation/goldens/project_home_open_with_menu_text2_outdoor.png`
- `frontend/test/features/projects/presentation/goldens/project_list_numbered_pinned_dark.png`
- `frontend/test/features/projects/presentation/goldens/project_list_numbered_pinned_light.png`
- `frontend/test/features/projects/presentation/goldens/project_list_numbered_pinned_outdoor.png`
- `frontend/test/features/projects/presentation/goldens/project_list_numbered_pinned_text2_dark.png`
- `frontend/test/features/projects/presentation/goldens/project_list_numbered_pinned_text2_light.png`
- `frontend/test/features/projects/presentation/goldens/project_list_numbered_pinned_text2_outdoor.png`
- `frontend/test/features/settings/presentation/goldens/settings_index_dark.png`
- `frontend/test/features/settings/presentation/goldens/settings_index_light.png`
- `frontend/test/features/settings/presentation/goldens/settings_index_outdoor.png`
- `frontend/test/features/settings/presentation/goldens/settings_index_system.png`
- `frontend/test/features/settings/presentation/goldens/settings_index_text2_dark.png`
- `frontend/test/features/settings/presentation/goldens/settings_index_text2_light.png`
- `frontend/test/features/settings/presentation/goldens/settings_index_text2_outdoor.png`
- `frontend/test/features/settings/presentation/goldens/settings_index_text2_system.png`
- `frontend/test/features/settings/presentation/goldens/ai_provider_settings_dark.png`
- `frontend/test/features/settings/presentation/goldens/ai_provider_settings_light.png`
- `frontend/test/features/settings/presentation/goldens/ai_provider_settings_outdoor.png`
- `frontend/test/features/settings/presentation/goldens/ai_provider_settings_system.png`
- `frontend/test/features/settings/presentation/goldens/ai_provider_settings_text2_dark.png`
- `frontend/test/features/settings/presentation/goldens/ai_provider_settings_text2_light.png`
- `frontend/test/features/settings/presentation/goldens/ai_provider_settings_text2_outdoor.png`
- `frontend/test/features/settings/presentation/goldens/ai_provider_settings_text2_system.png`
- `frontend/test/features/context/presentation/goldens/context_hierarchy_dark.png`
- `frontend/test/features/context/presentation/goldens/context_hierarchy_light.png`
- `frontend/test/features/context/presentation/goldens/context_hierarchy_outdoor.png`
- `frontend/test/features/context/presentation/goldens/context_hierarchy_system.png`
- `frontend/test/features/context/presentation/goldens/context_hierarchy_text2_dark.png`
- `frontend/test/features/context/presentation/goldens/context_hierarchy_text2_light.png`
- `frontend/test/features/context/presentation/goldens/context_hierarchy_text2_outdoor.png`
- `frontend/test/features/context/presentation/goldens/context_hierarchy_text2_system.png`

## 063 — Resolve projects, capture and template feedback

**Depends on** [012](12-capture.md), [062](24-product-refinements.md)

**Implementation started:** Yes

### Status reconciliation — 2026-09-28

Photo derivation/revert, attached-template indicators, the compact project toolbar and grouped processing queue have implementation and tests, including photo_derivation_test.dart and capture_feedback_test.dart. The acceptance checklist was never reconciled. The project-home destination-grid criterion was subsequently superseded by task 068's records view; reconcile that criterion with the later requirement before closing this task, rather than reintroducing obsolete UI.

Verification 2026-09-30: owned photo-derivation, capture-feedback, screen, edit/repository and shipped-picker tests passed. The project/processing audit reports passing home/list/toolbar and queue screen/controller tests, including states, responsive layouts and semantics; project-home expectations follow task 068's current records flow and eight project destinations. Database-upgrade and intended shared-theme golden verification remain open until the final repository gates.

### Implement

Close feedback archive 23092026-2222: dependable photo preview and editing, project-scoped template navigation, compact capture and project-list surfaces, explicit template-add state, unambiguous project-home destinations, and a recomposed processing queue.

W8 (project import and export, FBK0000072) is recorded on [018](18-export.md#018--export-xlsx-csv-json-pdf-and-zip-all-produced-on-device) and [020](20-data-import.md#020--data-import-continue-an-inventory-someone-else-started) under decision D4(a), not as a new task. Task 062 already records archive 23092026-1635, so this archive is 063 (FE-FLOW-04, FE-FLOW-08).

The executable prompt is `prompts/feedback-23092026-2222/001-resolve-projects-capture-template-feedback.md`. Defaults taken: D1(a) newest derived photo with Revert; D2(a) destination grid with icons and counts; D3(a) compact queue summary; D4(a) record import and readable project exports.

### Files

- `frontend/lib/core/db/`
- `frontend/lib/core/widgets/`
- `frontend/lib/features/capture/`
- `frontend/lib/features/templates/`
- `frontend/lib/features/projects/`
- `frontend/lib/features/processing/`
- `frontend/lib/app/router.dart`
- `frontend/test/`

### Definition of done

- [x] Captured images show a cached thumbnail after capture and after session restoration.
- [x] Rotate, crop, text and drawing update the active photo, survive restart, and keep the original bytes.
- [ ] Derivation and rotation survive completion and database upgrade; pre-migration photos stay originals.
- [x] Revert walks back to the original without deleting raw evidence.
- [x] Project template destinations keep project ancestry and Back never opens Settings.
- [x] Capture sheets are content-sized and Save and process is the only primary save action.
- [x] Project search, filter and clear share one compact toolbar row.
- [x] Project context says Add templates, and shipped rows show when they are already attached.
- [x] Project home destinations name their pending counts beside an icon.
- [x] The processing queue shows one summary, one primary action and grouped rows.
- [ ] Tests: migrations, derivation, repositories, routes, widgets, failures, semantics and intended goldens.

## 064 — Resolve projects and capture feedback

**Depends on** [012](12-capture.md), [063](24-product-refinements.md)

### Implement

Close feedback archive 24092026-1016: visible captured photos and records, photo captions from the tray, one add-photo sheet, search and filters that match the reports, aligned project home, a searchable shipped library, a clear pinned-fields empty state, and a visible project export.

The executable prompt is `prompts/feedback-24092026-1016/001-resolve-projects-capture-feedback.md`.

### Files

- `frontend/lib/core/widgets/`
- `frontend/lib/features/capture/`
- `frontend/lib/features/projects/`
- `frontend/lib/features/templates/`
- `frontend/lib/features/context/`
- `frontend/lib/app/`
- `frontend/test/`

### Definition of done

- [x] Captured photos show in the tray and the viewer when the file or the session bytes exist.
- [x] Captured records appear in the Ready to process count and on the project records list.
- [x] Photo captions can target the latest photo, the selection, and every photo from the capture page.
- [x] Add photo is one sheet with icon buttons, and the tray add control matches the thumbnail.
- [x] Project search holds the filter after the microphone, and filters are a Projects › Filters page.
- [x] Project rows drop Last worked, mark archived projects, and sit close under the header.
- [x] Project home rows and destination cards align, and the cards read as buttons.
- [x] The shipped library can be searched and filtered by kind.
- [x] Pinned fields tell the operator to mark a field when a template is already attached.
- [x] Export is in both project menus and writes a new `.xlsx` without replacing an earlier one.
- [x] Tests: repositories, routes, widgets, and failure paths named by the prompt.

## 065 — Place the audio record control in the caption field

### Implement

Move the capture record control into the Caption field, after the speech-to-text microphone. The Audio heading and the Record audio button go away. Recording still writes the same local file and still asks which photos the clip belongs to after stop.

The executable prompt is `prompts/feedback-24092026-1453/001-place-audio-record-in-caption.md`.

### Files

- `frontend/lib/features/capture/presentation/record_caption_field.dart`
- `frontend/lib/features/capture/presentation/capture_screen.dart`
- `frontend/lib/features/capture/presentation/audio_recorder.dart`
- `frontend/test/features/capture/presentation/capture_feedback_test.dart`

### Definition of done

- [x] The Caption field shows the speech-to-text microphone, then a waveform button labelled `Copy.captureRecordAudio`.
- [x] The capture page has no Audio heading and no Record audio button.
- [x] Tapping the waveform button starts the existing recorder. Pause and stop remain available until the recording ends.
- [x] Typing in Caption still stores only the record caption.
- [x] Tests: `capture_feedback_test.dart` covers the layout matrix and the recording start.

## 066 — Resolve project, capture and export feedback

### Implement

Close the 24 September 2026 feedback archive using its defaults: export copies use `PROJECT-NAME-DDMMYY-HHMMSS.xlsx` under `Tapture/Exports`, screen titles follow the active page, capture photos and actions match the reports, and the project home lists captured items beside the existing hub.

The executable prompt is `prompts/feedback-24092026-2143/001-resolve-project-capture-feedback.md`. Decisions D1–D7 use the defaults in that prompt.

### Files

- `frontend/lib/core/files/download_service.dart`
- `frontend/lib/core/files/download_service_io.dart`
- `frontend/lib/features/exports/domain/export_file_name.dart`
- `frontend/lib/features/projects/presentation/project_export_screen.dart`
- `frontend/lib/features/capture/presentation/capture_screen.dart`
- `frontend/lib/features/capture/presentation/photo_tray.dart`
- `frontend/lib/features/context/presentation/context_hierarchy_screen.dart`
- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/lib/features/projects/presentation/captured_items.dart`
- `frontend/lib/features/templates/presentation/template_list_screen.dart`
- `frontend/lib/features/templates/presentation/field_list_screen.dart`
- `frontend/android/app/src/main/kotlin/com/tapture/app/MainActivity.kt`

### Definition of done

- [x] Export display names are `PROJECT-NAME-DDMMYY-HHMMSS.xlsx`, and a copy is written under `Tapture/Exports` without moving feedback downloads.
- [x] Create project, Capture, Project templates, and Project contexts are the active-page titles. The projects-list Show archived menu stays on that list.
- [x] Capture thumbnails open the photo, remove a draft, and caption one photo or the selection.
- [x] Save actions and the add-photo actions are stacked and full width.
- [x] Context levels can share an order, and pinned fields open from the project home.
- [x] The project home lists captured items, switches templates, and archives instead of deleting photos.
- [x] Tests: export name, download subfolder, status-line titles, photo tray, shared context level, and the project home.

## 067 — Resolve project, template and capture feedback

### Implement

Close the 25 September 2026 feedback archive (FBK0000117–FBK0000131) using the defaults of its decisions D1–D6.
Audio recording saves a playable WAV file. A captured item is edited field by field. The shell stops padding
the top inset twice. Full-width buttons fill their slot. The shipped library is one list under seven categories.
Sheets draw one handle and fit their content. The template list has one add action. Pinned fields and project
contexts move into the project menu. The home template list loses its frame and the home gets a page gutter.
The project search is pinned at the top. Capture offers project and template switches and spaces its blocks.

Every icon is named through one vocabulary, `AppIcons`, drawn from widely recognised glyphs, and a guardrail
rejects an `Icons.` glyph anywhere else (FE-CONS-08).

The executable prompt is `prompts/feedback-25092026-1124/001-resolve-project-template-capture-feedback.md`.
Decisions D1–D6 use the defaults in that prompt.

### Files

- `frontend/lib/core/audio/audio_recorder_plugin.dart`
- `frontend/lib/core/constants/app_constants.dart`
- `frontend/lib/app/nav_shell.dart`
- `frontend/lib/core/widgets/app_icons.dart`
- `frontend/lib/core/widgets/app_button.dart`
- `frontend/lib/core/widgets/app_page.dart`
- `frontend/lib/core/widgets/feedback/app_bottom_sheet.dart`
- `frontend/lib/core/widgets/fields/app_radio_group.dart`
- `frontend/lib/core/widgets/fields/app_choice_field.dart`
- `frontend/lib/features/templates/domain/shipped_template_category.dart`
- `frontend/lib/features/templates/presentation/shipped_picker_screen.dart`
- `frontend/lib/features/templates/presentation/template_list_screen.dart`
- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/lib/features/projects/presentation/captured_items.dart`
- `frontend/lib/features/projects/presentation/record_edit_sheet.dart`
- `frontend/lib/features/projects/presentation/record_edit_controller.dart`
- `frontend/lib/features/projects/presentation/project_template_selection.dart`
- `frontend/lib/features/capture/domain/capture_template_choice.dart`
- `frontend/lib/features/capture/presentation/capture_target_fields.dart`
- `frontend/lib/features/capture/presentation/capture_screen.dart`
- `frontend/lib/features/capture/presentation/photo_tray.dart`
- `frontend/lib/features/capture/presentation/audio_recorder.dart`
- `frontend/test/architecture/icons_test.dart`

### Definition of done

- [x] Start then stop writes a WAV file through `FileWriter.copyIn`; the staging file is removed only after the copy, and a start failure reads "Recording could not start."
- [x] Shell pages see no top inset under the header, at compact, medium and expanded widths.
- [x] Save raw, the add-photo actions, Add level and the template add action fill their slot at the primary action's height.
- [x] The shipped library shows seven category headings; a search miss sits directly under the search field; Save adds only ticked templates.
- [x] Every modal sheet draws one handle and ends at its content.
- [x] A raw-saved item lists every editable template field; a new value is stored once as typed, a stored one is refined, and a failed save keeps the text.
- [x] The template list has one add action, reading Add more templates once a template exists.
- [x] Pinned fields and Project contexts open from the project menu; the home template list is unframed and in line with its label; the home search is pinned at the top.
- [x] Capture shows Project and Template fields that open a searchable list, shares its template choice with the home, and spaces its blocks by 16dp.
- [x] Every icon is an `AppIcons` concept; `icons_test.dart` fails on a raw glyph.
- [x] Tests: audio plugin, shell inset, button expand, sheet sizing, library categories, record editor, template list, project home, capture template choice, radio and choice fields, icon guardrail.

## 068 — Resolve project, record, capture and export feedback

### Implement

Close the 25 September 2026 21:20 feedback archive (FBK0000132–FBK0000142, FBK0000144) using the defaults of
its decisions D1–D8. An open keyboard no longer collapses shell pages and sheets. Record rows show their photo,
and template rows count their records. The project home holds only the record search and the records list. A
record opens on its own page and is edited on the capture page. On capture, photos are ticked with a checkbox,
a caption goes to the ticked photos (to all when none is ticked), each photo's caption is edited in its preview,
and Save and process waits for a network. The export page summarises the project and sends the file to other
apps. A new template takes several fields at once.

The executable prompt is `prompts/feedback-25092026-2120/001-resolve-project-record-capture-export-feedback.md`.
Decisions D1–D8 use the defaults in that prompt: (a) in every case.

### Files

- `frontend/lib/app/nav_shell.dart`
- `frontend/lib/app/router.dart`
- `frontend/lib/app/route_paths.dart`
- `frontend/lib/app/shell_title.dart`
- `frontend/lib/main.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/core/files/photo_thumbnails.dart`
- `frontend/lib/core/files/download_service.dart`
- `frontend/lib/core/files/download_service_io.dart`
- `frontend/lib/core/files/download_service_web.dart`
- `frontend/lib/core/network/offline_now.dart`
- `frontend/lib/core/widgets/app_photo_thumb.dart`
- `frontend/lib/core/widgets/fields/app_choice_field.dart`
- `frontend/lib/features/projects/domain/project_repository.dart`
- `frontend/lib/features/projects/data/project_repository_impl.dart`
- `frontend/lib/features/projects/projects.dart`
- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/lib/features/projects/presentation/captured_items.dart`
- `frontend/lib/features/projects/presentation/project_records_screen.dart`
- `frontend/lib/features/projects/presentation/record_detail_screen.dart`
- `frontend/lib/features/projects/presentation/record_edit_sheet.dart`
- `frontend/lib/features/projects/presentation/project_export_screen.dart`
- `frontend/lib/features/projects/presentation/export_summary_view.dart`
- `frontend/lib/features/exports/domain/export_repository.dart`
- `frontend/lib/features/exports/domain/export_summary.dart`
- `frontend/lib/features/exports/data/export_repository_impl.dart`
- `frontend/lib/features/templates/presentation/template_list_screen.dart`
- `frontend/lib/features/templates/presentation/template_create_screen.dart`
- `frontend/lib/features/templates/presentation/template_field_rows.dart`
- `frontend/lib/features/capture/domain/caption_apply.dart`
- `frontend/lib/features/capture/domain/capture_session.dart`
- `frontend/lib/features/capture/domain/capture_session_key.dart`
- `frontend/lib/features/capture/domain/capture_persistence.dart`
- `frontend/lib/features/capture/domain/capture_record_persistence.dart`
- `frontend/lib/features/capture/data/capture_record_writer.dart`
- `frontend/lib/features/capture/data/drift_capture_persistence.dart`
- `frontend/lib/features/capture/presentation/capture_controller.dart`
- `frontend/lib/features/capture/presentation/capture_screen.dart`
- `frontend/lib/features/capture/presentation/photo_tray.dart`
- `frontend/lib/features/capture/presentation/photo_viewer_screen.dart`

### Definition of done

- [x] With the keyboard open, a shell page shows its search field, part of its list and its footer, at every width and in both orientations, and a choice sheet keeps its options visible above the keyboard.
- [x] A record with a photo shows that photo, turned the way it was saved; a cropped photo shows its cropped version; a removed photo is never the thumbnail; a missing file shows Missing photo.
- [x] Each template row shows how many live records use it, and Delete is offered only for a template with no records.
- [x] The project home shows the search field and the records list only; no count-card symbol remains; Templates and Project contexts open from the menu.
- [x] The home search reads "Search records", and a query with no match names the query, on the home and in every choice sheet.
- [x] While offline, Save and process is disabled with a caption, and Save raw still saves.
- [x] On Android and iOS, Share opens the system share sheet with a hint; a failed share says why.
- [x] The export page summarises records, photos, audio, capture dates, status counts, templates and the file, with Export and Share in its footer.
- [x] Each tray photo has a checkbox and a remove control and no Caption button; a caption fills the one photo, all photos with none ticked, or the ticked photos.
- [x] The photo preview shows the caption with Edit caption and Delete caption; a delete asks and can be undone.
- [x] New template takes a name and several fields, and Create saves them together with unique keys.
- [x] Tapping a record opens its page, which edits its fields and deletes it.
- [x] A record's Edit opens capture with its photos and captions; Save changes updates the same record, refining raw values; an unsaved new capture is untouched.
- [x] Tests: shell insets, record thumbnails, template counts, project home, search no-match, offline capture, export share and summary, photo checkbox and captions, preview captions, template create rows, record page, record edit session and writer.

## 069 — Resolve record, capture markup and project photo feedback

### Implement

Close the 26 September 2026 04:34 feedback archive (FBK0000145–FBK0000154) using the defaults of its decisions
D1–D7. Tapping a record opens its page, and its Edit opens that record on the capture page. Record rows and the
capture tray show real thumbnails. Captions typed on capture keep every keystroke and say which photos they go to.
Crop, draw and type-on each save what the screen shows. Photo corner controls read on any photo. Page content
scrolls clear of the folded feedback bar, and a project can carry a photo.

The executable prompt is `prompts/feedback-26092026-0434/001-resolve-record-capture-markup-feedback.md`.
Decisions D1–D7 use the defaults in that prompt: (a) in every case.

### Files

- `frontend/lib/app/router.dart`
- `frontend/lib/app/route_paths.dart`
- `frontend/lib/app/theme/markup_ink.dart`
- `frontend/lib/core/constants/app_constants.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/core/files/thumbnail_cache.dart`
- `frontend/lib/core/files/photo_picker.dart`
- `frontend/lib/core/widgets/app_photo_thumb.dart`
- `frontend/lib/core/widgets/app_ink_picker.dart`
- `frontend/lib/core/widgets/photo_markup.dart`
- `frontend/lib/core/widgets/markup_stroke.dart`
- `frontend/lib/core/widgets/markup_text.dart`
- `frontend/lib/features/feedback/presentation/feedback_overlay.dart`
- `frontend/lib/features/capture/domain/capture_session.dart`
- `frontend/lib/features/capture/domain/capture_session_key.dart`
- `frontend/lib/features/capture/domain/capture_persistence.dart`
- `frontend/lib/features/capture/domain/capture_record_persistence.dart`
- `frontend/lib/features/capture/data/capture_record_writer.dart`
- `frontend/lib/features/capture/data/drift_capture_persistence.dart`
- `frontend/lib/features/capture/presentation/capture_controller.dart`
- `frontend/lib/features/capture/presentation/capture_screen.dart`
- `frontend/lib/features/capture/presentation/record_caption_field.dart`
- `frontend/lib/features/capture/presentation/photo_frame.dart`
- `frontend/lib/features/capture/presentation/photo_crop_screen.dart`
- `frontend/lib/features/capture/presentation/photo_doodle_screen.dart`
- `frontend/lib/features/capture/presentation/photo_type_screen.dart`
- `frontend/lib/features/capture/presentation/photo_viewer_screen.dart`
- `frontend/lib/features/capture/presentation/photo_tray.dart`
- `frontend/lib/features/projects/domain/project_settings.dart`
- `frontend/lib/features/projects/domain/project_repository.dart`
- `frontend/lib/features/projects/data/project_repository_impl.dart`
- `frontend/lib/features/projects/presentation/captured_items.dart`
- `frontend/lib/features/projects/presentation/record_detail_screen.dart`
- `frontend/lib/features/projects/presentation/project_create_screen.dart`
- `frontend/lib/features/projects/presentation/project_edit_screen.dart`
- `frontend/lib/features/projects/presentation/project_list_view.dart`
- `frontend/lib/main.dart`

### Definition of done

- [x] Tapping a record row opens its page, with no not-found page, at every width; the page shows the record's photos, caption, field values, audio count and capture time, and its menu edits the fields and deletes the record.
- [x] Fast typing into the caption field keeps every character and the text lands on the targets; the line under the field names how many photos the caption goes to; changing the ticks shows the new targets' caption.
- [x] With the default decoder, a stored JPEG gets a cached thumbnail no larger than the requested edge; record rows and the capture tray show the photo.
- [x] The crop frame starts on the photo, resizes from its corners and moves inside it; the saved crop is the region shown; after crop, draw and type-on the preview shows the new version.
- [x] With feedback minimized, every page's last content and footer action scroll into view above the bar, also with the keyboard open; closed and expanded feedback leave pages as before.
- [x] The select and remove controls sit flush in the thumbnail's top corners and are visible on black and white photos in all three themes.
- [x] Six named inks and three sizes are tokens and appear in `AppInkPicker`.
- [x] Draw offers the inks and sizes, each stroke keeps its own, and the saved photo shows the strokes where and as they were drawn.
- [x] Type-on shows the text live in the chosen ink, size and position, with several lines, a backing switch and dragging, and saves it where placed.
- [x] A record's Edit opens capture with its photos, captions and audio; Save changes updates the same record, refining raw captions; leaving without saving changes nothing; an unsaved new capture is untouched; field values are edited from the record page.
- [x] A project can be given, changed and cleared a photo from the create and edit screens, and one with a photo shows it as its list thumbnail.
- [x] Tests: record route and page, caption typing and targets, thumbnail decoder, photo frame and crop, folded feedback insets, corner controls, ink picker, draw and type-on markup, record edit session and writer, project photo.

## 070 — Resolve web capture, caption and template feedback

### Implement

Close FBK0000002–FBK0000005 from the 26 September 2026 15:49 archive and FBK0000155 from the 15:50 archive. In a
browser, a photo from the webcam or the library is kept on the device and shows in the capture tray and the viewer.
On every platform, capture's Project and Template selects are one field tall and sit side by side with the two
saves from medium width up, and the empty tray's icon is itself the add action. Typing and dictating a caption no
longer writes it onto any photo; a button under the field adds it to the photos it names. Template fields list
Required, then Recommended, then Optional; every list search bar with facets carries the same filter button; and a
field's default value fills it when nothing else does.

The executable prompt is `prompts/feedback-26092026-1550/001-resolve-web-capture-caption-template-feedback.md`.
Decisions D1–D7 use the defaults in that prompt, (a) in every case:

- D1: web keeps photo files in IndexedDB through `BlobStore` (store `AppConstants.projectFiles.storeName`), and the
  first write asks the browser once for persistent storage; a reload keeps them, clearing site data removes them.
- D2: the field list shows Required, Recommended and Optional sections, each in stored order, and moves stay
  inside a section; the stored order capture and exports read does not change.
- D3: the filter button goes on projects, template fields (requiredness, type), templates (kind) and a project's
  records (status); pickers in sheets, the dataset browser and the feedback panel keep search only.
- D4: processing's validate stage writes a field's default into a field still empty after extraction, unverified,
  with provenance source `default`, and it counts as filled for the record status. Defaults are not written at
  save time.
- D5: the empty tray's add-photo icon is the add action, a labelled button, and the separate button is gone.
- D6: the caption button adds the text on a new line after a photo's existing caption.
- D7: after a successful add the caption field clears and a snack says how many photos got it.

FBK0000155 supersedes decision D2 of task 069 (a caption goes to the ticked photos as it is typed): the later
request, made after using that behaviour, wins. FBK0000149's ask, adding a caption to several photos before
saving, stays met through the button.

Names that differ from the prompt, because the prompt's would break a guardrail: the blob writer and reader live
in `blob_file_writer.dart` and `blob_file_reader.dart`, named for the types they hold (FE-STR-06), and a project's
records filter is `ProjectRecordFilter` in `project_record_filter.dart`, since `Item` is a banned word in a type
name (FE-CODE-03). The three list filters open one shared `showAppFilterSheet` beside `showAppSheet` (FE-CONS-02,
FE-CONS-05). A drag longer than one place lays the section's fields back into the section's own stored slots; a
one-place move swaps exactly two fields.

Web surfaces W1 and W2 leave out (processing, export, record-list and project-cover thumbnails) are task
[071](24-product-refinements.md#071--enable-processing-export-and-list-thumbnails-on-web). Processed records missing from the project home are task
[072](24-product-refinements.md#072--list-processed-records-on-the-project-home). A Resume tapped while the Capture page's first writes are
in flight losing the resumed photos is task [073](24-product-refinements.md#073--keep-resumed-capture-photos).

### Files

- `frontend/lib/main.dart`
- `frontend/lib/core/constants/app_constants.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/core/files/path_sanitizer.dart`
- `frontend/lib/core/files/file_writer.dart`
- `frontend/lib/core/files/file_writer_io.dart`
- `frontend/lib/core/files/file_writer_web.dart`
- `frontend/lib/core/files/file_writer_stub.dart`
- `frontend/lib/core/files/blob_file_writer.dart`
- `frontend/lib/core/files/file_reader.dart`
- `frontend/lib/core/files/file_reader_io.dart`
- `frontend/lib/core/files/file_reader_web.dart`
- `frontend/lib/core/files/file_reader_stub.dart`
- `frontend/lib/core/files/blob_file_reader.dart`
- `frontend/lib/core/widgets/photo_asset.dart`
- `frontend/lib/core/widgets/app_photo_thumb.dart`
- `frontend/lib/core/widgets/fields/app_choice_field.dart`
- `frontend/lib/core/widgets/responsive/responsive_pair.dart`
- `frontend/lib/core/widgets/states/app_empty_state.dart`
- `frontend/lib/core/widgets/app_search_field.dart`
- `frontend/lib/core/widgets/feedback/app_bottom_sheet.dart`
- `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart`
- `frontend/lib/features/capture/data/drift_photo_repository.dart`
- `frontend/lib/features/capture/presentation/capture_screen.dart`
- `frontend/lib/features/capture/presentation/capture_target_fields.dart`
- `frontend/lib/features/capture/presentation/photo_tray.dart`
- `frontend/lib/features/capture/presentation/record_caption_field.dart`
- `frontend/lib/features/projects/presentation/project_list_toolbar.dart`
- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/lib/features/projects/presentation/captured_items.dart`
- `frontend/lib/features/projects/presentation/project_record_filter.dart`
- `frontend/lib/features/templates/presentation/template_list_screen.dart`
- `frontend/lib/features/templates/presentation/template_list_filter.dart`
- `frontend/lib/features/templates/presentation/field_list_screen.dart`
- `frontend/lib/features/templates/presentation/field_list_filter.dart`
- `frontend/lib/features/templates/presentation/field_reorder.dart`
- `frontend/lib/features/processing/domain/proposal_application.dart`
- `frontend/lib/features/processing/data/validate_stage.dart`

### Definition of done

- [x] W1 — In a browser, `FileWriter` keeps files in IndexedDB through `BlobFileWriter` (same sha256 and length as
      the device writer), asks once for persistent storage, and `DriftPhotoRepository.readBytes` reads them back
      through `FileReader`, also after a reload; the device writer, its `.part` handling and its tests are unchanged.
- [x] W2 — `PhotoAsset.thumbBytes` draws through `Image.memory` decoded at thumbnail size; a browser's capture tray
      (new record and edit) draws the bytes it holds or reads back, never opens a `File`, and tapping a thumb opens
      the viewer; native trays keep their cached thumbnail files.
- [x] W3 — A sheet choice field is as tall as a labelled single-line text field and at least 48dp, unclipped at 200
      percent text.
- [x] W4 — `ResponsivePair` stacks on compact and shares a row in its flex ratio from medium up, start first in
      reading order, with a gallery entry and goldens at three widths in three themes.
- [x] W5 — `AppEmptyState` with `onIconTap` and `iconLabel` makes its icon a named 48dp button; every existing
      empty state renders as before.
- [x] W6 — `AppSearchField.onFilter` and `activeFilterCount` draw the one filter button after the microphone;
      `Copy.searchFilters` replaces `Copy.projectFilters`; the projects toolbar uses it.
- [x] W7 — The templates search filters by kind and a project's records search filters by status, each with a
      count on its button and Clear filters.
- [x] W8 — On Capture, Project and Template share a row, and so do Save raw and Save and process (the primary
      twice as wide), from medium width up; compact keeps today's order; the empty tray's icon opens the photo
      source sheet and the Add photo button is gone; nothing overflows at 200 percent text in either orientation.
- [x] W9 — Typing and dictating change no photo caption; a secondary button reads "Add to all n photos" or "Add to
      n ticked photos", appends the text after existing captions, clears the field and says how many photos got it;
      a failed add keeps the text; untouched text stays the record caption; on Capture and on the record edit page.
- [x] W10 — Template fields list Required, Recommended, then Optional sections in stored order; up, down and drag
      stay inside a section and change only the fields moved; the field search filters by requiredness and type.
- [x] W11 — Processing fills a field left empty with its default, unverified, source `default`, no evidence and an
      audit row; extracted, stored, verified and hand-entered values win; a required field its default fills
      counts as filled; the field row shows "Default: value".
- [x] Tests: `blob_file_writer_test`, `file_reader_test`, `drift_photo_repository_test`, `app_photo_thumb_test`,
      `app_choice_field_test`, `responsive_pair_test`, `app_empty_state_test`, `app_search_field_test`,
      `app_bottom_sheet_test`, `template_list_screen_test`, `project_home_screen_test`,
      `project_list_screen_test`, `capture_widgets_test`, `capture_feedback_test`, `capture_edit_screen_test`,
      `field_list_screen_test`, `field_reorder_test`, `proposal_application_test`, `validate_stage_test`.
- [x] Goldens regenerated: only for the items that change a catalogue image (local baselines, not
      tracked): W2 `test/design_system/app_photo_thumb/goldens/app_photo_thumb_{light,dark,outdoor}.png`; W3
      `test/design_system/app_choice_field/goldens/app_choice_field_{light,dark,outdoor}.png`, and, because every
      sheet choice field is now one field tall,
      `test/features/settings/presentation/goldens/ai_provider_settings_{light,dark,outdoor}.png`; W4 (new)
      `test/design_system/responsive_pair/goldens/responsive_pair_{compact,medium,expanded}_{light,dark,outdoor}.png`
      and `test/design_system/goldens/responsive_pair_{light,dark,outdoor}.png`; W5
      `test/design_system/app_empty_state/goldens/app_empty_state_{light,dark,outdoor}.png`; W6
      `test/design_system/app_search_field/goldens/app_search_field_{light,dark,outdoor}.png`. Every other golden
      matches its baseline from the commit before this task.
- [x] [071 — Enable processing, export and list thumbnails on web](24-product-refinements.md#071--enable-processing-export-and-list-thumbnails-on-web),
      [072 — List processed records on the project home](24-product-refinements.md#072--list-processed-records-on-the-project-home) and
      [073 — Keep resumed capture photos](24-product-refinements.md#073--keep-resumed-capture-photos) are in the plan.

### Verification

`dart run tool/verify.dart` on this change fails the same gates, with the same findings, as on the commit
before it; these failures predate task 070 and nothing here adds to them:

- test presence: the 47 files already listed as owing a test (for example
  `lib/features/capture/domain/caption_apply.dart`, `capture_screen.dart`).
- `test/architecture/errors_test.dart`: `capture_record_writer.dart` throws `_recordGone`, and
  `ExportRepositoryImpl.scope` returns a list.
- `test/architecture/state_test.dart`: the 35 `setState` and provider placements already reported.
- `test/tool/check_naming_test.dart`: the 19 naming findings already reported (for example `CapturedItems`).
- `test/tool/check_structure_test.dart`: the canonical core directory list orders `location` before
  `logging`.
- `test/tool/check_tests_test.dart`: the same 47 missing tests.

The golden baselines are local files; with baselines generated from the commit before this task, every golden
passes after the regenerations listed above. The release web build compiles.

In Chromium, on the release web build at 1280 by 900: Capture shows Project and Template side by side at one
field tall, Save raw and Save and process side by side, and the empty tray's icon with no Add photo button; the
icon opens the photo source sheet; a library photo saves with no error snack and shows in the tray at once; Save
raw saves the record; after a reload the record's Edit reads the photo back into its tray and the viewer shows
it, and a resumed draft does the same; the projects, records, templates and field searches carry the filter
button, and the field list opens on its Required section. The record row's thumbnail on web still shows the
missing-photo placeholder, which is task 071.

## 071 — Enable processing, export and list thumbnails on web

**Depends on** [070](24-product-refinements.md)

### Implement

**Implementation started:** Yes

Processing and shared thumbnails are being moved onto the platform file services. Task 076 already supplies the
browser bundle/download path; regression coverage will verify that path with browser-backed photos.

2026-10-01 audit: host regressions exercise `BlobStore.memory` with every processing stage and the production
package writer, preserving originals and stored exports. `integration_test/browser_product_test.dart` adds an
actual-browser wasm SQLite/IndexedDB run for the controller, exported photo contents, platform download call and
shared bounded thumbnail rendering. Its execution and the final platform regressions remain pending; the mere
existence of a browser-safe test is not acceptance evidence.

Task 070 keeps capture's photo files in the browser: on web, `FileWriter` writes into the IndexedDB store
`AppConstants.projectFiles.storeName` through `BlobFileWriter`, and `FileReader` reads them back. The capture tray
draws its thumbnails from those bytes. Every other surface that opens a project file still reads through
`dart:io`, which has no browser implementation, so on web it fails or shows the missing-photo placeholder.

Move those readers onto `FileReader` so a browser can process, export and list what it captured:

- Processing: the prepare, on-device and online stages and the egress summary open photos, transcripts and
  audio through `File` (`features/processing/data/prepare_stage.dart`, `on_device_stage.dart`,
  `online_transcripts.dart`, `egress_summary.dart`, `photo_paths.dart`). They read bytes through `FileReader`
  and write derived files through `FileWriter`; on-device OCR stays unavailable on web and says so.
- Export: `features/exports/data/export_repository_impl.dart` reads photos and writes the archive through `File`.
  It reads through `FileReader`, and the finished file reaches the operator through `DownloadService`.
- Thumbnails: `core/files/thumbnail_cache.dart` writes cached files that `AppPhotoThumb` opens by path. On web the
  record-list thumbnail (`features/projects/presentation/record_thumb.dart`), the record page's photos and the
  project cover (`project_list_view.dart`) draw `PhotoAsset.thumbBytes` read through `FileReader`, decoded at
  thumbnail size (FE-PERF-04).

Native platforms keep their files, cache and paths unchanged.

### Files

- `frontend/lib/core/files/thumbnail_cache.dart`
- `frontend/lib/core/files/photo_thumbnails.dart`
- `frontend/lib/features/processing/data/prepare_stage.dart`
- `frontend/lib/features/processing/data/on_device_stage.dart`
- `frontend/lib/features/processing/data/online_transcripts.dart`
- `frontend/lib/features/processing/data/egress_summary.dart`
- `frontend/lib/features/processing/data/photo_paths.dart`
- `frontend/lib/features/exports/data/export_repository_impl.dart`
- `frontend/lib/features/projects/presentation/record_thumb.dart`
- `frontend/lib/features/projects/presentation/project_list_view.dart`
- `frontend/lib/main.dart`

### Definition of done

- [ ] On web, Save and process runs a captured record through processing without a file error.
- [ ] On web, an export of a project with photos downloads a file that holds those photos.
- [ ] On web, record rows, the record page and the project list show photo thumbnails decoded at thumbnail size.
- [ ] Android keeps its files, thumbnail cache and paths; every existing processing, export and thumbnail test
      still passes.
- [ ] Tests: processing stages, export and thumbnails over `BlobFileWriter` and `FileReader` with
      `BlobStore.memory`.

## 072 — List processed records on the project home

**Depends on** [070](24-product-refinements.md)

### Implement

Found while building task 070's records status filter. Processing's validate stage writes the record status
`NEEDS_REVIEW` or `EXTRACTED` (`ProposalApplication.needsReviewStatus`, `extractedStatus`), but the project home
lists records whose status is in `capturedItemStatuses` (`features/projects/presentation/captured_items.dart`),
which spells those two `needsReview` and `extracted`. `ProjectRepositoryImpl.watchRecords` and
`watchTemplateRecordCounts` match with SQL `IN`, which is case-sensitive, so a record drops off the project home,
out of its template's record count and out of the status filter as soon as processing finishes. Task 070's W11
makes `EXTRACTED` more common, since a default can now fill a required field.

Make the stored status and the listed statuses agree: one set of status values, written by capture and processing
and read by the lists, so every live record is listed whatever stage it has reached. `ProjectRecordFilter.statusOf`
already folds case and separators when naming a stored status.

### Files

- `frontend/lib/features/projects/presentation/captured_items.dart`
- `frontend/lib/features/projects/data/project_repository_impl.dart`
- `frontend/lib/features/processing/domain/proposal_application.dart`

### Definition of done

- [x] A record that processing marks `NEEDS_REVIEW` or `EXTRACTED` stays on its project home, in its template's
      record count, and under its status in the records filter.
- [x] Records captured before the change are listed without a migration step the operator has to run.
- [x] Tests: repository watch queries over records in every status, and a project home widget test with a
      processed record.

## 073 — Keep resumed capture photos

**Depends on** [070](24-product-refinements.md)

### Implement

Found while checking task 070 in a browser. When the Capture page opens, its first frames schedule
`CaptureController.setTemplate` and `setContext` for the fresh session. Each builds its next session from `state`
as it was when called, awaits `saveSession`, and only then assigns it. If the operator taps Resume on the recovery
prompt while those saves are still in flight, `replaceSession` sets the resumed session, and the late
`setTemplate` or `setContext` then assigns and stores the fresh, photo-less session over it. The tray shows no
photos and the stored draft loses them; the photo rows and files stay, unlinked from any session. A browser's
database writes are slow enough to hit this every time Resume is tapped within a few seconds of opening Capture;
a device can hit it too.

Make every session change apply to the session current when its write lands, never to a stale copy, so no change
can undo another; a resumed session keeps its photos, captions and audio.

### Files

- `frontend/lib/features/capture/presentation/capture_controller.dart`
- `frontend/lib/features/capture/presentation/capture_screen.dart`

### Definition of done

- [x] Resume tapped while the template and context writes are still in flight keeps every resumed photo, caption
      and audio clip, in the tray and in the stored session.
- [x] Concurrent caption, value, template and context changes each land, whatever order their writes finish in.
- [x] Tests: controller tests with a session store whose writes finish out of order, and a capture screen test that
      resumes during slow writes.

## 074 — Ship the full template catalogue

### Implement

Ship every template of the planning catalogue `resources/templates.md` (2,349 templates, 72 categories, 17
supergroups, 26 shared archetype packs) in the app's library beside the 23 starter templates of §13.4. Each must
capture every field its record needs, be easy to find, and be copied into a project as an ordinary editable template
(§11.1, §13.6). The specification's new §13.7 describes the result.

Decisions, each the smallest that meets the ask without changing an existing behaviour:

- D1: the catalogue is generated, not hand-written. `frontend/tool/build_template_catalogue.dart` reads
  `resources/templates.md`, the typed packs in `frontend/tool/template_catalogue/packs.json` and the choice lists and
  per-field corrections in `frontend/tool/template_catalogue/field_rules.json`, and writes
  `frontend/assets/templates/catalogue/` plus the readable list `resources/template-library.md`. `--check` exits 1
  when a committed file has drifted.
- D2: a catalogue template is composed, not copied out in full: it inherits the four groups of §13.3, its category's
  context group (`context_<category>`, stickable, suggested RECOMMENDED) and its record type's pack
  (`pack_<pack>`), then adds its own starter fields (suggested RECOMMENDED, group `specific_details`). Packs and
  contexts live in `catalogue/_groups.json` and resolve through the same `inherits_groups` path the starter
  templates use. One asset per category keeps the web build to 74 requests, not 2,349.
- D3: every column is atomic (§13.1). Pack fields are typed by hand (`parties` becomes first, second and other party
  names; `dates` becomes start and end dates; `totals` becomes an amount and its currency; a `*_time` becomes a date
  and a time). Starter fields are typed by rules on their last word, with overrides for the 60-odd keys the rules
  would get wrong (19 `*_and_*` keys split in two, `address` narrowed to `street_address`, non-money `*_amount`,
  spans and odometers). Money gets a `_currency` companion and `MANUAL_ONLY` input, a stated measure gets a `_unit`
  companion, sizes split into length, width and height in millimetres, `*_timestamp` becomes `*_at`, a deadline
  becomes `*_date`, and prose an AI may rewrite is marked `refine`.
- D4: identity (§40) comes from the record type: each pack names its identity fields, so records of the same type
  match the same way in every category.
- D5: the library lists light entries, and resolves fields only for a preview or a copy. The catalogue index is built
  once off the UI thread through `runIsolate` (FE-PERF-02) and kept; a failed read is not kept. `library()` still
  returns the 23 starter templates; `entries()` lists all 2,372 and `template(key)` resolves any one of them.
- D6: names, category and record-type titles and guidance are catalogue data (FE-L10N-07): a catalogue asset keeps
  `name` as a `templates.<key>.name` key for the schema and carries its display `title`; field labels are
  `templates.catalogue.<key>` and resolve through `Copy.shippedLabel`.
- D7: the picker keeps its starter layout when only starter templates are listed, and adds area headings once
  catalogue templates are listed. Search matches name, code, category, area, record type, kind and own field labels,
  every word; the shared filter button (task 070) narrows by area, record type and tier. The list is built lazily.

### Files

- `resources/templates.md` (source, unchanged), `resources/template-library.md` (generated)
- `frontend/tool/build_template_catalogue.dart`, `frontend/tool/template_catalogue/packs.json`,
  `frontend/tool/template_catalogue/field_rules.json`
- `frontend/assets/templates/catalogue/` (generated: `_catalogue.json`, `_groups.json`, 72 category files),
  `frontend/assets/templates/_schema.json`, `frontend/pubspec.yaml`
- `frontend/tool/check_templates.dart`
- `frontend/lib/core/constants/template_assets.dart`, `frontend/lib/core/copy/copy.dart`
- `frontend/lib/features/templates/domain/shipped_template_entry.dart`,
  `frontend/lib/features/templates/domain/shipped_record_type.dart`,
  `frontend/lib/features/templates/domain/shipped_catalogue_category.dart`
- `frontend/lib/features/templates/data/shipped_template_loader.dart`, `frontend/lib/features/templates/templates.dart`
- `frontend/lib/features/templates/presentation/shipped_picker_screen.dart`,
  `frontend/lib/features/templates/presentation/shipped_library_filter.dart`
- `app-write-up.md` (§13.4, §13.7), `README.md`, `frontend/README.md`

### Definition of done

- [x] All 2,349 catalogue templates ship, one asset per category, each with its code, title, kind, record type,
      suggested privacy and tier, identity fields and inherited groups; every one resolves to 62–72 fields.
- [x] The template checker reads `assets/templates/catalogue/`, holds every catalogue template and group field to
      §13.1, names an unknown inherited group, reports each finding at its own line inside a category file, and
      counts 2,372 templates, all atomic.
- [x] The generator refuses a catalogue whose counts, packs, fields or guidance do not add up, writing nothing, and
      `--check` names every drifted file.
- [x] The loader lists 2,372 entries, starters first, indexes the catalogue off the UI thread once, resolves any
      template with its context fields stickable, its pack's choices, auto-fills and money input, and copies a
      catalogue template into a project at version 1 with labels and options resolved.
- [x] The library shows area and category headings, a code, record type and field count on each catalogue row;
      search and the area, record type and tier filters narrow it; the preview shows the category, record type,
      privacy and tier, guidance and every field under its group with type and requiredness; adding uses the
      catalogue title.
- [x] Tests: `build_template_catalogue_test`, `check_templates_test`, `shipped_template_loader_test`,
      `shipped_template_entry_test`, `shipped_record_type_test`, `shipped_catalogue_category_test`,
      `shipped_picker_screen_test`.

### Verification

`dart run tool/check_templates.dart` reports 2,372 templates, all atomic, and
`dart run tool/build_template_catalogue.dart --check` reports every committed file current.

`dart run tool/verify.dart --fast` on this change fails the same three gates, with the same 17 failing tests and the
same findings, as on the commit before it (test presence: the 47 files already owing a test; the architecture,
naming and structure findings and goldens already reported under task 070). Nothing here adds to them; the passing
counts rise by the new tests.

In Chromium, on the release web build (`--no-web-resources-cdn`) at 1280 by 900: the library lists the starter
templates under "Starter templates", then the catalogue under area and category headings; "borehole" finds four
templates in two areas with the count in the search field; the filter sheet offers area, record type and tier; the
preview of WAT-003 shows its category, record type, privacy and tier, the four guidance lines and 68 fields from
Record admin to Specific details.

## 075 — Replace the starter templates with the catalogue

**Depends on** [074](24-product-refinements.md)

### Implement

The shipped library is the catalogue alone. The 23 starter templates of the former §13.4 (Equipment / Asset to
Generic Item) are removed, and the catalogue's assets move from `assets/templates/catalogue/` up into
`assets/templates/`, which then holds only the schema, the groups of §13.3, the catalogue index, the catalogue groups
and one file per category. The specification's §13.4–13.5 describe the library that remains.

Decisions:

- D1: the product owner chose to replace the starters outright, knowing their columns (99–212 per template) are not
  folded into the catalogue's; a project that needs one rebuilds it by extending a catalogue template (§13.6) or by
  importing a spreadsheet (§11.2).
- D2: `_groups.json` keeps the four groups of §13.3 by hand; the generated pack and context groups move to
  `_catalogue_groups.json` beside it, and the index stays `_catalogue.json`. The generator owns those two and every
  non-underscore JSON in the folder, so a run removes a template file nothing generates any more.
- D3: the template checker reads a file holding a `templates` array as a category of many templates and any other as
  one template, and reads `_catalogue_groups.json` beside `_groups.json`.
- D4: the loader drops `library()`; `entries()` and `template(key)` serve the catalogue alone, and every entry has a
  title, code, category and record type. `ShippedTemplateCategory` and the starter names and group titles in `Copy`
  go with the starters.
- D5: UNI-001 General observation is the universal fallback the success criteria name instead of Generic Item, and
  Meeting Mode (§28, task 017) builds on the Meeting record type, keeping its repeating rows in its own tables.

### Files

- `frontend/assets/templates/` (23 starter assets removed; catalogue assets moved up; `_catalogue_groups.json`)
- `frontend/tool/build_template_catalogue.dart`, `frontend/tool/check_templates.dart`, `frontend/pubspec.yaml`
- `frontend/lib/core/constants/template_assets.dart`, `frontend/lib/core/copy/copy.dart`
- `frontend/lib/features/templates/data/shipped_template_loader.dart`
- `frontend/lib/features/templates/domain/shipped_template_entry.dart`,
  `frontend/lib/features/templates/domain/shipped_template_category.dart` (removed)
- `frontend/lib/features/templates/presentation/shipped_picker_screen.dart`,
  `frontend/lib/features/templates/presentation/shipped_library_filter.dart`
- `app-write-up.md` (§13.4–13.7, §28.1, success criteria), `README.md`, `frontend/README.md`,
  `resources/template-library.md`, `dev-plan/17-meetings/017-meetings.md`

### Definition of done

- [x] `assets/templates/` holds `_schema.json`, `_groups.json`, `_catalogue.json`, `_catalogue_groups.json` and the 72
      category files, and nothing else; `catalogue/` and the 23 starter assets are gone.
- [x] The generator writes there, keeps the hand-kept files, and removes or flags a template file it did not write.
- [x] The checker counts 2,349 templates, all atomic.
- [x] The library lists, searches, filters, previews and copies the catalogue with no starter section.
- [x] Tests: `shipped_template_library_test`, `shipped_template_loader_test`, `shipped_template_entry_test`,
      `shipped_picker_screen_test`, `copy_test`, `build_template_catalogue_test`, `check_templates_test`;
      `shipped_template_category_test` removed with its source.

### Verification

`dart run tool/check_templates.dart` reports 2,349 templates, all atomic, and
`dart run tool/build_template_catalogue.dart --check` reports every generated file current.
`dart run tool/verify.dart --fast` fails the same three gates, with the same 17 failing tests and findings, as
before task 074; nothing here adds to them.

## 076 — Resolve project, capture and template feedback, and add project packages

### Implement

Close FBK0000006 and FBK0000007 from the 27 September 2026 08:43 archive, FBK0000156 to FBK0000162 from the 08:45
archive, and the operator's three requests made with them: R1, the project export writes one ZIP holding everything
another Tapture app needs; R2, another app imports that ZIP as a new project or merges it into a project built from
compatible templates after a compatibility check; R3, an optional duplicate check that a person decides. FBK0000002
to FBK0000005 in the 08:43 archive were already closed by task 070.

The executable prompt is `prompts/feedback-27092026-0845/001-resolve-project-capture-package-feedback.md`.
Decisions D1–D17 use the defaults in that prompt, (a) in every case:

- D1: `AppForm.onSubmit` returns `Future<bool>`; `true` clears the form's unsaved mark.
- D2: the open project's row has the `surfaceVariant` fill, a 4dp `primary` start bar, a `primary` title and is
  announced as selected.
- D3: the Project contexts page loses its level-name diagram; each level row carries one overflow menu.
- D4: Save raw and Save and process share one row at equal width at every width; FE-SIMP-01 reads "No other control
  is larger".
- D5: an in-house document picker mirroring `FolderPicker`; no new dependency.
- D6: native packages stream to disk under `AppConstants.bundles.nativeMaxBytes` (4,000,000,000 bytes) and are
  delivered by a streamed copy; web builds in memory under 200 MiB. Combined manifest/table/reference JSON is
  bounded to 32 MiB, with the manifest bounded to 1 MiB before encoding or decoding. A package beyond this metadata
  budget asks the exporter to choose a smaller scope; native media entries remain streamed under the native cap.
- D7: the package carries every project-owned table and file, and leaves out capture drafts, the processing queue,
  caches, export history, device settings, the operator profile and secure storage.
- D8: a read-only project page at `/projects/<id>/details`; the form is "Edit project" and returns there.
- D9: "Edit fields" moves from the record page's overflow to its Fields heading.
- D10: on the Capture tab the shell's context bar shows every level, set or not, and Manage.
- D11: the library's categories collapse, with counts, collapsed by default.
- D12: ranked on-device description search now; AI suggestions are task
  [077](24-product-refinements.md#077--suggest-shipped-templates-with-ai).
- D13: one export, the ZIP package, carrying the workbook as `records.xlsx`.
- D14: a collapsed "What to capture" row, and a caption panel while typing, dictating or recording.
- D15: a merge is blocked when a used template has no match or a filled field is missing or cannot hold its values.
- D16: the merge settles by content with §47's rules and a person; no version vectors, no undo (task 019).
- D17: the duplicate check is on by default, runs before the write, and offers Keep both or Don't import.

FBK0000158 supersedes task 070's decision (W8, from FBK0000004) that Save and process is twice as wide.

Deviations from the prompt, each smaller or safer than what it replaces:

- W13: the record page's Fields heading carries "Edit fields" as an icon button with a tooltip, not a text button;
  the text button overflowed the heading at 200 % text.
- W16: the ranking also drops the English connectives ("and", "the", "with"…) a description carries, which would
  otherwise match every template.
- W21: a merge writes the new files straight to paths no other file uses (a path already on disk moves under
  `_merged/`), each checked against the package's checksum, before the one transaction; any failure removes them.
  This replaces the `imports/<bundleId>/` staging folder and the move after the commit, which could leave rows
  pointing at files that never arrived.
- W21: the apply step is `PackageImportRepositoryImpl.merge`, beside the import it shares its file copy, row
  insert and rollback with, rather than a separate `merge_apply_impl.dart`; its tests are in
  `package_import_repository_impl_test.dart`.
- W21: a person's "Keep this device's" is stored with the conflict, so merging the same package again raises
  nothing; planning is `MergePlanner.plan(incoming, local, templateMapping, …)`, with the mapping taken from
  W20's `CompatibilityReport`.
- W22: the pair type is `PossibleDuplicate`, since Drift already names the stored row `DuplicatePair`. Only the
  scoring moved to `core/normalise/fuzzy_matcher.dart`; its reference-row ranking became a generic `rank`.
- W19: `PickedFile.isCopy` marks the picker's own copy on Android and iOS, so the flow deletes that copy and never
  the operator's file on a desktop.

### Files

- Plan: this task, [077](24-product-refinements.md#077--suggest-shipped-templates-with-ai), [078](24-product-refinements.md#078--keep-the-device-id-in-the-storage-root),
  `dev-plan/24-product-refinements/README.md`, `dev-plan/INDEX.md`, `dev-plan/08-projects/008-projects.md`,
  `dev-plan/18-export/018-export.md`, `dev-plan/19-bundles-and-merge/019-bundles-and-merge.md`,
  `frontend/.rules/06-simplicity.md`
- Native: `frontend/android/app/src/main/kotlin/com/tapture/app/MainActivity.kt`,
  `frontend/ios/Runner/AppDelegate.swift`
- App: `frontend/lib/main.dart`, `frontend/lib/app/nav_shell.dart`, `frontend/lib/app/route_paths.dart`,
  `frontend/lib/app/router.dart`
- Core: `frontend/lib/core/bundle/` (new: format, entry, manifest, tables, output, writer, zip jobs, reader,
  rejection, inspected bundle, template key), `frontend/lib/core/files/` (document picker and its platforms,
  picked document, file and bytes, archive problem, `file_validation.dart`, download service and its platforms),
  `frontend/lib/core/normalise/` (`search_text.dart`, `fuzzy_matcher.dart` moved from `features/reference`),
  `frontend/lib/core/constants/app_constants.dart`, `frontend/lib/core/copy/copy.dart`,
  `frontend/lib/core/widgets/` (`app_list_tile.dart`, `app_section_header.dart`, `app_icons.dart`,
  `forms/app_form.dart`, `responsive/responsive_pair.dart`, `fields/app_text_field.dart`,
  `fields/app_number_field.dart`, `fields/field_editor.dart`, `gallery/widget_gallery_screen.dart`)
- Capture: `capture_screen.dart`, `capture_guide_card.dart`, `capture_guide_state.dart`, `record_caption_field.dart`
- Context: `context_bar.dart`, `context_hierarchy_screen.dart`
- Exports: `export_repository.dart`, `export_repository_impl.dart`, `export_file_name.dart`
- Merge: `features/merge/domain/` (compatibility, conflicts, settlement rules, plan and planner, import port,
  presence), `features/merge/data/` (`package_files*.dart`, `package_import_repository_impl.dart`),
  `features/merge/presentation/` (import controller, phase and flow, merge controller and view, preview, conflict
  screen, duplicate pair sheet, target sheet, compatibility pill, labels), barrels
- Projects: `current_project.dart`, `project_details_screen.dart`, `project_edit_screen.dart`,
  `project_create_screen.dart`, `project_settings_screen.dart`, `project_home_screen.dart`,
  `project_list_actions.dart`, `project_list_screen.dart`, `project_list_view.dart`, `project_list_filter.dart`,
  `project_export_screen.dart`, `export_summary_view.dart`, `record_detail_screen.dart`, `record_edit_sheet.dart`,
  `record_field_draft.dart`, `record_field_input.dart`, `record_field_sheet.dart`
- Quality: `duplicate_signal.dart`, `duplicate_signals.dart`, `possible_duplicate.dart`, barrels
- Reference: `domain/domain.dart` (the matcher moved out)
- Settings: `app_lock_screen.dart`, `operator_profile_screen.dart`; Feedback: `give_feedback_screen.dart`
- Templates: `capture_guide.dart`, `shipped_search_document.dart`, `shipped_template_ranking.dart`,
  `shipped_library_expanded.dart`, `shipped_picker_screen.dart`, `template_create_screen.dart`,
  `field_add_sheet.dart`, `templates.dart`
- Tests: `test/core/bundle/`, `test/core/files/document_picker_test.dart`, `download_service_test.dart`,
  `test/core/normalise/search_text_test.dart`, the widget tests of the list tile, section header, number field,
  form and responsive pair, their gallery goldens and the catalogue golden, `test/app/nav_shell_test.dart`, capture,
  context, exports, merge (planner, compatibility, repository, preview, import flow), processing
  (`key_custody_test.dart`), projects, quality, reference and templates suites, and
  `test/support/bundle_fixture.dart`, `fakes/fake_export_repository.dart`,
  `fakes/fake_package_import_repository.dart`

### Definition of done

- [x] W1 — A project save reports "Project saved" and leaving asks nothing; a failed save keeps its guard; an
      archived project stays editable; every `AppForm` returns its outcome.
- [x] W2 — The expanded pane's border is drawn in front of its rows; the open project's row carries the current
      marker (fill, start bar, title colour, selected semantics).
- [x] W3 — Project contexts is inset by the gutter, has no diagram, no default drag handles and one overflow menu
      per level row.
- [x] W4 — `ResponsivePair.stacksOnCompact` and `matchesHeights`.
- [x] W5 — `foldSearchText`, `searchWords` and `searchStem` in `core/normalise/search_text.dart`.
- [x] W6 — `AppSectionHeader.expanded`/`onToggle` and `AppIcons.collapse`.
- [x] W7 — `DocumentPicker` on Android, iOS, Windows, macOS, Linux and web.
- [x] W8 — `DownloadService.saveStored` and `openStoredExternally`, exports folder only.
- [x] W9 — `BundleWriter` writes the package on native (streamed) and web (in memory).
- [x] W10 — `BundleReader.inspect` refuses each `BundleRejection` and accepts a written package.
- [x] W11 — A read-only project details page; the form is "Edit project" and returns to it after a save.
- [x] W12 — Capture's saves share one equal row at every width; the offline line sits under the row.
- [x] W13 — A tap on a record field edits it with a typed input; "Edit fields" sits on the Fields heading.
- [x] W14 — On Capture the context bar shows every level, set or not, plus Manage or Set up context.
- [x] W15 — The shipped library groups templates into collapsible, counted categories.
- [x] W16 — The shipped library ranks a description by relevance, offline.
- [x] W17 — Export writes the package with `records.xlsx` inside, delivered as a stored file on native.
- [x] W18 — Capture shows a guide built from the template, and the caption panel while typing or recording.
- [x] W19 — "Import a project" imports a package as a new project, all or nothing.
- [x] W20 — A compatibility report precedes every merge; an incompatible target cannot be chosen.
- [x] W21 — A package merges into a project after a preview and a person's conflict choices, all or nothing.
- [x] W22 — The merge preview checks for possible duplicates, and a person decides each pair.
- [x] Tests: every item has its own, and every new `domain/`, `data/` and screen file its mirrored test; the
      merge suite covers each planner rule and tombstone ordering, an import compared row for row and file for
      file, a failure part way leaving rows and files unchanged, a second merge of the same package planning
      nothing, and each conflict choice writing one audit entry.
- [x] Goldens regenerated with `--update-goldens`, only these (local images, git-ignored):
      - W2: `test/design_system/app_list_tile/goldens/app_list_tile_{light,dark,outdoor}.png`,
        `test/app/goldens/nav_pane_{empty,projects,header_text2}_{light,dark,outdoor}.png`,
        `test/features/projects/presentation/goldens/project_list_numbered_pinned{,_text2}_{light,dark,outdoor}.png`;
      - W3: `test/features/context/presentation/goldens/context_hierarchy{,_text2}_{light,dark,outdoor,system}.png`;
      - W4: `test/design_system/responsive_pair/goldens/responsive_pair_row_compact_{light,dark,outdoor}.png`
        (the file's other three sets were rewritten unchanged);
      - W6: `test/design_system/app_section_header/goldens/app_section_header_{light,dark,outdoor}.png`;
      - W14: `test/features/context/presentation/goldens/context_bar_{320,600,1024,320_text2}.png`;
      - W17: `test/features/projects/presentation/goldens/export_summary_{light,dark,outdoor}.png`.
- [x] `dart run tool/verify.dart --fast` fails only the gates that failed before this task, with the same
      findings: test presence (45 missing, down from 47), and the guardrail tests' architecture errors and state
      findings, naming, the structure list's missing `core/location`, and the CRLF misses of the dependency and
      catalogue checks. Format, analyzer, dependency allowlist, structure, plan and templates pass.
- [x] [077](24-product-refinements.md#077--suggest-shipped-templates-with-ai) and [078](24-product-refinements.md#078--keep-the-device-id-in-the-storage-root) are in the
      plan.

## 077 — Suggest shipped templates with AI

**Depends on** [024](23-backend.md), [076](24-product-refinements.md)

**Implementation started:** Yes

### Implement

Split from FBK0000161 by task 076's decision D12. Task 076 ranks the shipped library on the device: a typed
description finds the best-matching templates offline (`ShippedTemplateRanking`). The reporter also asked that AI
suggest the most suitable templates, in order of best match, from a description of the work.

Production uses the configured AI proxy through the existing `extractFields` operation, with choice fields over
the on-device candidate catalogue. The "Suggest with AI" action in the shipped library:

- sends only the typed description and the names, codes and record types of the top on-device matches, never
  project data (FE-SEC-03, FE-SEC-05);
- asks through the existing operation surface (a choice field over those candidates, as `TemplateAssist` does) or
  a new `/ai/rank` endpoint added to §74.2 in the same change;
- respects the offline switch, the project's AI setting and the daily budget, and is hidden when AI is unavailable;
- shows the model's order as a proposal the person can ignore (AI proposes; a person approves).

### Files

- `frontend/lib/features/templates/presentation/shipped_picker_screen.dart`
- `frontend/lib/core/ai/ai_service.dart`

### Definition of done

Verification 2026-09-30: candidate ranking/payload domain tests, 15 shipped-picker tests, the complete proposal/reordering widget case and four budget/reservation controller cases passed. The model order is labelled as a suggestion and never selects a template automatically. Availability is rechecked after durable budget reservation, so switching offline during that wait prevents egress and clears the busy state. Payloads contain only the entered description and bounded catalogue text, without project records, context or images.

- [x] With AI available, a description returns the candidates in the model's order, marked as a suggestion.
- [x] Offline, with AI off or unavailable, the action is hidden and on-device ranking still works.
- [x] Nothing but the description and catalogue text leaves the device.
- [x] Tests: a fake `AiService` ranking, the hidden states, and the egress payload.

## 078 — Keep the device id in the storage root

**Depends on** [076](24-product-refinements.md)

### Implement

Found while writing task 076's project packages. The device id (specification §10.2: created at first launch,
never reused) is kept in the OS temp folder on native platforms
(`frontend/lib/core/device/device_io.dart`, `${Directory.systemTemp.path}/tapture-device/device.id`), which the OS
or a cleaner may empty, and only in memory on web, so every page load gets a new id. A project package names the
device it came from and a merge records it, so an id that changes makes one device look like several.

Keep the id where it survives: in the database's `device_profile.deviceId` (already a column), read once at start,
with the temp file read only to migrate an existing id into it. On web the database lives in IndexedDB, so the id
survives a reload there too.

### Files

- `frontend/lib/core/device/device_identity.dart`
- `frontend/lib/core/device/device_io.dart`
- `frontend/lib/core/db/tables/device_profile.dart`
- `frontend/lib/main.dart`

### Definition of done

- [x] The device id survives clearing the OS temp folder and, on web, a page reload.
- [x] An id already in the temp file is kept, not replaced, on the first launch after the change.
- [x] Tests: identity resolution from the profile, from the legacy file, and a fresh install.

## 079 — Show a mobile More menu in the bottom navigation

**Depends on** [006](06-app-shell.md), [032](24-product-refinements.md), [060](24-product-refinements.md)

### Implement

Replace the compact bottom navigation's Settings action with a labelled, horizontal three-dot **More** control
that opens an anchored menu above the bar (§83.1). Keep Projects, Capture and Records, and use the fourth branch
for existing secondary destinations. Each menu row has its established icon and label: Templates, Unprocessed,
Recycle bin and Settings. Opening or dismissing the menu must not navigate or reset the current branch.

Retain the medium/expanded Settings rail. Expose Documentation later in task 083 when it has a working route;
do not add a dead Documentation or export placeholder to this change.

### Files

- `frontend/lib/app/nav_shell.dart`, `frontend/lib/app/shell_destination.dart`
- `frontend/lib/core/widgets/app_overflow_menu.dart`, `frontend/lib/core/copy/copy.dart`
- `frontend/.rules/06-simplicity.md` and enforcing navigation tests
- `frontend/test/app/nav_more_menu_test.dart`, `frontend/test/app/nav_shell_test.dart`
- Existing destination goldens and shared overflow widget tests

### Constraints

- Reuse the shared overflow menu and destination metadata. Compact label/icon changes must not rename the desktop
  Settings control. Exactly four mobile controls; no fifth tab.
- Minimal corner radius from `Radii` (never zero), shared spacing/theme tokens, 48 dp targets, icons plus text, safe-area scrolling and accessible
  labels. Preserve selected branch, current project, draft input and search across dismissal and resizing.
- Selecting an entry closes the menu and uses the canonical route; reopening adds no duplicate route.

### Definition of done

- [x] Compact More opens a menu with the minimal corner radius and four working icon-labelled secondary destinations.
- [x] Each menu choice navigates to its existing destination and secondary screens select the fourth branch.
- [x] Dismissal preserves the active primary branch, project and search state; an open popup remains usable across
      a width change, and the existing desktop Settings rail is retained.
- [x] Focused widget/golden tests cover all four routes, icon/copy consistency, shared overflow behaviour, narrow
      phone layout at 200 percent text and light/dark/outdoor themes: 21 passed.
- [ ] The standard Flutter gate completes successfully, including analysis and `dart run tool/verify.dart --fast`.

### Verification status

Implemented and focused tests passed on 2026-09-28; targeted analysis of the six changed source/test files reported
no issues. The broader navigation/copy run reported 67 passes and one failure in the expanded project-pane no-match
test: its assertion expects **Create a project**, while the current empty pane supplies no create action. The
project-pane implementation was not changed by this task, but a separate baseline run has not established the
failure's age.

The full fast gate was attempted and is not green: plan and template checks passed; formatting, full analysis,
dependency allowlist, structure, strict test presence and guardrails reported failures. The pre-unit diagnostics
did not name this task's edited source paths: full analysis reported 14 issues elsewhere, formatting identified
40 other files, the allowlist lacked `integration_test`, and structure rejected existing `core/assets` and
`core/backend`. Guardrails reported 372 passes and 20 failures. The long unit/widget stage was stopped after about
10 minutes 50 seconds, at 3,163 passes and 9 failures, so that suite is incomplete. Its failures included the pane
assertion and processing tests. No unrelated files were changed to silence these results.

This task and its index entry remain open until the standard gate is satisfied; the 21 passing focused tests and
clean targeted analysis verify the menu change without claiming that the whole repository passes.

## 093 — Audit implementation and efficiency against the full plan

**Implementation started:** Yes

### Implement

Review the repository against all existing implementation tasks except steps 25 and 26, repair concrete gaps,
and improve durability, bounded work and shared UI reuse. Review the pre-existing staged/unstaged changes before
including them in incremental GitHub commits. Update original task acceptance records with executable evidence;
keep real-device, deployment and whole-product verification open when it has not run.

Inspect step 27 and remove its contents only if its implementation and acceptance are already complete. Its
unchecked whole-product requirements and unfinished excluded prerequisites currently make that condition false.
Retain the final hardening folder and its stable task 023 reference.

### Files

- Original task checklists in `dev-plan/01-*` through `24-*`; `27-hardening/27-hardening.md`
- `frontend/lib/`, corresponding tests and intentional synthetic golden baselines
- `frontend/.gitignore`, frontend guardrails and generated tracker/index/folder summaries
- `backend/src/`, repositories, migrations, OpenAPI contract, deployment and tests
- `run-tools/common.py`, web/Android entry points and script regression tests

### Definition of done

- [x] Audit work preserves and reviews existing local changes; the user's instruction includes reviewed pre-existing changes.
- [x] Steps 25 and 26 receive no feature implementation; the incomplete hardening plan is retained under the conditional deletion request.
- [ ] Every included original task satisfies its complete Definition of done; unverified hardware, deployment and performance criteria remain open.
- [ ] Concrete code fixes pass their regression tests and the standard frontend/backend gates on the final tree.
- [ ] Synthetic UI baselines are reviewed and committed, with failure dumps and captured evidence excluded.
- [ ] Acceptance source changes and automatically synchronized tracker views accompany the implementation commits.
- [ ] Reviewed changes are committed incrementally and pushed to GitHub.

### Audit evidence — 2026-09-30

The audit covers shared foundation/design/database/storage/navigation, every application feature and the backend.
Original checklists retain distinct requirements and stable task references. Concrete repairs include worker
exit/cancellation, authenticated database recovery, project-relative integrity checks, safe export publication,
scoped/password bundles, causal merge/conflict/history/undo, secure cloud checkpoints and native account/folder ports.
Only generated summary updates touch excluded steps 25 and 26. Step 27 remains because its acceptance is incomplete.

Historical focused evidence: foundation/accessibility 16 passes; encryption 6; integrity/writers 10; cache 8;
native storage/archive 21. A 400 MiB archive fixture completed in 18,627 ms with about 31 MiB additional sampled
process RSS against its 120 MiB ceiling. These host measurements do not certify physical-device performance.

### Frontend checkpoint — 2026-10-01

The initial reviewed UI checkpoint passed 648 collection layout/accessibility cells, six Projects title-bar menu
cases and 47 screenshot suites (259 cases). Subsequent changes expand coverage to all 35 primary screen fixtures,
add inherited English/pseudo catalogues and preserve semantic errors through durable state while keeping English
text for audit and older clients. The affected domain libraries compile and execute on the plain Dart VM.
These changes require the final current-tree analyzer, regressions, layout matrices and browser run before acceptance.

Actual browser IndexedDB integration previously passed three named cases: durable evidence reopening, preservation
after an interrupted write and bounded thumbnail recovery through a new service. Production processing,
export/download, thumbnail rendering and asynchronous password/cipher browser fixtures are now added; their final
Chrome execution remains pending. Native SDK consent, removable-folder grants, biometrics and OS incoming transports
require actual platform checks. Android Kotlin/resources/manifest/link compilation passed all 315 targets again
after the final share-intent and AppCompat theme changes. The freshly merged Android manifest passed the real-output
permission review; iOS aggregate privacy verification requires Xcode.

### Durability and bounded-work checkpoint — 2026-10-01

Photo inspection retains current/neighbor originals with serial reads. Project/template rows build lazily.
Native attachment imports stream through the atomic writer; metadata and browser packages have explicit ceilings.
Queue summaries omit historical failure arrays, and one indexed 50-row keyset failure page stays live with retries.
Relay preflights the deployment's 20,000,000-byte ciphertext limit before a whole native read and encrypts on a worker.
Native package operations use cancellable workers and parent-owned scratch; compatible browser encryption yields
between aligned AES chunks and authenticates asynchronously. Focused final regressions remain pending.

The indexed duplicate scan preserved the frozen prior pairs/scores/priority across 100 randomized pure-Dart datasets.
The 100-incoming/10,000-local identity fixture measured 755,195 microseconds for 1,000,000 all-pairs comparisons versus
73,963 microseconds indexed, retaining 100 matches. The bounded asynchronous logger reduced a 1,000-entry desktop
caller's time from 45,430,771 to 32,331 microseconds; final flush took 27,132 microseconds. Logging/thumbnail services
passed 20 cases, opaque relay pagination eight and authenticated database recovery eight before the final locale edits.

Ten offline host fault cases passed, including an actual SQLite lock and killed SQLite child. The combined earlier
foundation run passed 318 cases and exposed eleven generated/test-fixture failures; those were repaired with further
regressions. Strict retained-RSS measurements remain open: resource counters returning to zero do not prove RSS
returned to baseline, and the same measured capture/export/merge scenarios must be rerun after streaming changes.
Physical cold-start, frame, battery, camera, recording, permission and provider budgets remain open.

Current database, permission, verification-runner, incoming-service and duplicate regressions passed 302 cases;
thumbnail regressions passed 19 and the real bootstrap error-handler fixture passed separately. Migration coverage
includes every released version through schema 31 and retains prior error text alongside semantic descriptors.
The cloud/security batch passed 243 cases and exposed eleven failures. Cancellation must unwind native ZIP handles
before scratch removal, password derivation must remain strong and efficient, and isolated locale/biometric fixtures
must use their proper boundaries. Those repairs and the final full gates are still in progress.

Backend checkpoints `202cd1d5` and `bd855380` are committed, pushed and verified against the remote branch. Scoped
collections use bounded keyset pagination/composite indexes, and limiter buckets preserve active limits with bounded
retention. Five additional real-PostgreSQL tests cover identity, scoped/cross-organisation membership, actual CLI
export/destroy, transactional pool draining and exact-expiry relay cleanup. Final backend verify/build pass: 136
successful tests, nine explicit PostgreSQL/Docker skips, zero audit vulnerabilities. Skips do not satisfy real-database,
live deployment or protected-CI acceptance. Frontend commits and final gate evidence follow after verification.

### Requested run-script checkpoint — 2026-10-01

The exact web entry point compiled and served the application at localhost:5173. The initial Chrome load exposed
a view-focus geometry assertion. A public binding coordinator now delays only the initial focus transfer until
its target has layout; seven engine-boundary regressions pass. The exact script retry compiled in 109.6 seconds.
Fresh Chrome checks rendered Projects, its menu, Settings and Language with no startup assertion or console error.
The Android entry point initially could not connect to its Gradle daemon because the shortened Windows socket
directory only reached the launcher. Commit `f8ab255d`, pushed and remotely verified, passes the setting to the
daemon through `JAVA_TOOL_OPTIONS` while preserving caller options; three Python regressions pass. The exact
Android entry point then completed `assembleProdRelease` and copied a fresh 189,525,581-byte universal release
APK to `run-tools/dist/android/app-release.apk`. No ADB device is connected, so native installation/launch remains
unverified. Subsequent source repairs require a final build of the final tree before completion is claimed.

### Current efficiency checkpoint — 2026-10-01

The coherent streaming, cancellation, paging, lazy photo-grid/viewer and feedback-archive batch passed 213 of 213
tests. A refused atomic writer now cancels an already-open native source even before accepting its first chunk.
The actual record screen builds only visible photo tiles; 240 continuous host drag samples measured a 66,099
microsecond p90 and 320,838 microsecond worst frame within the unchanged host gate. These are host measurements,
not physical-device frame acceptance.

Capture 200, export 5,000 and merge 2,000-photo workloads passed their three functional/resource tests. The exact
strict command `dart run tool/profile_memory.dart build/memory-profile.json 134217728 0` failed its three retained
RSS checks. Additional peaks were 97.57, 37.00 and 123.93 MiB; retained RSS was 39.50, 21.95 and 69.95 MiB respectively.
Databases, subscriptions, bundles, containers and isolates returned to zero. No baseline allowance, forced garbage
collection or operating-system working-set manipulation was introduced; memory baseline acceptance remains open.

The follow-up audit found two concrete data-path gaps: bootstrap did not bind the real record repository, and
field deletion used an empty count provider without retiring stored values. Production bindings, fresh scoped
count queries, transactional value retirement and historical retired-value exports now have source repairs and
real database/UI regressions; their current-tree verification is pending. Desktop external-browser PKCE is tracked
in [098](21-cloud-upload.md#098--connect-configured-desktop-cloud-accounts-through-external-browser-pkce), with registered provider consent still unverified.

### Incremental publishing checkpoint — 2026-10-01

Plan/evidence commit `e4ef641e` is pushed and its hash matches the remote branch. The publication review found no
captured evidence, credentials or oversized artifacts in the pending changes. Source, generated catalogues,
migrations, native integrations and their regressions remain a coupled application checkpoint.

Current backend verification passes with 136 successful tests, nine explicit database/Docker skips and zero audit
vulnerabilities. The real native PDFium capture batch passes 22 tests without skips. The initial golden run passed
251 cases and found five failures; visual review confirmed six intentional branding/gallery image updates, while
an explicit thumbnail readiness condition preserved all three existing missing-photo baselines. All seven affected
golden cases pass on rerun.

Preparation exposed formatting/analyzer issues and ten guardrail failures. Repairs preserve the architecture rules,
generated-source inclusion and literal-duration detection, and distinguish runtime serialization from style tokens.
Focused tooling checks pass 29 cases; feature architecture and affected regressions pass. Disposable-file cleanup
now proves fresh ownership and exclusive creation before deletion. The focused cleanup batch passes 62 durability,
10 safety and eight related-service tests, including preservation of a concurrently created cipher target.
The publication hook then found three redundant test imports, two missing queue type tests and a transitive
Flutter dependency in the plain-Dart domain probe. Import repairs and queue identity/cursor tests pass 45 focused
cases with a clean analyzer; all owed source files now have tests. Feedback workbook code imports its existing
pure XLSX types directly, and the unchanged 19-library headless probe plus 11 affected regressions pass.
An independent review also exposed marker-path aliases and published temporary roots escaping the cleanup proof;
those negative cases require stronger ownership checks before the application checkpoint can be committed.
Final aggregate verification and application publication remain pending; unverified acceptance stays open.

## 095 — Generate platform branding reproducibly from vector sources

**Depends on** [002](02-foundation.md), [003](03-design-system.md), [054](24-product-refinements.md)

**Implementation started:** Yes

### Implement

Generate platform branding from one canonical outlined mark and the existing outlined wordmark. Render every raster
directly from vector geometry at its final dimensions; never resize an existing PNG into another density. Resolve
light/dark/outdoor colors through the actual `AppColors` semantic palette. Generate typed asset paths, complete
source/output hashes, native launch resources, icon catalogs and unrestricted web orientation.

The isolated development renderer is **@resvg/resvg-js 2.6.2**, pinned in the package and lockfile and reviewed under
**MPL-2.0** (the installed package metadata and bundled LICENSE agree). Its
[primary project and API](https://github.com/thx/resvg-js) describe direct SVG rendering. The dependency and license
allowlist lives beside this tool and is validated before rendering (FE-FLOW-06). This replaces independently
maintained raster exports without a reproducible generation command; no Flutter runtime package is added.

### Files

- `frontend/tool/branding/{generate.mjs,generate.test.mjs,package.json,package-lock.json,dependencies.json,README.md}`
- `frontend/tool/branding/source/{mark.svg,wordmark.svg}`
- `frontend/lib/core/assets/branding_assets.dart`
- `frontend/assets/branding/` artwork and generation manifest
- Android launcher/adaptive/monochrome densities, launch backgrounds and light/night/Android-12 styles under `res/`
- iOS/macOS icon catalogs; iOS light/dark launch images, named launch color and `LaunchScreen.storyboard`
- Windows ICO; web favicon, standard/maskable/apple-touch icons and manifest
- `frontend/test/core/assets/branding_assets_test.dart`

### Contract

From `frontend/tool/branding/`, `npm ci` installs the pinned renderer; `npm run generate` refreshes resources;
`npm run check` compares every expected output and source hash without writing; `npm test` exercises reproducibility
and negative fixtures. Check reports all missing/stale paths and exits nonzero. The JSON manifest records exact
renderer version, palette roles, input/output SHA-256, byte counts and PNG dimensions. `BrandingAssets` exposes named
runtime artwork and a typed inventory of every generated path.

Native launch follows OS light/dark appearance and uses the matching page background. Outdoor artwork is exposed to
Flutter; an OS launch screen cannot read the app's persisted outdoor setting. No AppDelegate or MainActivity code
is generated. Physical OS mask/launch behavior and recognition remain hardening review evidence, not inferred from
asset dimensions or existence.
Android launch and normal themes use the biometric SDK's required AppCompat DayNight parent in all four resource
variants; light/night palette qualifiers and Android 12 splash artwork remain generated from the same sources.

### Definition of done

- [x] Canonical mark and wordmark geometry render each target size directly, without font installation or raster resizing.
- [x] The exact development renderer version/license is allowlisted and checked against package metadata and lockfile.
- [x] Generated artwork, platform resources, typed inventory and source/output metadata pass a nonmutating cache check.
- [x] AppColors light/dark/outdoor roles match generated metadata and native launch backgrounds; web permits either orientation.
- [x] Tests: Node fixtures prove reproducibility and reject missing densities/assets, source/palette changes and unpinned renderer declarations; Dart validates typed inventory, source/output hashes and semantic colors.
- [ ] Physical review: reference devices show recognizable 48-pixel marks, correct OS masking and matching native/Flutter launch backgrounds in supported appearance modes.

### Verification — 2026-10-01

The final generator emitted 95 resources and `npm run check` reports zero missing/stale outputs without writing.
All five Node fixtures pass, including source/palette invalidation, missing densities, metadata/native appearance,
and dependency/license allowlist failures. Both Dart inventory/hash/palette tests pass in the final focused batch;
typed paths and assertions also analyzed cleanly. The installation audit initially reported zero vulnerabilities;
a later audit could not reach the registry because DNS resolution failed. Physical review remains open.
The AppCompat integration refresh regenerated all 95 resources, passed the nonmutating cache check and all five
Node fixtures, including explicit parent/background/Android 12 assertions. The final Dart/native reruns remain pending.

### Line endings — 2026-10-03

On a `core.autocrlf=true` checkout the cache check reported 26 stale resources and the Dart hash test failed: the
manifest held hashes of CRLF bytes that git had normalized away on commit. The root `.gitattributes` now keeps the
generator's inputs and text outputs LF on every checkout, and the regenerated manifest records LF hashes for ten
SVG outputs and three inputs; no other resource changed. `node tool/branding/generate.mjs --check` reports zero
violations and `test/core/assets/branding_assets_test.dart` passes.
