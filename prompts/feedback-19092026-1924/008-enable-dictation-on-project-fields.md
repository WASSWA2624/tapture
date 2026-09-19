# 008 — Enable dictation on project fields

**Feedback:** FBK0000013 · **Type:** Gap · **Priority:** P5 · **Effort:** S · **Depends on:** —

## Goal
Every free-text field offers the microphone for speech to text, including project name, description and
organisation on New project and Project details. Fields excluded for a stated reason stay as they are.
This holds at every width, in light, dark and outdoor, and at 200 percent text.

## Evidence
- FBK0000013 (in part): the reporter asks for speech to text on the inputs, applied to all of them.
  `screenshots/FBK0000013.png` shows New project with Name, Description and Organisation and no
  microphone on any of them. Android, mobile, compact, portrait, system dark, route `/projects/new`.
- Dictation is already app-wide: `DictationScope` wraps the navigator (`frontend/lib/app/app.dart:56`),
  and `AppTextField` shows the microphone on free-text fields under it (`app_text_field.dart:24-26`).
- Root cause: the six project text fields opt out with `dictation: false` and no stated reason:
  - `frontend/lib/features/projects/presentation/project_create_screen.dart:72`, `:80` and `:87`;
  - `project_edit_screen.dart:87`, `:95` and `:102`.
- Opt-outs with a recorded reason, which stay:
  - initials (`operator_profile_screen.dart:105`);
  - email and phone (task 292);
  - the typed-name delete confirmation, which task 087 requires "typed by hand" (`app_dialog.dart:307`);
  - the numeric confidence fields (`project_settings_screen.dart:150` and `:160`).

## Scope
- Change:
  - `project_create_screen.dart` and `project_edit_screen.dart`: delete the six `dictation: false`
    arguments.
  - `frontend/test/features/projects/presentation/project_create_screen_test.dart` and
    `project_edit_screen_test.dart`: the tests below.
- Do not change: `DictationScope`, `AppTextField`, the voice language setting, the offline behaviour, or
  the opt-outs listed above.

## Rules
- FE-CONS-01: reuse the catalogue dictation; add no screen-level speech code.
- FE-L10N-08: the speech language comes from the voice language setting that `DictationScope` already
  reads.
- FE-SEC-04: offline by choice keeps recognition on the device (`onDeviceOnly: offline` in `app.dart`).
- FE-SIMP-09: dictated words land at the caret, and nothing is submitted.
- FE-A11Y-01 and FE-A11Y-02: the microphone is 48 dp and labelled.
- FE-TEST-03: use `SttService` stand-ins, as `app_text_field_dictation_test.dart` does; never the plugin.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 08-projects enable-dictation-on-project-fields "Enable dictation on project fields"`
   (FE-FLOW-08).
2. Remove the six opt-outs.
3. Tests, under a `DictationScope` with a fake service:
   - New project and Project details show a microphone on Name, Description and Organisation;
   - dictating into Name inserts the words and does not submit the form;
   - the Delete confirmation's typed-name field still has no microphone;
   - no overflow at 360 dp and 200 percent text.

## Human review
⛔ Stop before step 2 and ask:
- The reporter asks for "all inputs". Keep the recorded exclusions (initials, email, phone, the typed
  delete name, and numbers)? Recommend yes; each has a stated reason, and the typed name must be typed by
  hand (task 087).
Proceed only with an explicit answer. If the answer is "proceed", keep them.

## Acceptance criteria
- [ ] New project and Project details show a microphone on Name, Description and Organisation, and
      dictation fills the field.
- [ ] With Stay offline on, dictation uses on-device recognition or shows the existing plain message.
- [ ] Excluded fields still show no microphone.
- [ ] It looks right at every width and theme, and at 200 percent text.
- [ ] FBK0000013's dictation part is resolved. The marks are 006.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- On an Android phone: New project → tap the Name microphone → speak; the words appear.
- No goldens change.
