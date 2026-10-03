# 26 — Documentation

Turn captured project data into reviewed documents through one local workspace: Inputs, Outputs and an optional
Prompt. New workspaces preselect the current project's approved records with visible scope/counts, purely for
convenience. **Captured projects are never required inputs.** Users can clear the project selection and use only
uploaded files or project archives, or combine any of these sources. Specification
[Part XII, §§76–84](../app-write-up.md) owns the product behaviour.

## Build order

The task list below is sequential. Task 079 delivers the mobile More menu independently; task 083 connects the
Documentation destination when the workspace exists. Each task ships its own tests and uses [AGENTS.md](../AGENTS.md).

## Current repository and gaps

| Reuse | Work that still has to exist |
| :--- | :--- |
| Drift, project identity, merge columns, audit and tombstones | Documentation workspace, resource, output, run and revision entities; migrations and lifecycle |
| `core/files/` readers, writers, blob storage, storage guard and document picker | Multi-file picking; durable imported originals; per-file capabilities and safe archive expansion |
| Record processing, OCR, consent, cost controls and lease/retry concepts | Source extraction with locators; a document job that does not require a fake record; document generation |
| `AiService`, `ProxyAiService` and backend AI routes | Production transport and request parity, a typed generation operation and an actual configured provider |
| XLSX/CSV writers and template-copy helpers | Supported template fidelity checks, editable DOCX, paginated document PDF and canonical document rendering |
| Shared widgets, `Copy`, routes and responsive shell | Shared rich text editor, the three-section workspace, review and history |
| Project ZIP package, hash manifest, merge and share/download | Versioned Documentation entries, provenance, revisions and merge behaviour |

Task 013's checklist records its processing scope as complete; task 024 remains partially complete. Neither status
establishes that end-to-end document AI is wired:
`main.dart` uses a keyless provider registry, the current `ProxyAiService` emits metadata counts rather than the
backend's `projectId`/`model`/`payload` envelope, and neither AI interface exposes generation. Task 084 must close
the gaps required for this module and verify the real path. Its completion must not close unrelated processing work.
`ProcessingJob` and its queue are record-scoped today; shared primitives must be extracted without breaking those
contracts. The existing `PdfEngine` emits a single text stream, so document pagination and embedded images cannot
be assumed. DOCX support and a rich text editor are not present in the current dependency list. Task 080 is the
dedicated dependency/capability task required by FE-FLOW-06; subsequent tasks implement the module against it.

## Delivery boundaries

- The first useful slice offers optional captured-project sources by default, accepts uploaded sources, extracts
  supported content and preserves a resumable local workspace. Unsupported files stay visible with an explanation;
  attaching a file is not evidence that AI read it.
- The first complete release creates editable DOCX and XLSX plus PDF, Markdown and CSV adapters where applicable,
  using confirmed output definitions and evidence-linked content. No arbitrary Office or PDF layout is promised.
- ZIP is the initial expandable archive. Other archives are retained, labelled unsupported and may be manually
  unpacked by the user. Nested, encrypted and unsafe archives are never silently expanded.
- Input facts, output structure and user instructions remain distinct roles. The same source may be deliberately
  assigned more than one role. Template examples never silently become facts.
- All originals, extracted derivatives, prompts, jobs, drafts and approved revisions are authoritative on the
  device. The backend performs bounded AI requests and retains metadata only; it is not a document repository,
  vector database, render farm or durable job queue.
- Captured content from one or several explicitly chosen projects, an uploaded project archive, and loose files can
  be combined in one run. Native records/meetings and archive content become immutable source snapshots with their
  chosen dependency closure in the destination workspace's store; there is no implicit whole-project scan, live
  source-project dependency or automatic archive merge. Source and destination privacy rules both apply.
- No Documentation destination is exposed until it can open a useful workspace. The More menu itself is useful
  immediately for existing secondary destinations, and keeps four mobile navigation controls.

## Release acceptance

This module's acceptance precedes [final whole-app hardening](27-hardening/). A successful module run
does not replace that final pass or the release gates over the completed app and backend.

Task 086 runs the workflows in §84: a narrative report from mixed documents and media, an XLSX template with
required headers, multiple outputs from one source set, partial and unsupported extraction, offline preparation,
restart/retry, safe ZIP handling, provenance and human approval, and bundle round trips. The release gate includes
Android, desktop and web capabilities, accessibility, resource limits and metadata-only backend logging.
Each task's Definition of done carries the specific assertions, fixtures and regression coverage.
The source acceptance includes a combined run from projects A and B, a project archive C and loose documents,
with provenance and privacy preserved after an originating project is edited or deleted.
The shortest acceptance path starts with the current captured project and creates a document without uploading
any file or entering a prompt. Existing workspaces retain their saved selections instead of adding fresh defaults.

## 080 — Establish document adapters and approved dependencies

**Depends on** [005](05-file-storage.md), [018](18-export.md)

### Implement

