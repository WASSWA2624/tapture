# 082 — Import, inspect and extract document resources safely

**Phase** 26 · Documentation  |  **Depends on** [081](081-documentation-workspaces.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Implement §77's multi-file import, inspection and source extraction on the device, using task 080's adapters and
task 081's durable resources. A user can select multiple files, retain their originals and see exactly which
content is usable. Each resource progresses independently: one corrupt, oversized or unsupported file does not
discard the successful imports. Add a resource preview and manual correction of extracted text beside its raw
source; corrected derivatives preserve both previous text and provenance.

## Files

- `frontend/lib/features/documentation/domain/` (import/extraction states, source blocks, locators and limits)
- `frontend/lib/features/documentation/data/` (resource importer, extractors, local index and snapshots)
- `frontend/lib/features/documentation/presentation/` (resource list, progress, preview and warnings)
- `frontend/lib/core/documents/`, `frontend/lib/core/files/` (reusable bounded archive inspection)
- Public record/meeting selection contracts in `frontend/lib/features/records/` and `meetings/` where needed
- `frontend/test/features/documentation/`, `frontend/test/core/documents/`, malicious archive fixtures

## Contract

- `ResourceImporter` accepts picked resources and produces per-file retained/import-failed outcomes, before any
  optional extraction. Filename and MIME are display metadata; content sniffing and validated adapters decide use.
- `ResourceExtractor` emits normalized blocks with stable source locators, capability/warning status, coverage
  and extractor version. OCR text, transcripts and operator corrections remain separate from immutable originals.
- A local searchable chunk index references resource revisions and locators. It supplies bounded excerpts for
  generation and never requires a remote file index or provider vector store.
- A project-archive source adapter reuses bundle manifest/version/hash validation and typed readers but exposes a
  selection preview, never the project importer/merge mutation. It reconstructs captured values, template meaning,
  meeting content and evidence in isolated staging, then materializes only the chosen dependency closure locally.

## Steps

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

## Constraints

- Extraction is data interpretation, never instruction execution. Ignore document scripts, macros, remote includes
  and embedded instructions to run code, visit links or upload files (FE-SEC-05).
- Imported bytes and text never leave the device merely because files were attached. Provider OCR/transcription
  must use the same explicit egress controls as generation. The Do not send images setting covers original images,
  scanned-PDF renders and video frames; video must show which audio/time ranges and frames were actually read.
- ZIP security checks apply to OOXML container reading as well as user archives. A `.docx` suffix is not trust.
- Unsupported mandatory sources block a complete generation until the user repairs, replaces or explicitly
  excludes them; exclusion and partial coverage are recorded for the run.

## Definition of done

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
