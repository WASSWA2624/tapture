# 083 — Build the Inputs, Outputs and Prompt workspace

**Phase** 26 · Documentation  |  **Depends on** [079](../06-app-shell/079-mobile-more-menu.md), [082](082-documentation-ingestion.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Build the simple workspace in §§76, 78–79 and 83: **Input resources**, **Output documents**,
**Instructions (optional)**, and one primary
**Create documents** action. Progressive disclosure keeps extraction diagnostics, section/cell mappings and
advanced settings out of the initial flow. A user can prepare and save everything offline. Until task 084 wires
generation, the action reports unavailable capability instead of simulating success.

Each output definition names its result, selects one or more compatible DOCX/PDF/Markdown or XLSX/CSV render
formats, and optionally attaches
one or more format/requirements resources. A built-in simple report/table definition works without an uploaded
format. Multiple outputs share explicitly chosen inputs but have independent structure, validation and history.
Input facts, output structure and instructions are visibly different roles even when the same file is deliberately
used in more than one role.

## Files

- `frontend/lib/features/documentation/domain/` (output definition, structure, mapping and prompt models)
- `frontend/lib/features/documentation/data/` (template inspection and prompt-file normalization)
- `frontend/lib/features/documentation/presentation/` (workspace/list, output editor and preview)
- `frontend/lib/core/widgets/` (shared rich text editor and reusable resource/output rows where needed)
- `frontend/lib/core/copy/`, shared widget gallery and themes/tokens only where existing tokens are insufficient
- `frontend/lib/app/router.dart`, shell navigation/More destinations, project-home entry points
- `frontend/test/features/documentation/`, `frontend/test/core/widgets/`, `frontend/test/app/`

## Contract

- `OutputDefinition` has a versioned, canonical structure: sections and tables for narrative output; sheets,
  headers, column types, target ranges and row rules for tabular output. It carries requiredness, mapped fields,
  missing-value behaviour, constraints, chosen fidelity mode and referenced template/requirement revisions.
  One deliverable has one canonical revision and a compatible format set; a report rendered to DOCX and PDF is not
  two independent output definitions. A register alongside the report has its own definition.
- `OutputTemplateInspector` proposes a definition and unsupported-feature findings; it does not silently confirm
  ambiguous headers, formulas, merged cells or conflicting format resources. Editable original and normalized
  definition are retained together.
- `DocumentPrompt` stores a sanitized rich-text representation plus canonical plain instructions and optional
  `.md`, `.docx` or `.txt` prompt-resource revision. File instructions are the base; explicitly typed instructions
  refine/override them, while system grounding and confirmed output constraints remain enforced. Material conflicts
  are shown before generation. Original prompt bytes and normalized instructions remain available.
- A shared rich text editor supports paragraphs, headings, bold/italic, ordered/bulleted lists and safe links with
  keyboard and screen-reader access;
  no feature embeds a separate editor package directly or stores executable HTML.

## Steps

1. Assemble the workspace from shared rows, fields, sections, dialogs, buttons, async states and `Copy`. Autosave
   through task 081. The output list supports add, rename, duplicate and remove; the common path needs no wizard.
   Start with Report · DOCX, a local generated title and the visible default instruction in §79.1, all editable.
   Inputs defaults to **Projects**, with the current project's approved captured records selected on a new
   workspace and visible counts/filter scope. The picker can add further projects, then optional **Files** and
   **Project archive** sources, with context/date/template/status filters and an evidence preview. No upload is
   required, and captured projects are not required either: make the preselected project removable in one action.
   Upload-only work explicitly deselects project sources. If the project has no eligible records, offer
   another project, supplementary sources or explicit unapproved inclusion without forcing capture/template setup.
   Display origin project/archive beside identically named records; show destination ownership separately.
   Reopening a saved workspace retains the exact chosen scope. Resolve lightweight native selections and freeze
   their immutable dependency snapshots when a run starts, never by copying a project just to open this screen.
2. Inspect format documents locally using task 082: DOCX placeholders/headings/tables and XLSX headers/sheets.
   PDF/MD/DOCX requirements can describe a recreated layout; they are not editable template masters by default.
   Show whether the chosen renderer preserves a supported template or recreates structure and where fidelity is
   partial. Unsupported or conflicting requirements must be resolved or explicitly accepted as a visible limitation.
3. Confirm column/header mappings, required sections and allowed empty markers. Warn on duplicate/blank headers,
   macros, external links, formulas and unmapped required placeholders. Template sample text/rows are examples;
   importing them as factual input requires a separate explicit input role.
4. Add prompt-file selection and rich text entry, both optional. Preview the effective instructions. Prompt file
   parsing cannot silently treat a failed import as an empty prompt. Changes update the draft and future run only.
5. Connect Documentation to the active project and the mobile More menu from task 079, with a document icon and
   labelled row. With no active project, use the existing project-selection guard and resume the requested route.
   Desktop/tablet show an equivalent reachable navigation entry without adding a fifth mobile tab.
6. Implement a generation-readiness summary: inputs readable or explicitly excluded, at least one valid output,
   format mappings confirmed, prompt parsed, and storage/capability constraints met. Advanced diagnostics remain
   available without obstructing a valid simple report.

## Constraints

- Square components and zero-radius menus follow existing design tokens. No one-off rounded cards or custom form
  controls (FE-CONS-01, FE-CONS-02). Responsive layout changes preserve input, route and selected output.
- User-editable instructions cannot override grounding, request extra unselected files or trigger external actions.
- XLSX record-capture templates and Documentation output definitions are distinct concepts; reuse parsing/writing
  primitives without mutating the project's capture schema.
- Opening Documentation, importing files or saving a draft never sends an AI request.
- Readiness requires at least one readable source of any supported kind, never specifically a captured project.
  Removing a default is durable; reopening or generating must not reinsert that project selection.
  An empty default project is visibly empty and cannot block a valid uploaded-source workflow.

## Definition of done

- [ ] A user prepares an output with inputs and no prompt/template, or multiple named outputs with separate format
      files and optional rich text/file instructions, then resumes the exact draft after restart.
- [ ] The workspace can combine native projects A/B, project archive C and loose documents without switching the
      destination project or importing a new live project; source filters, counts, approvals and origins are clear.
- [ ] A new workspace defaults to current-project approved records and can generate with zero uploaded files and
      no prompt. Empty eligible scope, adding projects, explicit unapproved inclusion and upload-only deselection
      have clear paths; reopening a saved workspace neither changes its sources nor copies new project records.
- [ ] Clearing all captured-project selections permits files-only and project-archive-only generation; the removed
      default stays removed after restart, and no source-project/record/template requirement blocks either path.
- [ ] DOCX section/placeholder and XLSX header-mapping fixtures produce reviewable output definitions; sample values
      are excluded from factual inputs unless explicitly selected in both roles.
- [ ] Prompt file alone, typed instructions alone, both, neither and failed prompt parsing behave as documented.
- [ ] Unsupported fidelity and conflicting requirements are visible before the run, with a repair/exclusion path.
- [ ] Documentation is reachable from More and project context; no-project selection resumes correctly; existing
      Settings/processing/template routes and capture remain reachable with four mobile navigation controls.
- [ ] Widget tests cover empty/loading/error states, narrow/medium/expanded layouts, 200 percent text, keyboard,
      screen-reader labels, dirty-draft navigation and width changes without lost input.
- [ ] Shared rich text and new reusable widgets have gallery coverage and light/dark/outdoor goldens.