Establish the supported formats and platform adapters required by §§77–78, before promising that any attachment
can be read or reproduced. This is the dedicated dependency task under FE-FLOW-06. It must leave executable
adapter probes and fakes, an explicit capability registry, and pinned, licensed dependencies where existing code
cannot do the job; a package shortlist alone is not completion.

Evaluate the existing archive/XML, CSV/XLSX, OCR, file and export facilities first. Inspect real fixture outputs:
the current PDF writer is not a paginated document renderer, and DOCX, PDF reading, video extraction and rich text
editing are not demonstrated by a checked task elsewhere in the plan. Reuse existing public contracts where
possible; wrap chosen packages in `core/`, with pure domain-facing interfaces and platform implementations.

### Files

- `frontend/pubspec.yaml`, `frontend/pubspec.lock`, `frontend/tool/allowlist.yaml`
- `frontend/lib/core/documents/` (new capability models, decoder/render adapter interfaces and platform bridges)
- `frontend/lib/core/files/document_picker*.dart`, platform file-channel implementations
- `frontend/lib/core/export/` (adapter bridges to existing writers)
- `frontend/test/core/documents/`, `frontend/test/fixtures/documentation/`
- `frontend/tool/check_structure.dart`, architecture fixtures and `frontend/.rules/11-security-privacy.md` with
  its enforcing tests, only to register the new feature and explicitly adopted prompt boundary
- `dev-plan/26-documentation/capabilities.md` (new verified matrix, dependency/licence decisions and fidelity limits)

### Contract

- `DocumentCapabilities` reports by format and platform: retain, inspect, extract text/tables/media, render and
  template fidelity. `supported`, `partial`, `onlineRequired`, `passwordRequired` and `unsupported` are distinct.
- A shared decoder interface returns typed blocks, source locators and warnings, never a success flag without
  usable content. A renderer capability describes the actual supported output structures and template features.
- Extend `DocumentPicker` with a backwards-compatible multi-file operation and bounded file metadata/stream access;
  preserve `pick` for package import and all existing callers. Domain models do not expose plugins or file handles.

### Steps

1. Run a capability probe against representative TXT/MD, text PDF, scanned PDF, DOCX, XLSX, CSV, JPEG/PNG, audio,
   video and ZIP fixtures on the supported runtime families. Record where extraction is local, proxy-assisted or
   unavailable. Include corrupt and password-protected samples; do not infer support from an extension.
2. Choose the smallest maintainable adapter set for PDF text/rendering, DOCX reading/writing, rich text editing,
   media inspection/extraction and multi-file picking. Reuse the existing archive, image and XLSX code where its
   fixture behaviour meets the contract. Pin approved new dependencies, record licences and replacement rationale,
   and add each to the allowlist in this task.
3. Implement thin adapter bridges and deterministic fakes. Text/Markdown, document headings/tables, spreadsheet
   sheets/cells, image OCR, bounded audio transcription and video audio/frames must have an explicit capability
   path. A missing native codec must report unsupported; it must never fabricate a transcript.
4. Prove basic editable DOCX and XLSX, paginated PDF, Markdown and CSV output viability. Prove a supported DOCX
   placeholder/table and XLSX header/row example can be filled without treating template examples as input facts.
   Record format-specific limits before later tasks use them.
5. Update the feature scaffold allowlist and FE-SEC-05 prompt-injection rule/fixtures for the deliberate Prompt
   role: explicitly adopted prompt-file text is user instruction, while input/format/archive content stays
   untrusted evidence. Preserve existing network, layering and raw-evidence boundaries; do not weaken them globally.

### Constraints

- No feature-specific SDK calls or duplicated file pickers (FE-STR-11, FE-CONS-01). No `dart:io` imports in a web
  path. Avoid loading entire videos, expanded archives or large spreadsheets into memory.
- No promise of pixel-identical Office/PDF reproduction, every media codec or arbitrary executable archive content.
- Do not enable macros, external links, remote HTML, document scripts or network retrieval while decoding.
- Adapter evaluation is not permission to add a server document store or conversion service. Conversion stays on
  device; provider-assisted extraction uses the existing governed proxy path when available in task 084.

### Definition of done

- [ ] The checked-in capability matrix matches executable fixture results for Android, desktop and web, including
      explicit limitations and the release formats in §84.
- [ ] Baseline media fixtures cover JPEG/PNG/WebP, WAV/MP3/M4A and a named tested MP4 codec profile with both
      timestamped audio and sampled visual evidence; platform limits are explicit.
- [ ] Added dependencies are pinned, allowlisted, licensed and wrapped; rejected/unused packages are not installed.
- [ ] Existing single-document selection still works; multi-selection supports cancellation, unreadable files and
      metadata inspection without reading unbounded content into memory.
- [ ] Adapter probes can read representative supported input and generate independently readable DOCX, XLSX, PDF,
      Markdown and CSV outputs; missing functionality fails with a typed capability reason.
- [ ] Tests cover malformed files, unsupported codec/platform, safe cancellation and a fake for every new platform
      interface; format-reader assertions inspect contents rather than only file extensions.

