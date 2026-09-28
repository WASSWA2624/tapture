# 26 — Documentation

Turn captured project data into reviewed documents through one local workspace: Inputs, Outputs and an optional
Prompt. New workspaces preselect the current project's approved records with visible scope/counts, purely for
convenience. **Captured projects are never required inputs.** Users can clear the project selection and use only
uploaded files or project archives, or combine any of these sources. Specification
[Part XII, §§76–84](../../app-write-up.md) owns the product behaviour.

## Build order

The task list below is sequential. Task 079 delivers the mobile More menu independently; task 083 connects the
Documentation destination when the workspace exists. Each task ships its own tests and uses [STANDARD.md](../STANDARD.md).

<!-- dev-plan:generated:start -->

## Implementation progress

**Step 26 — Pending**

7 total · 0 Complete · 0 Partially complete · 7 Pending. Status is generated from each task’s Definition of done; follow sub-step order below.

| Sub-step | Task ID | File / implementation | Status | Done | Dependencies / readiness |
| --- | --- | --- | --- | ---: | --- |
| 26.01 | 080 | [Establish document adapters and approved dependencies](080-documentation-capabilities.md) | **Pending** | 0/6 | 05.01 (005), 18.01 (018); Waiting for: 018 |
| 26.02 | 081 | [Persist Documentation workspaces and resources locally](081-documentation-workspaces.md) | **Pending** | 0/7 | 04.01 (004), 26.01 (080); Waiting for: 080 |
| 26.03 | 082 | [Import, inspect and extract document resources safely](082-documentation-ingestion.md) | **Pending** | 0/8 | 24.51 (076), 26.02 (081); Waiting for: 081 |
| 26.04 | 083 | [Build the Inputs, Outputs and Prompt workspace](083-documentation-editor.md) | **Pending** | 0/10 | 24.54 (079), 26.03 (082); Waiting for: 079, 082 |
| 26.05 | 084 | [Generate grounded document drafts through resumable jobs](084-documentation-generation.md) | **Pending** | 0/9 | 23.01 (024), 26.04 (083); Waiting for: 024, 083 |
| 26.06 | 085 | [Render, review and approve versioned documents](085-documentation-review.md) | **Pending** | 0/8 | 26.05 (084); Waiting for: 084 |
| 26.07 | 086 | [Carry Documentation in project packages and pass release acceptance](086-documentation-release.md) | **Pending** | 0/12 | 19.01 (019), 25.01 (025), 24.51 (076), 26.06 (085); Waiting for: 025, 085 |

<!-- dev-plan:generated:end -->

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

This module's acceptance precedes [final whole-app hardening](../27-hardening/README.md). A successful module run
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
