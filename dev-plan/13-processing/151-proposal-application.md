# 151 — Apply proposals with confidence bands

**Phase** 13 · Processing  |  **Depends on** [018](../01-orchestration/018-network-test.md), [054](../04-data-layer/054-records-table.md), [078](../07-account-and-settings/078-settings-store.md), [150](150-response-parse.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Parsed values written to `record_fields` as proposals carrying source, confidence and a band, never as approved data
and never over a verified or manual value, with the record moved to NEEDS_REVIEW when anything is uncertain.

## Files

- `frontend/lib/features/processing/domain/proposal_application.dart` (new)
- `frontend/lib/features/processing/domain/confidence.dart` (new)

## Steps

1. Write `valueRaw` with source and confidence; skip any field already verified or entered by hand and record the
   skip.
2. Band each score as high, medium or review-required against the project thresholds in the settings store; one
   banding function serves every screen that shows a band.
3. Set the record status to NEEDS_REVIEW when any applied value lands in the review-required band or a required field
   is still empty.

## Constraints

- Nothing written here is approved data; the raw-data test of task 018 must stay green.
- Thresholds come from settings, never from a literal (FE-CODE-09).

## Definition of done

- [ ] A verified field survives reprocessing untouched.
- [ ] Thresholds are configurable per project and yield the same band everywhere they are read.
- [ ] Tests: unit tests that verified and manual values are preserved, that banding follows the configured
      thresholds, and that a review-required value forces NEEDS_REVIEW, with no Flutter binding.