### Out of scope

Documentation database, workspace UI, archive expansion policy, production generation and release-ready renderers.
Those are the following tasks; this task establishes the usable adapter boundary they depend on.

## 081 — Persist Documentation workspaces and resources locally

**Depends on** [004](04-data-layer.md), [080](26-documentation.md)

### Implement

Add the durable project-scoped Documentation domain and persistence in §82. A workspace holds a title, selected
resource roles, optional prompt, output definitions, generation runs and immutable document versions. It must
survive process death before generation exists. Reuse project identity, attachments/blob storage, audit fields,
version vectors, tombstones and storage checks; do not create a second filesystem or pretend the workspace is a
capture record.

### Files

- `frontend/lib/features/documentation/documentation.dart` and layered `domain/`, `data/`, `presentation/`
- `frontend/lib/core/db/tables/` (new Documentation tables), `app_database.dart`, `migrations.dart`
- `frontend/lib/core/files/` (project-folder, attachment ownership and derivative paths as required)
- `frontend/lib/core/db/tables/attachments.dart`, `attachment_owners.dart`
- `frontend/lib/features/projects/` through its public repository contract for lifecycle integration
- `frontend/test/features/documentation/`, `frontend/test/core/db/`, migration fixtures

### Contract

- `DocumentationRepository` exposes project-scoped watch/create/update, resource registration and role selection,
  output-definition persistence, atomic run snapshots/checkpoints and immutable version writes through typed
  `Result` values. Publish only the contracts needed by subsequent tasks through the feature barrel.
- Workspace/resource/selection/output definition/run/document version are distinct identities. Resource content
  has an immutable hash, original name, detected MIME, bytes, attachment reference and extraction status. A
  selection assigns input, output-format or prompt role without duplicating the physical bytes.
  Native/project-archive source snapshots include origin project/entity/record/template identities and revisions,
  original attribution, evidence hashes, approval state and captured source policy; origin scope disambiguates
  identical display record numbers from different projects.
- Extracted derivatives record source hash, extractor version, page/paragraph/sheet/cell/time locators and warnings.
  A run snapshots selected resource hashes/versions, confirmed output definitions, canonical prompt, schema/parser
  versions and later model/settings metadata. A mutable workspace never changes an already queued run.
- A document version records its parent, canonical content, source/run links, validation findings, review state,
  creator/approver and output-file hashes. Review state is separate from a job's execution state.

### Steps

1. Define the model and an append-only schema migration from the current version, with foreign keys, project
   indexes and existing merge/audit columns. Prefer normalized entity tables and versioned JSON for rich blocks or
   definitions; do not use one unversioned settings blob for every domain entity.
2. Store originals through the existing attachment writer under the project's documentation paths; extracted
   content, run snapshots and output artifacts are distinct derivatives. Stage bytes, validate hash/size, commit
   metadata only once durable, and recover interrupted staging on startup.
3. Implement deterministic IDs, timestamps and repository fakes using injected existing services. Duplicate bytes
   may reuse storage, while filename, logical role and provenance remain separate. Replacing a resource creates a
   new revision and makes future use explicit; historical runs keep their original reference.
   Materialize the full selected native/archive dependency closure in the destination workspace's attachment
   store, including values, captions, meeting structure, template interpretation and chosen evidence bytes. Do not
   use only live foreign keys into another project. Preserve origin links as attribution, not storage ownership.
   Native project selections stay lightweight while editing; freeze/materialize their selected revisions and
   evidence when creating a run, before dispatch. Opening a new workspace does not copy every project record.
   Reopening a saved workspace preserves its exact stored scope and does not silently add current-project defaults.
4. Implement project archive/delete/restore and workspace/resource removal through existing lifecycle semantics.
   Removing a selection does not delete raw evidence. Permanent purge requires existing explicit retention rules
   and cannot remove bytes referenced by a retained run/version or another attachment owner.
5. Persist editor state incrementally and atomically; wire local repositories/providers in the existing composition
   root. Browser state uses existing durable blob storage and exposes quota/storage failures.

### Constraints

- Every confirmed write is local and durable. Storage exhaustion cannot leave a success state with missing bytes.
- `core/` may not depend on Documentation; other features access only its barrel (FE-STR-04, FE-STR-08).
- Sources and approved document versions are immutable. Human edits create a revision and keep earlier versions.
- No network upload, AI request or server content persistence occurs in this task.

### Definition of done

- [ ] Migration preserves existing projects, capture records, attachments and exports, and opens the new schema on
      native and web database implementations.
- [ ] Repository round trips reconstruct workspace, selections, prompt, definitions, run snapshots and revisions
      after closing and reopening storage.
- [ ] One source can have multiple explicit roles and owners without accidental physical duplication or deletion.
- [ ] Interrupted import/version writes recover safely; quota failure, missing blob and hash mismatch are visible
      typed failures and never confirmed as successful saves.
