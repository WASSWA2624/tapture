# 183 — Mark a field verified

**Phase** 16 · Review  |  **Depends on** [097](../09-templates/097-field-editor-inline.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

An explicit verification action, separate from editing: a person states that a value is right, and processing may not
overwrite it afterwards.

## Files

- `frontend/lib/features/review/presentation/verify_action.dart` (new)

## Steps

1. Verify sits on the field row beside the inline editor of 170 and records who verified the value and when.
2. One action verifies every confident field of the record at once.
3. A verified value is skipped by proposal application (278) and offered as a diff by re-analysis (343) instead.

## Definition of done

- [ ] Verifying is distinct from editing: a value can be verified without being changed.
- [ ] A verified value survives reprocessing untouched, and a later proposal for it is offered, never applied.
- [ ] Tests: widget test of `verify_action.dart` covering single and bulk verification, the recorded verifier, and its
      empty and failure states.
