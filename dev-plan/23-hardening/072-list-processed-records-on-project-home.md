# 072 — List processed records on the project home

**Phase** 23 · Hardening  |  **Depends on** [070](070-resolve-web-capture-caption-template-feedback.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Found while building task 070's records status filter. Processing's validate stage writes the record status
`NEEDS_REVIEW` or `EXTRACTED` (`ProposalApplication.needsReviewStatus`, `extractedStatus`), but the project home
lists records whose status is in `capturedItemStatuses` (`features/projects/presentation/captured_items.dart`),
which spells those two `needsReview` and `extracted`. `ProjectRepositoryImpl.watchRecords` and
`watchTemplateRecordCounts` match with SQL `IN`, which is case-sensitive, so a record drops off the project home,
out of its template's record count and out of the status filter as soon as processing finishes. Task 070's W11
makes `EXTRACTED` more common, since a default can now fill a required field.

Make the stored status and the listed statuses agree: one set of status values, written by capture and processing
and read by the lists, so every live record is listed whatever stage it has reached. `ProjectRecordFilter.statusOf`
already folds case and separators when naming a stored status.

## Files

- `frontend/lib/features/projects/presentation/captured_items.dart`
- `frontend/lib/features/projects/data/project_repository_impl.dart`
- `frontend/lib/features/processing/domain/proposal_application.dart`

## Definition of done

- [ ] A record that processing marks `NEEDS_REVIEW` or `EXTRACTED` stays on its project home, in its template's
      record count, and under its status in the records filter.
- [ ] Records captured before the change are listed without a migration step the operator has to run.
- [ ] Tests: repository watch queries over records in every status, and a project home widget test with a
      processed record.
