# 152 — Template detection: local signals, model assist, operator's choice

**Phase** 13 · Processing  |  **Depends on** [029](../02-foundation/029-ai-service-interface.md), [041](../03-design-system/041-app-dialog-service.md), [104](../09-templates/104-template-detection-profile.md), [146](146-identifier-extraction.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A template chosen from local signals first — OCR keywords, identifier patterns and reference matches scored against
the detection profile with no network — then by one cheap model call when the local score is inconclusive, and only
then by asking the operator.

## Files

- `frontend/lib/features/processing/domain/template_detection.dart` (new)
- `frontend/lib/features/processing/domain/template_detection_ai.dart` (new)
- `frontend/lib/features/processing/presentation/template_choice_sheet.dart` (new)

## Steps

1. Implement the selection order from the specification, stopping as soon as a rule decides; a pinned template
   short-circuits the whole ladder.
2. Call the model only when local scoring is inconclusive, and only for the shortlist local scoring produced.
3. The sheet offers two or three large buttons plus the option to pin the choice to the current context level, so the
   question is asked once per room rather than once per item.

## Constraints

- Detection carries the on-device-first rule of this phase: a model call happens only after local scoring fails to
  decide.
- The sheet is built on `AppBottomSheet` from task 041 (FE-CONS-01, FE-SIMP-07).

## Definition of done

- [ ] A pinned template short-circuits detection entirely.
- [ ] No detection call is made when local scoring is confident.
- [ ] The question is asked once per room, not once per item.
- [ ] Tests: unit tests over the full decision table and the inconclusive path, with no Flutter binding; widget test
      of `template_choice_sheet.dart`, including its empty and failure states.
