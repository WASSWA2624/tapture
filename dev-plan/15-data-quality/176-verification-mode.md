# 176 — Verification mode and register prefill

**Phase** 15 · Data quality  |  **Depends on** [086](../08-projects/086-project-edit.md), [111](../10-reference-data/111-lookup-exact-match.md), [134](../12-capture/134-identifier-lookup.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A project or session switched into confirming existing data rather than creating it: capture starts from an
identifier, the record arrives prefilled from its reference row, and the register's values are kept apart from what
the field worker finds so 331 can compare the two.

## Files

- `frontend/lib/features/quality/presentation/verification_mode_toggle.dart` (new)
- `frontend/lib/features/quality/domain/verification_prefill.dart` (new)

## Steps

1. The toggle sits in project settings (149) and in the session; with it on, capture opens the identifier lookup of
   248 before the form.
2. Prefill fills every mapped field from the matched reference row through 199 and marks the record on-register.
3. Keep the register values in their own slot on the record — as-recorded — so editing the as-found values never
   overwrites them.
4. An identifier with no matching row still creates a record, flagged not-in-register; the lookup never blocks capture.

## Definition of done

- [ ] The mode is visible in the status line so no one forgets it is on.
- [ ] A prefilled field shows that it came from the register, and editing it leaves the register value intact.
- [ ] A not-found identifier creates a record flagged not-in-register.
- [ ] Tests: widget test of `verification_mode_toggle.dart` on, off and in its failure state; unit tests of
      `verification_prefill.dart` covering a matched row, an unmatched identifier and the preserved register values,
      with no Flutter binding.
