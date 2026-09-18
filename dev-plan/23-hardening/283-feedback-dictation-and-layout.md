# 283 — Feedback screens: compact layout, dictation and reopen safety

**Phase** 23 · Hardening  |  **Depends on** [282](282-in-app-feedback.md), [131](../12-capture/131-voice-permission.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

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

## Files

- `frontend/lib/core/ai/stt_service.dart` (new, 131 contract), `frontend/lib/core/normalise/spoken_text.dart` (new)
- `frontend/lib/core/widgets/fields/dictation_scope.dart`, `dictation_session.dart` (new)
- `frontend/lib/core/widgets/fields/app_text_field.dart`, `app_radio_group.dart`, `app_switch_tile.dart`
- `frontend/lib/core/widgets/app_icon_button.dart`, `app_page.dart`, `forms/app_form.dart`
- `frontend/lib/app/app.dart`, `frontend/lib/app/widgets/global_error_page.dart`, `frontend/lib/main.dart`
- `frontend/lib/features/feedback/` (presentation, `FeedbackCategory.offered`)
- `frontend/pubspec.yaml`, `frontend/tool/allowlist.yaml` (`speech_to_text`), platform microphone and speech usage strings

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
- [x] Tests: `SpokenText` unit tests, `DictationSession` with a fake recogniser (partial, final, stop, error,
      dispose), `AppTextField` dictation, the new radio, switch, icon-button and page modes, feedback screen and
      reopen tests, and the recovery row.