- [ ] Changing/removing a selected source leaves past run and approved-version provenance intact.
- [ ] A run combining several native projects and an imported project archive retains all selected snapshots and
      source policy/identity after the originating projects are edited, archived or deleted; equal display IDs
      cannot collide or cause citations to point at the wrong project.
- [ ] Tests cover transactions, source revision invalidation, duplicate content, concurrent saves, project
      archive/delete/restore and referenced-file retention with injected clock/IDs/file services.

## 082 — Import, inspect and extract document resources safely

**Depends on** [076](24-product-refinements.md), [081](26-documentation.md)

### Implement

Implement §77's multi-file import, inspection and source extraction on the device, using task 080's adapters and
task 081's durable resources. A user can select multiple files, retain their originals and see exactly which
content is usable. Each resource progresses independently: one corrupt, oversized or unsupported file does not
discard the successful imports. Add a resource preview and manual correction of extracted text beside its raw
source; corrected derivatives preserve both previous text and provenance.

### Files

- `frontend/lib/features/documentation/domain/` (import/extraction states, source blocks, locators and limits)
- `frontend/lib/features/documentation/data/` (resource importer, extractors, local index and snapshots)
- `frontend/lib/features/documentation/presentation/` (resource list, progress, preview and warnings)
- `frontend/lib/core/documents/`, `frontend/lib/core/files/` (reusable bounded archive inspection)
- Public record/meeting selection contracts in `frontend/lib/features/records/` and `meetings/` where needed
- `frontend/test/features/documentation/`, `frontend/test/core/documents/`, malicious archive fixtures

### Contract

- `ResourceImporter` accepts picked resources and produces per-file retained/import-failed outcomes, before any
  optional extraction. Filename and MIME are display metadata; content sniffing and validated adapters decide use.
- `ResourceExtractor` emits normalized blocks with stable source locators, capability/warning status, coverage
  and extractor version. OCR text, transcripts and operator corrections remain separate from immutable originals.
- A local searchable chunk index references resource revisions and locators. It supplies bounded excerpts for
  generation and never requires a remote file index or provider vector store.
- A project-archive source adapter reuses bundle manifest/version/hash validation and typed readers but exposes a
  selection preview, never the project importer/merge mutation. It reconstructs captured values, template meaning,
  meeting content and evidence in isolated staging, then materializes only the chosen dependency closure locally.

### Steps

1. Multi-select files and copy them durably before confirmation. Show filename, role, size, type and progress;
   handle cancellation, corrupt files, duplicate hashes and same-name/different-content inputs distinctly.
2. Implement the declared matrix: TXT/MD text; DOCX paragraphs/headings/tables; PDF page text with OCR for scanned
   pages where available; XLSX sheets/header/cell ranges and CSV rows; images through available OCR/vision; audio
   through transcription; video through bounded audio/frame extraction. Make online-required work wait visibly
   until task 084 supplies the governed adapter. Arbitrary formats remain retained and unsupported.
3. For ZIP, inspect first and let the user choose entries; members inherit the explicitly chosen import role, with
   later reassignment only through user action. A `prompt.md` member is not automatically an instruction. Resource
   ZIP import never runs project-bundle merge, even if it finds a Tapture manifest. Retain the original archive and parent
   links. Reject absolute/traversal paths, symlinks, overlapping/duplicate normalized paths, disguised executables,
   excessive entry counts, compression ratios and expanded bytes. Do not auto-expand nested archives. Encrypted
   archives require explicit unlocking support or remain unsupported; never treat failure as an empty success.
4. Enforce the proposed initial import limits in §77.3: 250 MB/file, 100 files/batch, 1,000 enumerated ZIP entries,
   100 selected expansions, 500 MB actual expanded bytes/archive and 100:1 maximum per-entry/aggregate compression
   ratio, with no automatic nested expansion. Check streamed bytes, not just advertised sizes. Reject an unsafe
   archive before committing any child resources; a failed safe member leaves the other valid selections visible.
   Add separate bounded page, row, duration, frame and chunk limits through centralized configurable constants.
   Defaults and supported platform exceptions must be recorded alongside the capability matrix.
   Extraction supports cancellation, checkpoint/retry and background/isolate work without blocking capture.
5. Add explicit selection from one or several existing captured projects through public feature APIs: project
   selection, then context/date/template/status filters and record/meeting/attachment preview. Default to approved
   content; unreviewed records require an explicit inclusion choice and remain flagged. Snapshot chosen values,
   evidence, template meaning, origin IDs/revisions and source privacy constraints; later source edits flag staleness
   but never change a queued run, and deleting the originating project cannot orphan materialized evidence.
   Add **Project archive** beside native projects and loose files. For a recognized Tapture package, validate its
   manifest, version, checksums and relationships before previewing typed captured content. Stage without registering
   a live project or merging records. Reject corrupt/unsupported recognized schemas for typed source reading; an
   unrecognized ZIP uses generic member selection with an explicit warning that captured structure was not read.
   An explicitly selected external archive is an uploaded input under destination import permission; its origin
   project need not exist on the backend. Retain restrictive embedded policy where present, but never treat archive
   metadata as a membership grant, a new approval or authority to loosen restrictions. No classification wizard.
