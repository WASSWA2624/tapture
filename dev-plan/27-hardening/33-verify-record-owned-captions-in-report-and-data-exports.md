# 141 — Verify record-owned captions in report and data exports

**Depends on** [012](../12-capture.md), [018](../18-export.md), [090](../18-export.md)

## Implement

Reconcile the record-owned source-caption contract with the report and data export contracts. Section 52 of
`app-write-up.md` names captions among a record report's contents; task 018's specific acceptance verifies photos
with captions. Establish which selected outputs must carry a record's own raw and refined captions, separately
from template fields named `caption_raw` or `caption_refined` and from photo captions. Verify those outputs end
to end and repair any confirmed omission through the existing record loader, export types and shared writers.

Keep source captions durable and unchanged. Refinement and export write beside the original; a missing template
field or an unprocessed record must not be mistaken for a missing source caption. This follow-up does not block
task 136's APK delivery or task 140's PDF secret-scanning repair.

## Files

- `app-write-up.md` (sections 22, 49 and 52, for caption/export contract reconciliation)
- `frontend/lib/core/db/tables/captions.dart`
- `frontend/lib/features/records/domain/record_entry.dart`
- `frontend/lib/features/records/data/record_queries.dart`
- `frontend/lib/features/exports/data/export_record_loader.dart`
- `frontend/lib/core/export/export_record.dart`
- `frontend/lib/core/export/pdf/record_report.dart` and the existing shared data/document writers
- `frontend/test/features/exports/` and `frontend/test/core/export/` (focused source-caption fixtures)
- `frontend/integration_test/` (real database/capture/export preservation scenario)

## Constraints

- Reuse the existing source-caption ownership, raw/refined storage, export loader and report foundation.
- Do not synthesize template-field values from captions silently or overwrite immutable source text.
- Preserve existing photo-caption and approved-value behavior and disclose the effect of export column choices.
- Keep operator data and device-specific validation artifacts local; commit reusable synthetic fixtures only.

## Definition of done

- [ ] The report/data export contract explicitly distinguishes record-owned source captions, template caption fields and photo captions, including raw/refined selection for unprocessed and processed records.
- [ ] Every output named by that contract includes the appropriate record-owned caption text without requiring a template caption field, while retaining existing photo-caption and field-value behavior.
- [ ] Tests: focused loader and shared-writer fixtures cover typed and spoken source captions, raw/refined selection, missing template caption fields, photo captions and unprocessed records.
- [ ] Tests: a real database/capture/export scenario verifies original source-caption bytes survive restart and export, and checks the selected delivered PDF/data output text independently of its manifest.
- [ ] Section 52 and the relevant export acceptance criteria agree with the verified implementation; remaining exclusions are explicit and backed by fixtures.

## Discovery evidence — 2026-10-07

The owned task 136 Android emulator fixture staged a caption in Capture; its saved record heading survived
an app restart. Later independent project-package inspection verifies the retained record-owned `text_raw`
value is exactly `APK smoke durable capt`. The original capture evidence remains retained on that local test
device. No source caption or raw attachment bytes were deleted or overwritten by export validation.

The actual delivered ZIP passed CRC, manifest/photo-reference and dictionary checks. Independent PDF parsing
and raster inspection verified all five record-report pages and two summary pages. The record report preserves
its two non-empty exported fields (`observed_at` and `observer_name`) and embeds the selected photo. It omits the
record-owned source caption: schema `caption_raw`/`caption_refined` are null and the exported photo caption is empty.

`RecordEntry.caption` represents the record-owned caption (refined, otherwise raw); `ExportRecordLoader` currently
copies `record.values` and `photo.caption` and does not map `record.caption`. This is evidence of a deliverable
contract gap to reconcile, not evidence that the durable source caption was lost. The full raw/refined source
byte and export-selection requirements remain unverified. All task acceptance items remain open and
implementation has not started.

The preserved ZIP, parsed text, page rasters and detailed caption distinction are in the ignored local
`frontend/build/apk-validation/android-deliverables-validation-6f1463/validation-summary.json` and sibling files.
