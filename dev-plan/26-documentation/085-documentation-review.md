# 085 — Render, review and approve versioned documents

**Implementation step:** 26.06

**Phase** 26 · Documentation  |  **Depends on** [084](084-documentation-generation.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Turn the canonical draft into locally generated files, then make review, correction and approval meaningful
(§§78, 81). A single canonical content model feeds editable DOCX/XLSX and PDF/Markdown/CSV adapters where
applicable. AI does not write the binary file. Each output has its own preview, validation findings, evidence,
versions and approval state; one failed renderer does not invalidate another successfully generated document.

Use task 080's format adapters and existing export writers. Extend the reusable renderers where required: current
PDF text output is not sufficient for a multi-page report with tables/images, and DOCX must be an editable Office
document. Renderers use deterministic layout/content decisions for the same canonical revision, template, settings
and renderer version. Preserve supported template features and explain unsupported fidelity explicitly.

## Files

- `frontend/lib/features/documentation/domain/` (canonical document, validation, version/review rules)
- `frontend/lib/features/documentation/data/` (render orchestration, artifact writes and version repository)
- `frontend/lib/features/documentation/presentation/` (preview, evidence, editing and history)
- `frontend/lib/core/documents/`, `frontend/lib/core/export/` (shared DOCX/PDF/XLSX/CSV/Markdown adapters)
- Existing share/download and project export surfaces through public contracts
- `frontend/test/features/documentation/`, `frontend/test/core/export/`, representative document fixtures

## Contract

- `DocumentRenderer` consumes canonical content, a confirmed output-definition snapshot and optional original
  template bytes; returns bytes/stream, MIME, extension, renderer version and fidelity/validation findings. Rendering
  accepts cancellation and never writes over a previous version or original template.
- `DocumentValidator` checks output requirements, types, allowed empty values, citation resolution, row/section
  coverage and format-specific constraints. Findings have severity, output/block/cell locator and a recovery action.
- Review state is **Draft**, **Needs review**, **Approved** or **Archived**, separate from run/render state. Approval binds an
  exact canonical revision and its rendered file hashes. Editing a source snapshot, prompt or definition causes a
  new run; editing draft content creates a new document revision and clears that revision's approval.
- `DocumentProvenance` links sections/claims/table cells to resource revisions and locators, plus operator edits,
  run settings and generation metadata. Keep provenance available in the app and an optional sidecar even when the
  user chooses a clean final document without visible citations.
  Native/archive citations identify the origin project and record/template revision while opening the destination's
  retained snapshot, so equal record numbers and deleted/edited origin projects cannot misdirect the reviewer.

## Steps

1. Implement typed narrative blocks, tables/cells, image references and citations. Reuse one validation/content
   representation for all renderers. Sanitize output filenames and references; never let provider data become a
   path, macro, executable link or formula without explicit supported-template rules.
2. Implement DOCX headings, paragraphs, lists, tables, images and supported placeholders; XLSX header mapping,
   row insertion, types and supported formatting/formula preservation; paginated PDF with repeated table headers
   and images; UTF-8 Markdown; CSV with deliberate spreadsheet-injection protection. Do not treat formulas as
   evaluated facts unless a supported calculation path verifies their results; preserve supported template formulas
   without executing macros or external links. CSV cannot promise workbook formulas/styles/multiple sheets.
3. Validate completed files with an independent reader, including MIME/extension, row/section counts, Unicode,
   long content and file integrity. Compare supported template structure and expose differences before approval.
   Persist artifacts atomically with checksum and export/run/version metadata; cancel cleans staging only.
4. Build review with document/table preview and an evidence panel reached from findings or citations. Keep unknown,
   conflicting and excluded material visible. Required unresolved gaps prevent final approval until corrected or
   explicitly changed to an allowed missing-value policy; do not invent facts to pass validation.
5. Add manual edits, local rerender without AI, regenerate-as-new-version, comparison and history. User edits have
   operator provenance instead of invented source citations. Regenerating a section/output preserves previous
   human edits in history and never overwrites them silently.
6. Add Approve, Export final and explicit Export draft through existing file/download services. Final export
   requires approval of the exact definition/content and all selected format hashes after every selected render
   is readable. Draft export is required by §81, visibly labelled in filenames and metadata and, where supported,
   in the document. It never grants approval. Supersession is a relationship to a newer version, not a status that
   revokes the old approved version; previous approved artifacts remain exportable.

## Constraints

- Every file is created on the device. Offline rerender/edit/approve/export of a saved draft remains possible.
- Preserve original format resources and all previous versions. An approved binary is not mutated in place.
- A citation verifies that an evidence reference exists, not that a claim is true; review must show the source.
- Unsupported template constructs are blocked or visibly accepted as recreation limits, never silently lost.
- No new feature-specific share sheet, error widget, rich text editor or form control (FE-CONS-01).

## Definition of done

- [ ] Representative DOCX, XLSX, PDF, Markdown and CSV outputs open in independent readers, carry the confirmed
      required sections/headers and contain supported Unicode, tables and images without corruption.
- [ ] Render verification covers page breaks, table overflow, long headings, empty values, merged/header cells,
      repeated rows, supported formulas and unsupported fidelity warnings; golden/reference fixtures cover layout.
- [ ] Every generated claim/cell requiring evidence reaches a retained source locator or displays its gap/manual
      origin; invalid citations and contradictions cannot be hidden by a clean preview.
- [ ] Evidence drawn from several projects and an uploaded archive remains distinguishable and readable after an
      origin is edited/deleted; final-export source inclusion follows captured source and destination restrictions.
- [ ] Human correction creates a revision, clears approval and rerenders offline; regeneration creates a separate
      version and leaves prior manual edits and approved artifacts intact.
- [ ] Approval records person, time and exact definition/revision/selected-format hashes; final export refuses an
      unapproved revision, incomplete render set or required unresolved issues. Explicit draft export is available
      and visibly identified, and a superseded approved revision remains immutable and exportable.
- [ ] Restart, cancellation, low storage and one failed output preserve successful artifacts and historical versions.
- [ ] Tests cover render determinism at the canonical/content level, version transitions, permission affordances,
      provenance, filenames/CSV injection and accessible review at mobile and desktop widths.
