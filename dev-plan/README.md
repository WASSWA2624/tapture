# Tapture — development plan

The numbered folders define the implementation flow: foundation, app features, backend, product refinements,
release infrastructure, Documentation, then final hardening. [INDEX.md](INDEX.md) lists every file in that order;
[dev-tracker.md](../dev-tracker.md) shows progress at both folder and file level.

Every task inherits [STANDARD.md](STANDARD.md). Read that once, then open the index's next actionable substep.
Finish its declared prerequisites first. A task repeats only what is specific to it; the rules live in `frontend/.rules/` and
`backend/.rules/`.

Each folder is a **step**; its files are **substeps**, numbered `PP.SS` in the index, tracker, folder README and task
metadata. For example, `24.54` is an execution position, while `079` is a stable task ID. Task IDs are retained for
code comments, commits and historical decisions; they are not the execution order. Follow folder/substep order,
not a global sort of task IDs. [RETIRED.md](RETIRED.md) records retired IDs, which are never reused.

Recorded completion describes the task's acceptance criteria; it does not establish later module integration or
erase open prerequisites. Documentation's [readiness assessment](26-documentation/README.md) identifies its AI,
format and source-ingestion gaps. Captured projects are its default inputs for convenience, never required inputs.

```text
tapture/
├── frontend/           Flutter app, plus 13 rule files
├── backend/            required minimal server (specification Part XI), plus 11 rule files
├── dev-plan/           this plan, plus RETIRED.md
├── run-tools/          run locally; build the APK, web bundle and backend archive
└── app-write-up.md     the specification
```

Paths in a task are written in full (`frontend/lib/...`, `backend/src/...`).

## How to use a task file

```text
# 014 — Records: find, read and change what was captured

**Phase** 14 · Records  |  **Depends on** [012](...)  |  **Standard** [STANDARD.md](../STANDARD.md)

**Implementation step:** 14.01

## Implement           what exists when this is finished
## Files               what to create or change
## Contract            public API other tasks will call (omit if none)
## Steps               order of work, only when it is not obvious
## Constraints         rules that bite harder here than STANDARD.md already requires
## Definition of done  the checklist, including the tests
## Out of scope        a named temptation, only when one exists
```

`check_plan.dart` requires **Implement**, **Files** and a tickable **Definition of done**. The other sections are
optional and must be omitted when empty.

One task, one file. IDs are globally unique; dependencies point to earlier execution positions. Never widen a task —
`dart run tool/new_task.dart` opens a new one instead (FE-FLOW-04). A phase task is worked in its Steps order and
lands as a series of pull requests, one per step group, rather than one enormous change.

## Phases

| | Phase | Tasks | What it delivers |
|---|---|---|---|
| 01 | [Project setup and guardrails](01-orchestration/) | 001, 087 | Repository rules, tooling and automatically maintained progress |
| 02 | [Foundation services](02-foundation/) | 002 | Boots, logs, fails safely; the services everything injects |
| 03 | [Design system](03-design-system/) | 003 | Tokens, themes and the whole widget vocabulary, before any screen |
| 04 | [Local database](04-data-layer/) | 004 | Every table, with merge columns from the first migration |
| 05 | [File storage](05-file-storage/) | 005 | The organised folder tree and every service that writes into it |
| 06 | [Application shell](06-app-shell/) | 006 | Navigation, routing and status line |
| 07 | [Account and settings](07-account-and-settings/) | 007 | Local identity that later becomes an account, app lock, and the switches later features read |
| 08 | [Projects](08-projects/) | 008 | The container that owns everything else |
| 09 | [Templates](09-templates/) | 009 | Record shapes with atomic columns, and requiredness the user owns |
| 10 | [Reference data](10-reference-data/) | 010 | Imported tables, lookups and prefill |
| 11 | [Context](11-context/) | 011 | Set a value once; it applies until changed |
| 12 | [Capture](12-capture/) | 012 | Evidence in, with as little typing as possible |
| 13 | [Processing](13-processing/) | 013 | On-device first, online only when it earns its place |
| 14 | [Records](14-records/) | 014 | Find, read and change what was captured |
| 15 | [Data quality](15-data-quality/) | 015 | Validation, duplicates, conflicts and verification |
| 16 | [Review](16-review/) | 016 | Where a person turns proposals into data |
| 17 | [Meetings](17-meetings/) | 017 | Minutes, attendance and actions |
| 18 | [Export](18-export/) | 018 | XLSX, CSV, JSON, PDF and ZIP, all produced on device |
| 19 | [Bundles and merge](19-bundles-and-merge/) | 019 | Collaboration that never touches the backend |
| 20 | [Data import](20-data-import/) | 020 | Continue an inventory someone else started |
| 21 | [Cloud upload](21-cloud-upload/) | 021 | A destination for files, never a sync channel |
| 22 | [Privacy and security](22-privacy-and-security/) | 022 | What leaves the device, and what never does |
| 23 | [The minimal backend](23-backend/) | 024 | **Required** — accounts, auth, roles, AI functionality and key custody, plus the optional relay |
| 24 | [Product refinements](24-product-refinements/) | 026–079 | Field feedback, project packages, capture and UI refinements, including the mobile More menu |
| 25 | [Testing and release](25-testing-and-release/) | 025 | Baseline suites, pipeline and gate infrastructure over both artefacts |
| 26 | [Documentation](26-documentation/) | 080–086 | Selected resources and output definitions to reviewed, versioned documents |
| 27 | [Hardening](27-hardening/) | 023 | Final whole-product performance, accessibility, resilience and release verification |

