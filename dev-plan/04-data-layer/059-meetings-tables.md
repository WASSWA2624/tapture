# 059 — Meeting tables

**Phase** 04 · Local database  |  **Depends on** [054](054-records-table.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The meeting header with its raw transcript and refined minutes, its attendee list, and its action items.

## Files

- `frontend/lib/core/db/tables/meetings.dart` (new)

## Steps

1. Meetings: `recordId`, `title`, `startAt`, `endAt`, `chair`, `secretary`, `agenda` JSON, `transcriptRaw`,
   `minutesRefined`.
2. Attendees: `meetingId`, `name`, `title`, `organisation`, `contact`, `signaturePresent`, `matchedStaffId` nullable.
3. Actions: `meetingId`, `action`, `ownerName`, `dueDate`, `status`; index on `meetingId` plus `status`.

## Constraints

- All three tables declare the shared merge columns through `MergeColumns` in the migration that creates them
  (FE-SEC-09).
- `transcriptRaw` is written once and never edited; refinement writes `minutesRefined` beside it (FE-SEC-08).
- Attendee names and contacts are personal data: no default GPS, no export beyond what the project consent flag allows
  (FE-SEC-07).

## Definition of done

- [x] A meeting with attendees and actions round-trips and deletes as one transaction with tombstones for each row.
- [x] Refining minutes leaves `transcriptRaw` byte-identical.
- [x] An attendee matched to a staff record keeps the free-text name that was captured.
- [x] Tests: `frontend/test/core/db/tables/meetings_test.dart` covers header, attendee and action inserts, transcript
      immutability under refinement, and cascade-with-tombstones on delete, against an in-memory database, covering the
      migration step.
