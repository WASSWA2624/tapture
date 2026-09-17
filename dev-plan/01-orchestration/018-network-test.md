# 018 — Network boundary and raw-data safety tests

**Phase** 01 · Project setup and guardrails  |  **Depends on** [004](004-folder-scaffold.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Two architecture suites over the security invariants: `network_test.dart` confines networking to the three folders
allowed to do it, and `data_safety_test.dart` stops code overwriting or hard-deleting raw evidence.

## Files

- `frontend/test/architecture/network_test.dart` (new)
- `frontend/test/architecture/data_safety_test.dart` (new)

## Steps

1. In `network_test.dart`, fail on any import of a HTTP client outside `frontend/lib/core/ai/`, `frontend/lib/core/cloud/` and `frontend/lib/core/backend/`.
2. Fail when a widget or a `domain/` file references a network client type.
3. Assert no capture, records or export file imports a networking package.
4. In `data_safety_test.dart`, fail on any assignment or update writing a field named `valueRaw`, `textRaw` or `transcriptRaw` outside the repository method that creates the row.
5. Fail on any hard row delete in a repository; deletion goes through the tombstone helper.
6. Fail on any file delete call outside the purge job.

## Constraints

- Egress is a closed list: networking imports live only in `core/ai/`, `core/cloud/` and `core/backend/`, and a screen never speaks to a server (FE-SEC-03).
- Raw values, captions, transcripts and original photos are written once; refinement writes a separate column, deletion is a tombstone, and files go only to the purge job after the retention window (FE-SEC-08).
- `domain/` imports no HTTP client at all, so a finding there is a layering defect as well as a security one (FE-STR-05).

## Definition of done

- [ ] A HTTP call added inside a feature repository fails `network_test.dart`, while the same import under `core/backend/` passes.
- [ ] An update to `valueRaw` in a refinement service, a hard row delete and a file delete outside the purge job each fail `data_safety_test.dart`.
- [ ] Tests: both suites with compliant fixtures and one non-compliant fixture per violation, under `frontend/test/architecture/fixtures/`.