6. Index extracted text locally, preserving table/section boundaries and locations. Record coverage per source:
   read, partially read, waiting online, password required, failed or unsupported. Never silently truncate.

### Constraints

- Extraction is data interpretation, never instruction execution. Ignore document scripts, macros, remote includes
  and embedded instructions to run code, visit links or upload files (FE-SEC-05).
- Imported bytes and text never leave the device merely because files were attached. Provider OCR/transcription
  must use the same explicit egress controls as generation. The Do not send images setting covers original images,
  scanned-PDF renders and video frames; video must show which audio/time ranges and frames were actually read.
- ZIP security checks apply to OOXML container reading as well as user archives. A `.docx` suffix is not trust.
- Unsupported mandatory sources block a complete generation until the user repairs, replaces or explicitly
  excludes them; exclusion and partial coverage are recorded for the run.

### Definition of done

- [ ] Mixed-file import preserves all accepted originals and displays independent, truthful extraction outcomes.
- [ ] Fixture tests verify PDF page, DOCX paragraph/table, XLSX sheet/cell, CSV row and media timestamp/frame
      locators; an empty extraction cannot become a ready input.
- [ ] Archive fixtures cover traversal, absolute paths, symlinks, duplicate names, corrupt/encrypted/nested ZIP,
      entry-count and expansion-ratio/size limits, with no writes outside the selected project staging directory.
- [ ] Reimporting unchanged bytes reuses cached extraction by hash and parser version; a source revision or parser
      change invalidates that derivative without altering the original.
- [ ] Offline and unsupported-platform cases stay visible and resumable; restart, cancel and retry preserve
      completed files and partial extraction coverage.
- [ ] One selection combines projects A and B, project archive C and loose files with distinguishable origin IDs,
      approved-content defaults, explicit unreviewed inclusion and no unselected content in the index/payload.
- [ ] Archive-source tests cover valid captured evidence, missing dependencies, bad hashes, unsupported versions
      and generic ZIP fallback; neither preview nor extraction registers a project, merges records or dispatches AI.
- [ ] Tests exercise large bounded inputs, low storage, retained unsupported files and responsive import progress.

## 083 — Build the Inputs, Outputs and Prompt workspace

**Depends on** [079](24-product-refinements.md), [082](26-documentation.md)

### Implement

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

### Files

- `frontend/lib/features/documentation/domain/` (output definition, structure, mapping and prompt models)
- `frontend/lib/features/documentation/data/` (template inspection and prompt-file normalization)
- `frontend/lib/features/documentation/presentation/` (workspace/list, output editor and preview)
- `frontend/lib/core/widgets/` (shared rich text editor and reusable resource/output rows where needed)
- `frontend/lib/core/copy/`, shared widget gallery and themes/tokens only where existing tokens are insufficient
- `frontend/lib/app/router.dart`, shell navigation/More destinations, project-home entry points
- `frontend/test/features/documentation/`, `frontend/test/core/widgets/`, `frontend/test/app/`

### Contract

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

### Steps

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

### Constraints

- Square components and zero-radius menus follow existing design tokens. No one-off rounded cards or custom form
  controls (FE-CONS-01, FE-CONS-02). Responsive layout changes preserve input, route and selected output.
- User-editable instructions cannot override grounding, request extra unselected files or trigger external actions.
- XLSX record-capture templates and Documentation output definitions are distinct concepts; reuse parsing/writing
  primitives without mutating the project's capture schema.
- Opening Documentation, importing files or saving a draft never sends an AI request.
- Readiness requires at least one readable source of any supported kind, never specifically a captured project.
  Removing a default is durable; reopening or generating must not reinsert that project selection.
  An empty default project is visibly empty and cannot block a valid uploaded-source workflow.

### Definition of done

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

## 084 — Generate grounded document drafts through resumable jobs

**Depends on** [024](23-backend.md), [083](26-documentation.md)

### Implement

Make **Create documents** run the §80 pipeline: snapshot, prepare sources, draft against confirmed definitions,
validate and leave evidence-backed canonical drafts for local rendering/review. Persist the work on the device
before making any network call. The backend is a request-lifetime AI proxy; it does not own workspaces, documents,
file uploads, vector stores or background generation jobs.

Close the current production integration gaps explicitly. `AiService` has no document operation; its current proxy
request shape does not match the backend envelope; startup uses a keyless registry. A fake returning prose is not
an implementation of this feature. Wire authenticated production transport and a configured provider, with clear
capability and recovery states where unavailable. Reuse existing auth, quotas, cost controls, egress consent,
redaction and provider resilience rather than building parallel versions.

### Files

