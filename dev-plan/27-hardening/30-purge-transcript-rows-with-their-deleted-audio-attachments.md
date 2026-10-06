# 134 — Purge transcript rows with their deleted audio attachments

**Depends on** [014](../14-records.md), [119](../24-product-refinements.md)

## Implement

Extend the existing retention/empty-now purge to include transcripts linked to the record's purged audio
attachments and their segments, plus associated audit, version-vector and tombstone metadata. Keep ordinary
delete/restore and transcript discard as tombstone operations. Never remove standalone transcripts, transcripts
owned by another record or files before the existing retention and merge gates permit deletion.

## Files

- `frontend/lib/features/records/data/record_purge_store.dart`
- `frontend/lib/core/db/tables/transcripts.dart`, `frontend/lib/core/db/tables/transcript_segments.dart`
- `frontend/test/features/records/data/record_purge_store_test.dart`
- `frontend/test/features/transcripts/data/transcript_repository_impl_test.dart`

## Definition of done

- [ ] Retention and explicitly confirmed empty-now purge remove linked transcript headers, segments and ownership
      metadata in the same durable row transaction; purged content is absent from transcript reads and history.
- [ ] Ordinary delete/restore preserves transcript content; recent and unmerged tombstones remain protected, and
      unrelated or standalone transcripts remain unchanged.
- [ ] Tests cover both purge entry points, restore, protected tombstones, another record's transcripts and failed
      file deletion; frontend analysis and relevant data-safety guardrails pass.

## Evidence

- 2026-10-06: Task 132 integration review found that `RecordPurgeStore._ownedRows` and `_deleteRows` omit both
  transcript tables. Their attachment/transcript identifiers have no foreign-key cascade. Record-delete UI correctly
  describes retention, but a transcript can remain visible in project history after its audio attachment is purged.
  This existing retention gap is outside task 132's processing integration and remains open for final hardening.
