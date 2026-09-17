# 150 — Parse, repair and persist the response

**Phase** 13 · Processing  |  **Depends on** [057](../04-data-layer/057-jobs-table.md), [089](../09-templates/089-field-type-registry.md), [143](143-job-runner.md), [149](149-extraction-request.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Provider output stored as it arrived, turned into typed proposals against the schema the template implies, with one
repair attempt when it will not parse and a permanent failure after that.

## Files

- `frontend/lib/features/processing/domain/response_parser.dart` (new)
- `frontend/lib/features/processing/domain/response_repair.dart` (new)
- `frontend/lib/features/processing/data/response_store.dart` (new)

## Steps

1. Store the raw response and a request summary against the job (task 057) before parsing; never store the key.
2. Validate against the schema derived from the template's field types (task 089); drop unknown keys; coerce types
   safely; reject anything malformed rather than guessing.
3. On a parse failure, re-request once with the parse error described, then fail the job as permanent through the
   retry classifier.

## Constraints

- Everything that arrives is validated for structure and type before use (FE-SEC-06).
- The stored request summary contains no key and no secret (FE-SEC-01).

## Definition of done

- [ ] A malformed or hostile response never corrupts a record.
- [ ] A failed job leaves the raw response stored for inspection.
- [ ] A record can be reprocessed from stored output with no new call.
- [ ] Tests: unit tests over valid, partial, hostile and unparseable responses, including the single repair attempt,
      with no Flutter binding; repository tests for `response_store.dart` against an in-memory database, plus the fake
      later tests use.