- `frontend/lib/features/documentation/domain/` and `data/` (run orchestration, grounding and validation)
- `frontend/lib/features/documentation/presentation/` (generation controller, egress preview and run status)
- `frontend/lib/core/ai/`, `frontend/lib/core/concurrency/`, `frontend/lib/main.dart`
- Existing processing primitives under `frontend/lib/features/processing/`, promoted to `core/` only when shared
- `backend/openapi.yaml`, `backend/src/routes/ai.ts`, `backend/src/services/ai/`, provider wiring/dependencies
- `frontend/test/features/documentation/`, `frontend/test/core/ai/`, record-processing regression suites
- `backend/test/routes/ai_proxy.test.ts`, provider/service and frontend/backend contract fixtures

### Contract

- Extend the AI abstraction with a typed document composition operation. Publish `POST /api/v1/ai/compose`
  (specification shorthand `/ai/compose`) in OpenAPI with a versioned request/response schema. Reuse the project's
  authentication and permission checks, model selection, request limits, quota and usage accounting.
- A composition request includes project/run/output/attempt IDs, schema version, bounded selected evidence blocks
  with source locators, confirmed output structure, normalized instructions and generation settings. Content and
  instructions are separate structured fields. It contains no local absolute paths or unselected project data.
- A response is validated canonical content: sections/tables/cells, claim/field source references, unresolved
  requirements, conflicts and coverage; include provider/model and usage metadata. AI returns structured data,
  never scripts, executable formulas, arbitrary file paths or trusted final binary documents.
- Persist run states **Queued**, **Running**, **Paused**, **Needs review**, **Partially complete**, **Failed** and
  **Cancelled**, with a typed pause/failure reason. Separate stage checkpoints describe preparing/reading/
  generating/validating/rendering, and each output keeps its own result. Task 085 owns rendering and document
  approval states. Required-input failures cannot be disguised as a successful complete run.

### Steps

1. Extract minimal reusable lease, bounded retry, cancellation and connectivity primitives from record processing.
   Keep existing `ProcessingJob`/`JobQueue` APIs backward compatible; Documentation runs are project/workspace jobs,
   never fake capture records. Add durable `documentation_jobs` owned by run/output with explicit stage/lease and
   attempt state; share runner primitives without invasively generalizing record queue tables. Persist checkpoints
   and immutable selections before scheduling.
2. Assemble the source context locally using task 082's chunks and locators. Apply explicit size/token budgets;
   when sources exceed one request, split by section/source and retain coverage across bounded summarization and
   synthesis. Retained summaries cite their original chunks. Show omitted/partial material; no silent truncation.
3. Present the selected provider/model, sources/excerpts or media to leave the device, purpose and available cost
   estimate under existing egress controls. Respect offline-by-choice, project AI disable, connection/metered
   rules, membership and cached-session expiry. Changed source selection requires refreshed preview/consent.
   Check the destination and every originating project's captured source restrictions; apply the strictest AI,
   no-image, connection and permission policy to each selected source. Destination approval cannot override a
   source project's no-AI/no-image rule. Show blocked sources with a repair/exclusion path and evaluate cached
   permissions explicitly; a snapshot's relocation is not new permission to send its bytes.
   Organisation project selections require actual accessible source membership. External archives instead use
   destination import/generation permission and disclosed sending consent, retaining known restrictive metadata;
   do not require an archive's origin project to be registered on the backend or infer privileges from its manifest.
4. Implement the real compose transport and provider adapter. Keep request bodies/transcripts/templates out of
   logs, databases, caches and error telemetry on the backend. Add capability negotiation for older servers; an
   absent compose route yields a recoverable unavailable state. Existing extraction/OCR/transcription/refinement
   calls continue to pass contract tests through the corrected transport.
5. Validate provider output against the definition and supplied source IDs/locations. Detect missing required
   content, invalid data types, unsupported citations, source contradictions and unsupported assertions. Never
   treat an AI confidence score as proof. Represent unknown values and gaps explicitly, with repair/edit paths.
   Allow at most one bounded schema-repair call per response; failed repair is a visible failure, not a blank success.
6. Add per-output progress, cancel and retry; successful outputs survive another output's failure. Restart makes
   interrupted jobs paused/retryable from durable checkpoints. Connectivity alone never dispatches Documentation
   AI: the user explicitly resumes queued offline work. Local run/attempt IDs prevent duplicate revision commits.
   An uncertain provider timeout is shown as potentially charged and requires explicit retry; do not promise
   exactly-once remote billing. Reject late responses from cancelled or superseded attempts.
7. Complete the production wiring used by the module, including proxy-assisted OCR/transcription where task 082
   declared it. Verify a configured staging provider end to end with non-sensitive fixtures and keep deterministic
   tests for offline CI; document missing configuration honestly instead of marking that acceptance complete.

### Constraints

- Source documents and format files are untrusted data (FE-SEC-05); embedded instructions cannot override system
  grounding, select more sources, request secrets, browse or upload. Explicit prompt text still cannot override
  product safety/grounding rules or confirmed output constraints.
- No persistent project-content schema, raw body logs, provider file store or remote asynchronous job is added.
  Metadata-only request receipts may track IDs/status/usage; they must not retain generated text or input payloads.
- A network outage never blocks capture, editing, review or local rendering of an existing draft.
- No AI output becomes approved automatically. A completed run produces a draft only.

