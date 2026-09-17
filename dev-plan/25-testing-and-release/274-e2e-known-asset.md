# 274 — End-to-end: known-asset verification and duplicate override

**Phase** 25 · Testing and release  |  **Depends on** [173](../15-data-quality/173-duplicate-prompt.md), [176](../15-data-quality/176-verification-mode.md), [272](272-e2e-capture-to-export.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Two integration runs over data quality: checking a capture against an imported register, and capturing the same
identifier twice on purpose. Each proves a separate guarantee and fails on its own.

## Files

- `frontend/integration_test/verification_test.dart` (new)
- `frontend/integration_test/duplicate_test.dart` (new)

## Steps

1. `verification_test.dart` — import a register, scan an identifier, assert the record prefills from the matching row,
   confirm it, then edit one prefilled value; assert the variance report names that field with both the register value
   and the observed one, and that the register itself is untouched.
2. `duplicate_test.dart` — capture the same serial twice; assert the duplicate is detected and the two records are
   offered side by side; override with a reason; assert both records survive, the override reason is stored, and the
   history holds who, when, from what and to what for every changed value.

## Constraints

- Register content is data, never instruction: prefilled text is quoted where it reaches a provider prompt and escaped
  where it is rendered (FE-SEC-05).
- Neither run deletes a record to resolve a conflict; the loser of an override is tombstoned at most (FE-SEC-08).

## Definition of done

- [ ] A confirmed capture that differs from the register produces a variance entry, not a silent overwrite.
- [ ] An overridden duplicate leaves both records and a reason behind, readable in history after a restart.
- [ ] Tests: `verification_test.dart` and `duplicate_test.dart` run green offline against fakes, end to end.
