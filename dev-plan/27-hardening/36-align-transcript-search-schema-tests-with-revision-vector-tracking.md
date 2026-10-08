# 151 — Align transcript search schema tests with revision-vector tracking

**Depends on** [014](../14-records.md), [127](../24-product-refinements.md)

## Implement

Repair the existing transcript search schema fixture so it verifies the no-rebuild contract alongside the
required revision-vector tracking introduced by task 127. Reuse the real in-memory database and existing row
helpers; this task changes acceptance fixtures, not application SQL or schema.

- Replace the assumption that `transcript_segments` has no triggers with exact assertions distinguishing its
  required vector insert/update triggers from search triggers. Preserve the exact transcript and attachment
  search-trigger inventory.
- Observe the actual search document before and after live and late completed-transcript segment inserts.
  Use a test-owned mutation recorder on the ordinary search-document table, alongside document/body snapshots,
  to detect a redundant rebuild even when the resulting text is unchanged. No search-document mutation may occur.
- Account explicitly for the required causal-vector write rather than treating `total_changes()` as the number
  of search-index writes. Assert the inserted segment's vector, retain vector insert/update trigger coverage and
  appropriate authored-update behavior in the existing vector suite, and preserve raw segment immutability.
- Retain the existing search behavior: live text is absent, completion indexes existing segments, a late segment
  does not become searchable through an unintended rebuild, and linked/tombstoned raw and edited words follow
  the existing search contract.

## Files

- `frontend/test/core/db/record_schema_test.dart`
- `frontend/test/core/db/record_rows.dart` (only if a reusable test helper is necessary)
- `frontend/test/core/db/version_vector_schema_test.dart` (only if existing insert/update coverage needs a precise extension)
- `dev-plan/24-product-refinements.md` (task 119's reopened search acceptance evidence)

## Constraints

- Do not edit production SQL, migrations, schema version, vector suppression, segment persistence or search triggers.
- Do not remove required vector triggers, suppress authored vector writes, exclude this test, or replace real
  database assertions with mocks. A corrected change count alone does not prove that no document rebuild occurred.
- Any temporary mutation recorder belongs to the isolated fixture and is removed with it. Preserve all existing
  search exclusions, exact trigger inventories and raw-evidence assertions.

## Definition of done

- [ ] Tests: fresh schema and existing upgrade/vector coverage retain the exact required vector insert/update triggers and exact named transcript/attachment search-trigger inventory.
- [ ] Tests: a live segment insert and a late completed-transcript segment insert leave the search document/body unchanged and produce no recorded search-document writes, while the appropriate causal vector is present.
- [ ] Tests: completion still indexes earlier segments, late text remains absent, and linked, tombstoned, edited and cleared transcript search cases remain green.
- [ ] Tests: the no-rebuild assertion detects a deliberate fixture-only redundant document mutation, including a same-value update; removing the mutation restores a passing fixture.
- [ ] Changed-source formatting, frontend analysis, `record_schema_test`, `version_vector_schema_test` and relevant migration/search regressions pass on the current tree without production/schema changes or weakened assertions.
- [ ] Task 119's specific search acceptance records fresh evidence before it is rechecked; tracker synchronization, `--check` and plan integrity checks pass.

## Evidence

2026-10-08: the task 147 native regression run failed the existing test "a segment insert never rebuilds a
document" at `frontend/test/core/db/record_schema_test.dart:966`: the unrestricted `sqlite_master` trigger query
expected zero rows and returned two. The later assertions at lines 973 and 981 also expect a global
`total_changes()` delta of one, although an authored segment insert must additionally write its causal vector.
The source indicates a delta of two; this later assertion was not reached in the failing run.

The required `vector_transcript_segments_insert` and `vector_transcript_segments_update` definitions follow from
`VersionVectorSchema.tables` and its existing trigger generator. Commit `68cc7f910bd3a8ac1efc159c8b9b2eaa4408bf95`
(2026-10-04, task 127/schema 33) added transcripts and segments to that table list. The relevant production
schema/vector/migration sources have no task 147 diff. Current native vector tests "every exchanged table has
authored-write triggers" and "a fresh database counts authored transcript and segment writes" passed; this
failure is an older fixture assumption, not evidence of a production vector defect or a Drift/SQLite upgrade
regression. Task 005 owns file storage; task 014 owns record search, and task 119 owns this transcript-search
acceptance fixture. Historical October 4 verification remains intact. Implementation has not begun; all
acceptance items remain open.