### Definition of done

- [ ] Real authenticated app-to-backend-to-provider generation returns a structured evidence-linked draft, with
      provider/model/usage shown and no provider key on the device.
- [ ] Shared request/response fixtures pass frontend/backend contract tests, including old-server capability
      absence, malformed output and corrected transport for existing AI operations.
- [ ] Offline preparation and queueing survive restart; reconnection alone makes no provider call, and explicit
      resume respects auth expiry, budget, metered policy and prior consent. Cancellation and bounded retries
      preserve work, reject stale late results and expose an actionable status.
- [ ] Multi-output partial success and an ambiguous timeout never overwrite completed work or create duplicate
      committed versions; usage remains attributable per attempt/output/run.
- [ ] Grounding tests reject invented source IDs and unsupported required claims; contradictory inputs, missing
      values, context-limit truncation and partial extraction remain explicit findings.
- [ ] Adversarial fixture instructions in source/template content cannot trigger external actions, hidden-source
      selection or transmission of credentials/unselected content.
- [ ] Mixed-project/native/archive payloads preserve origin-scoped citations and strictest source/destination
      privacy; a destination that permits AI cannot send a source whose policy forbids it, including derived images.
- [ ] Backend retention/logging tests prove no request content, prompt, template or generated text remains after
      success, cancellation, timeout and error paths; quota/auth checks happen before provider calls.
- [ ] Existing record processing/capture tests pass after any promotion of shared queue or AI primitives.

## 085 — Render, review and approve versioned documents

**Depends on** [084](26-documentation.md)

### Implement

Turn the canonical draft into locally generated files, then make review, correction and approval meaningful
(§§78, 81). A single canonical content model feeds editable DOCX/XLSX and PDF/Markdown/CSV adapters where
applicable. AI does not write the binary file. Each output has its own preview, validation findings, evidence,
versions and approval state; one failed renderer does not invalidate another successfully generated document.

Use task 080's format adapters and existing export writers. Extend the reusable renderers where required: current
PDF text output is not sufficient for a multi-page report with tables/images, and DOCX must be an editable Office
document. Renderers use deterministic layout/content decisions for the same canonical revision, template, settings
and renderer version. Preserve supported template features and explain unsupported fidelity explicitly.

### Files

- `frontend/lib/features/documentation/domain/` (canonical document, validation, version/review rules)
- `frontend/lib/features/documentation/data/` (render orchestration, artifact writes and version repository)
- `frontend/lib/features/documentation/presentation/` (preview, evidence, editing and history)
- `frontend/lib/core/documents/`, `frontend/lib/core/export/` (shared DOCX/PDF/XLSX/CSV/Markdown adapters)
- Existing share/download and project export surfaces through public contracts
- `frontend/test/features/documentation/`, `frontend/test/core/export/`, representative document fixtures

### Contract

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

### Steps

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

### Constraints

- Every file is created on the device. Offline rerender/edit/approve/export of a saved draft remains possible.
- Preserve original format resources and all previous versions. An approved binary is not mutated in place.
- A citation verifies that an evidence reference exists, not that a claim is true; review must show the source.
- Unsupported template constructs are blocked or visibly accepted as recreation limits, never silently lost.
- No new feature-specific share sheet, error widget, rich text editor or form control (FE-CONS-01).

### Definition of done

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

## 086 — Carry Documentation in project packages and pass release acceptance

**Depends on** [019](19-bundles-and-merge.md), [025](25-testing-and-release.md), [076](24-product-refinements.md), [085](26-documentation.md)

### Implement

Complete the portability, lifecycle and release boundary in §§82–84. A full project package carries retained
Documentation resources, source/provenance snapshots, workspace configuration, output definitions, prompts and
document versions alongside the project's existing data. Import reconstructs the workspace locally with no server.
Bundle inspection, hashes, version compatibility, merge preview, conflicts and undo stay the existing mechanism.
Then pass the complete user workflows on Android, desktop and web against the capability matrix.

### Files

- `frontend/lib/core/bundle/` (format version, tables, manifest, safe reader/writer and redaction)
- `frontend/lib/features/merge/`, package import and project lifecycle public contracts
- `frontend/lib/features/documentation/` (portable snapshots, merge rules and history/source health)
- `frontend/test/core/bundle/`, `frontend/test/features/merge/`, package import and migration fixtures
- `frontend/integration_test/`, `backend/test/`, relevant release verification/run tooling
- `dev-plan/26-documentation/capabilities.md`, release/operator documentation and §84 traceability

### Contract

- Bump the bundle format/schema deliberately. Documentation table/artifact entries identify their schema versions,
  owners, hashes, sizes and referenced revisions in the existing manifest. Older app compatibility is explicit:
  refuse an unsupported bundle with a recoverable explanation rather than silently dropping documents.
- Completed runs and immutable document versions travel as history. In-flight leases, machine paths, cached auth,
  provider keys and active network attempts do not travel. Imported draft work is inert and can be resumed only
  as an explicit new local run after readiness and egress checks.
