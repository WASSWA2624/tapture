# 202 — Record and inspection reports

**Phase** 18 · Export  |  **Depends on** [103](../09-templates/103-predefined-rows-import.md), [177](../15-data-quality/177-variance-computation.md), [196](196-photo-naming-service.md), [201](201-pdf-engine.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The two record-level reports of A52. The record report renders each record as a page or block with its fields, photos,
captions, context path and operator. The inspection report renders a checklist template — `inspection_check` and
anything derived from it — as checklist items with observations, compliance, risk, recommendations and photo evidence.

## Files

- `frontend/lib/core/export/pdf/record_report.dart` (new)
- `frontend/lib/core/export/pdf/inspection_report.dart` (new)

## Steps

1. Record report: offer thumbnail and full-size photo layouts, both through the engine's photo block.
2. Inspection report: order rows by the template's predefined rows (A15), so the report reads in the order the
   inspector worked rather than in capture order.
3. Render each checklist row as its result, observation, risk and recommendation, with the photos evidencing it
   beneath. A row never found prints as **Not found** — a finding, not a gap (A15).
4. Carry the compliance total and the count of not-found rows onto the cover, so the deliverable states its own
   completeness.
5. Print the raw observation beside the refined one wherever the field carries both and the project has that option on
   (A32).

## Constraints

- Cover, header, footer, page numbers and photo blocks come from `pdf_engine.dart`; neither report starts a second PDF
  foundation (FE-CONS-02).
- Checklist progress and the not-found set are read from 184 and 333, never recomputed here (FE-STATE-06).

## Definition of done

- [ ] A record's fields, photos with captions, context path and operator all appear, in both photo layouts.
- [ ] All five reports of A52 now exist and share the layout of 376.
- [ ] An inspection row that was never captured appears as **Not found** rather than being omitted, and is counted on the cover.
- [ ] Tests: golden tests of a rendered record page and inspection page, plus unit tests asserting inspection row order follows the predefined rows and that not-found rows are present.
