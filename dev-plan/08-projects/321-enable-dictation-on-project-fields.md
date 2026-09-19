# 321 — Enable dictation on project fields

**Phase** 08 · Projects  |  **Depends on** [084](084-project-create.md), [086](086-project-edit.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Every free-text field on New project and Project details offers the catalogue microphone.
Name, description and organisation accept speech to text. Fields that already opt out for a
stated reason stay as they are.

## Files

- `frontend/lib/features/projects/presentation/project_create_screen.dart`
- `frontend/lib/features/projects/presentation/project_edit_screen.dart`
- `frontend/test/features/projects/presentation/project_create_screen_test.dart`
- `frontend/test/features/projects/presentation/project_edit_screen_test.dart`
- `frontend/test/features/projects/presentation/project_delete_action_test.dart`

## Constraints

- Reuse catalogue dictation; add no screen-level speech code (FE-CONS-01).
- The speech language comes from the voice-language setting that `DictationScope` already
  reads (FE-L10N-08).
- Offline by choice keeps recognition on the device (FE-SEC-04).
- Dictated words land at the caret, and nothing is submitted (FE-SIMP-09).
- The microphone is 48 dp and labelled (FE-A11Y-01, FE-A11Y-02).
- Tests use `SttService` stand-ins, never the plugin (FE-TEST-03).
- Do not change `DictationScope`, `AppTextField`, the voice language setting, offline
  behaviour, or the recorded opt-outs (initials, email, phone, the typed-name delete
  confirmation, and the numeric confidence fields).

## Definition of done

- [x] New project and Project details show a microphone on Name, Description and
      Organisation, and dictation fills the field.
- [x] With Stay offline on, dictation uses on-device recognition or shows the existing
      plain message.
- [x] Excluded fields still show no microphone.
- [x] Tests: the three fields offer a microphone; dictating into Name inserts the words
      and does not submit; the Delete confirmation's typed-name field has no microphone;
      no overflow at 360 dp and 200 percent text.