- Workspace/configuration edits use existing merge vectors and conflict review. Immutable resource/version hashes
  deduplicate safely; independent versions form branches, never an automatic winner. Approval applies to the exact
  approved revision and is not transferred to a merged or edited revision.

### Steps

1. Extend bundle table/file collection, manifest validation, scope/redaction preview and package reader/writer
   for Documentation. Reuse byte hashing and storage; verify all transitive source/template/prompt/version
   references. A partial/redacted package clearly reports missing provenance instead of claiming reproducibility.
2. Integrate explicit merge, conflict resolution and undo. Restoring a project restores workspaces and their retained
   originals. Audit parent/version/source links survive export/import. Deletion follows existing tombstone and
   retention rules; pending work cannot restart automatically after a bundle is imported.
3. Add end-to-end fixtures for the five common workflows: ToR/company profile/meeting files to DOCX+PDF report;
   XLSX headers with typed required columns; mixed media/archive evidence; several outputs and an optional prompt
   file plus rich instructions; offline preparation followed by online generation and offline review/export.
   First verify the default path: current-project approved capture data to a report with zero file uploads and no
   prompt, visible source counts and an editable saved scope. Include no-eligible-record and upload-only paths.
   Include a single run combining native projects A and B, uploaded project archive C and loose documents/media.
   Give projects A/B identical display record numbers and different privacy settings, then edit/delete an origin
   and prove retained snapshots, attribution, filtered selection and policy enforcement remain correct.
4. Exercise failure workflows: unsupported/corrupt/encrypted source, partial OCR or transcript, unsafe ZIP, missing
   required information, contradictory sources, inaccessible backend, old server, exhausted quota, expired session,
   timeout with uncertain billing, cancellation/restart, render failure, missing blob and full storage.
5. Verify device/platform capabilities and resource budgets with documented reference fixtures. Import/extraction
   and generation queues must keep capture responsive; large videos/archives/workbooks must stay within bounded
   memory/storage limits. Web quota/codec limitations are visible, never silent data loss.
6. Run accessibility and UI consistency checks at narrow/medium/expanded widths, 200 percent text, keyboard and
   screen reader, light/dark/outdoor themes. More opens the menu, Documentation resumes project context, and changes
   in width do not lose edits, progress or selection.
7. Run the app/backend gates and record exact capability results, limits and any intentionally deferred formats.
   No unchecked task or failed acceptance is hidden by the general release checklist. Update phase acceptance
   tracking only from evidence, and leave unrelated existing backlog tasks open.

### Constraints

- A project ZIP is the user-controlled backup; the backend gains no document persistence, automatic upload or
  backup responsibilities. Cloud sharing is an explicit use of existing export/upload services.
- The optional encrypted relay may carry the same versioned bundle content only under existing project permission
  and retention controls. Relay support must not make document generation depend on a server copy.
- Packaging unsupported files preserves their bytes and unsupported status; import does not mark them read.
- Source caches may be rebuilt, but originals, prompts, approved versions and provenance cannot be omitted from
  a package labelled complete.

### Definition of done

- [ ] A complete package round trip onto a clean offline device reconstructs inputs, roles, definitions, prompt,
      source links, canonical revisions, approved files and history with matching hashes.
- [ ] Multi-project/archive source snapshots and their full chosen evidence dependency closure survive bundle
      round trip without creating/merging live origin projects; origin-scoped IDs and source policy are preserved.
- [ ] Bundle tests cover mixed old/new versions, missing/corrupt resources, duplicate files, redacted/partial scope,
      concurrent workspace edits, independent document versions, merge preview/undo and deletion/restoration.
- [ ] No active job, secret, credential or local absolute path travels in a package; importing never calls AI.
- [ ] End-to-end report and spreadsheet scenarios in §84 pass with documented fidelity and valid independently read
      artifacts; multiple outputs preserve successful results when another fails.
- [ ] The default-project, zero-upload/no-prompt workflow passes; a saved workspace retains its exact selection,
      and source snapshots are materialized at run creation without copying all records on screen open.
- [ ] Captured projects remain optional: removing all project sources permits files-only and archive-only runs;
      saving/reopening preserves removal and readiness never demands a captured project.
- [ ] Offline/restart/limits/unsafe-input failures preserve local work and expose recovery; source coverage and
      unresolved requirements remain visible through review/export.
- [ ] Android, desktop and web capability results are recorded, including codec/storage/platform limitations and
      bounded performance fixtures; capture stays responsive during large-file work.
- [ ] Accessibility and responsive navigation acceptance pass, including More, no-project routing and draft-state
      preservation at all supported widths.
- [ ] Release checks include metadata-only backend logs/retention, key custody, role/quota enforcement and evidence
      that no server document store or durable provider payload was introduced.
- [ ] `dart run tool/check_plan.dart`, the frontend standard gate and `npm run verify` pass; the step file and
      capability matrix identify all remaining unsupported/deferred behaviour accurately.
