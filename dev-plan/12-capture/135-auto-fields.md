# 135 — Automatic values: clock, sequence and GPS

**Phase** 12 · Capture  |  **Depends on** [023](../02-foundation/023-clock-service.md), [026](../02-foundation/026-permissions-service.md), [052](../04-data-layer/052-projects-table.md), [078](../07-account-and-settings/078-settings-store.md), [120](120-capture-session-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Everything a record gets without being asked: date, time, captured-at, operator and device; a per-project record number
allocated without gaps or collisions; and coordinates with accuracy, but only where the project enables GPS.

## Files

- `frontend/lib/features/capture/domain/auto_fields.dart` (new)
- `frontend/lib/features/capture/domain/record_number.dart` (new)
- `frontend/lib/features/capture/domain/gps_capture.dart` (new)

## Steps

1. Apply on first save; mark every value with source `AUTO` and the auto affordance, honouring each template field's
   `autoFill` setting and the project's date format.
2. Allocate the record number inside the same transaction as the record insert (092).
3. Time-box the location fix, store the accuracy with it, and save without waiting when the fix is slow or absent.

## Constraints

- GPS is off by default, and no location permission is requested while it is off (FE-SEC-07).
- Time, device identity and location come from injected `core/` services so tests can freeze them (FE-STR-11).
- Dates and times are formatted through `intl` from the project setting, never assembled by hand (FE-L10N-04).

## Definition of done

- [ ] A record captured with no typing still carries a complete timestamp, operator and device.
- [ ] Twenty rapid captures produce twenty consecutive record numbers with no gap or duplicate.
- [ ] With GPS off, no location permission is requested anywhere and no location call is made.
- [ ] Tests: unit test with a frozen clock asserting every automatic value and every `autoFill` combination; concurrency test allocating numbers from parallel inserts; test that the disabled GPS path makes no location call and that a slow fix does not delay the save.
