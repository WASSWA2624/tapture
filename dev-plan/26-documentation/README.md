# 26 — Documentation

Turn captured project data into reviewed documents through one local workspace: Inputs, Outputs and an optional
Prompt. New workspaces default to the current project's approved records with visible scope/counts; files and
project archives are optional supplementary sources, and upload-only work remains possible by explicitly
deselecting project sources. Specification [Part XII, §§76–84](../../app-write-up.md) owns the product behaviour.

Tasks 080–086 (7). All Documentation implementation remains planned; writing this plan does not complete a task.

## Build order

The task list below is sequential. Task 079 delivers the mobile More menu independently; task 083 connects the
Documentation destination when the workspace exists. Each task ships its own tests and uses [STANDARD.md](../STANDARD.md).

- [ ] [080 — Establish document adapters and approved dependencies](080-documentation-capabilities.md)
- [ ] [081 — Persist Documentation workspaces and resources locally](081-documentation-workspaces.md)
- [ ] [082 — Import, inspect and extract document resources safely](082-documentation-ingestion.md)
- [ ] [083 — Build the Inputs, Outputs and Prompt workspace](083-documentation-editor.md)
- [ ] [084 — Generate grounded document drafts through resumable jobs](084-documentation-generation.md)
- [ ] [085 — Render, review and approve versioned documents](085-documentation-review.md)
- [ ] [086 — Carry Documentation in project packages and pass release acceptance](086-documentation-release.md)

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

Task 013 is still open. Task 024 is marked complete, but that does not prove end-to-end document AI is wired:
`main.dart` uses a keyless provider registry, the current `ProxyAiService` emits metadata counts rather than the
backend's `projectId`/`model`/`payload` envelope, and neither AI interface exposes generation. Task 084 must close
the gaps required for this module and verify the real path. It must not mark unrelated task 013 work complete.
`ProcessingJob` and its queue are record-scoped today; shared primitives must be extracted without breaking those
contracts. The existing `PdfEngine` emits a single text stream, so document pagination and embedded images cannot
be assumed. DOCX support and a rich text editor are not present in the current dependency list. Task 080 is the
dedicated dependency/capability task required by FE-FLOW-06; subsequent tasks implement the module against it.

## Delivery boundaries

- The first useful slice accepts and retains files, extracts supported content and preserves a resumable local
  workspace. Unsupported files stay visible with an explanation; attaching a file is not evidence that AI read it.
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

Task 086 runs the workflows in §84: a narrative report from mixed documents and media, an XLSX template with
required headers, multiple outputs from one source set, partial and unsupported extraction, offline preparation,
restart/retry, safe ZIP handling, provenance and human approval, and bundle round trips. The release gate includes
Android, desktop and web capabilities, accessibility, resource limits and metadata-only backend logging.
Each task's Definition of done carries the specific assertions, fixtures and regression coverage.
The source acceptance includes a combined run from projects A and B, a project archive C and loose documents,
with provenance and privacy preserved after an originating project is edited or deleted.
The shortest acceptance path starts with the current captured project and creates a document without uploading
any file or entering a prompt. Existing workspaces retain their saved selections instead of adding fresh defaults.