The backend is required to exist (§70) and is built after the app because almost all of it depends on the app existing
first. The app-side steps of task 024 turn the local operator profile into an account and server-held key custody. The
change relay (§72) is the one optional slice inside that task: its relay schema, push, acknowledgement, purge job and
client. An organisation that never switches it on has a complete product. Phase 25 builds the release infrastructure;
phase 26 extends it with Documentation acceptance. Shipping requires those checks and the final phase 27 hardening
pass over the integrated product. Hardening remains the last numbered folder.

## Progress and automatic updates

The task's **Definition of done** is the source of truth. Check only verified criteria. If work has begun but no
criterion is fully verified, add `**Implementation started:** Yes` and a short evidence or remaining-work note.

| State | File | Folder |
| --- | --- | --- |
| Complete | All acceptance boxes checked | Every file Complete |
| Partially complete | Some boxes checked, or explicitly started | Any mix other than all Complete or all Pending |
| Pending | No boxes checked and not started | Every file Pending |

The tracker is a compact dashboard: overall/folder progress bars, state totals and linked partial/pending file IDs.
Bars count fully completed files equally; partial work contributes no estimated completion. The index and folder
READMEs retain every file's acceptance counts and dependencies. Prerequisite warnings remain separate from status;
neither a bar nor recorded completion certifies whole-product release readiness.
The [historical snapshot](01-orchestration/history/README.md) preserves previous closure notes and carried decisions.

After every implementation, update the task's acceptance record, then run from `frontend/`:

```text
dart run tool/sync_dev_tracker.dart
dart run tool/sync_dev_tracker.dart --check
```

The same refresh runs automatically through `new_task.dart`, `verify.dart` and the installed pre-commit hook,
including plan-only and backend-only commits. On a fresh checkout install the managed hooks once with
`dart run tool/install_hooks.dart`. CI rejects stale generated views before verification can refresh them.
The hook leaves staging to the author: review and include the generated files with the implementation.
Do not manually maintain duplicate status lists or automatically check acceptance boxes.

## Milestones

**001** — the guardrails are in place. An architectural mistake fails a test.

**003** — the design system is complete. Later screens assemble existing parts.

**018** — the first end-to-end slice works: project, template, context, capture, process, review, approve, export.

**024** — the backend exists and the app runs on it: identity, roles, and AI through the proxy.

**025** — baseline release tooling. One gate over both artefacts, including the run that proves a required backend
is never a required connection. Final release approval follows Documentation and hardening.

**079** — compact More opens the shared secondary menu without losing navigation or drafts.

**080** — measured format/platform capabilities and approved adapters establish truthful input/render support.

**083** — a durable local workspace accepts input resources, output definitions and optional rich text/file
instructions, including projects with no capture records.

**084** — real provider integration generates evidence-linked structured drafts through durable local runs;
offline work resumes only on the user's explicit action.

**086** — Documentation is release-ready: five output formats, source review and approval, immutable versions,
project package round trips and platform/retention acceptance. These new milestones remain planned until their
task checklists pass; the earlier release milestone does not mark them complete.

**023** — the final integrated product passes hardening, with task 025's release gates and task 086's Documentation
acceptance complete. Its older task ID is retained; its execution position is the final phase.
