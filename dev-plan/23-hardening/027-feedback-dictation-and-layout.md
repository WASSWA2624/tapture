# 027 — Feedback screens: compact layout, dictation and reopen safety

**Phase** 23 · Hardening  |  **Depends on** [012](../12-capture/012-capture.md), [026](026-in-app-feedback.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

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

### Second pass: a persistent feedback workspace

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

## Files

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

## Constraints

- `speech_to_text` is reached only through `SttService`, which has a fake (FE-STR-11, FE-FLOW-06).
- The microphone is asked for on the first mic tap, never at launch; refusal leaves typing untouched.
- Stored `improvement` entries still read, filter and export; the form no longer offers the type.
- Presentation does not call `setState` (FE-STATE-01). Tokens only (FE-THEME-01).

## Definition of done

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
