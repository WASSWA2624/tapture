# 131 — Voice input: permission, dictation and transcript

**Phase** 12 · Capture  |  **Depends on** [026](../02-foundation/026-permissions-service.md), [029](../02-foundation/029-ai-service-interface.md), [035](../03-design-system/035-app-text-field.md), [055](../04-data-layer/055-photos-table.md), [121](121-capture-screen.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Speaking instead of typing, end to end: the microphone asked for only on the first mic tap, on-device dictation behind
one interface, the mic affordance attached to any long-text field, and the spoken words stored verbatim where
refinement can never overwrite them.

## Files

- `frontend/lib/features/capture/presentation/mic_permission_gate.dart` (new)
- `frontend/lib/core/ai/stt_service.dart` (new)
- `frontend/lib/features/capture/presentation/voice_input_button.dart` (new)
- `frontend/lib/features/capture/domain/transcript_store.dart` (new)

## Contract

```dart
abstract interface class SttService {
  Stream<SttResult> listen({required String languageTag});
  Future<void> cancel();
}

class SttResult {
  const SttResult({required this.text, required this.isFinal, required this.languageTag, this.confidence});
  final String text;
  final bool isFinal;
  final String languageTag; // the language actually used, not the one requested
  final double? confidence;
}
```

## Steps

1. Ask for the microphone at the first mic tap, never at launch; refusal leaves typing fully available and asks again
   only on a later explicit tap.
2. Recognise on device in the configured language; fall back to the online recogniser only when configured and online,
   otherwise report unavailable rather than failing silently.
3. Show listening state and live partial text; stop on tap or silence; the final text lands in the field as editable
   text and is never auto-submitted.
4. Store transcript, language and confidence alongside the caption row (101).

## Constraints

- Speech is reached only through the `core/` service, which has a fake; networking stays inside `core/ai/` (FE-STR-11, FE-SEC-03).
- The voice language comes from the setting, not the device locale (FE-L10N-08).
- The raw transcript is written once; refinement writes a separate column (FE-SEC-08).

## Definition of done

- [ ] Dictation works with the network off wherever the platform supports the language.
- [ ] Refusing the microphone leaves typing fully available and blocks nothing else.
- [ ] Later refinement writes a separate column and leaves the raw transcript row unchanged.
- [ ] Tests: unit tests of `stt_service.dart` with a fake recogniser covering partial, final, cancel, unsupported language and offline-unavailable; widget tests of `mic_permission_gate.dart` and `voice_input_button.dart` including the denied and listening states; unit test that refining does not alter the raw transcript row.

## Out of scope

- Refining, summarising or extracting fields from the transcript, which belongs to phase 13 · Processing.
