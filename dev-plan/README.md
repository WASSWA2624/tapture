# Tapture — development plan

60 implementation prompts, in build order, from an empty repository to a shippable app and the minimal backend it
requires.

Every task inherits [STANDARD.md](STANDARD.md). Read that once, then open the lowest unticked file in
[INDEX.md](INDEX.md). A task repeats only what is specific to it; the rules live in `frontend/.rules/` and
`backend/.rules/`.

Phases 01 to 25 are one task each except phase 23, which still holds leftover field-feedback extras. Old numbers
are listed in [RETIRED.md](RETIRED.md) and are never reused.

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

One task, one file. Numbers are global and chronological; dependencies point backwards. Never widen a task —
`dart run tool/new_task.dart` opens a new one instead (FE-FLOW-04). A phase task is worked in its Steps order and
lands as a series of pull requests, one per step group, rather than one enormous change.

## Phases

| | Phase | Tasks | What it delivers |
|---|---|---|---|
| 01 | [Project setup and guardrails](01-orchestration/) | 001 | The repository, plus every architectural rule as a lint, checker or test |
| 02 | [Foundation services](02-foundation/) | 002 | Boots, logs, fails safely; the services everything injects |
| 03 | [Design system](03-design-system/) | 003 | Tokens, themes and the whole widget vocabulary, before any screen |
| 04 | [Local database](04-data-layer/) | 004 | Every table, with merge columns from the first migration |
| 05 | [File storage](05-file-storage/) | 005 | The organised folder tree and every service that writes into it |
| 06 | [Application shell](06-app-shell/) | 006 | Navigation, routing and the always-visible status line |
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
| 23 | [Hardening](23-hardening/) | 023, 026–060 | Fast, legible, reachable, unbreakable in the field |
| 24 | [The minimal backend](24-backend/) | 024 | **Required** — accounts, auth, roles, AI functionality and key custody, plus the optional relay |
| 25 | [Testing and release](25-testing-and-release/) | 025 | The suites, the pipeline and the gate over both artefacts |

The backend is required to exist (§70) and is built after the app because almost all of it depends on the app existing
first. The app-side steps of task 024 turn the local operator profile into an account and server-held key custody. The
change relay (§72) is the one optional slice inside that task: its relay schema, push, acknowledgement, purge job and
client. An organisation that never switches it on has a complete product. Nothing ships until phase 25 passes over
both artefacts.

## Milestones

**001** — the guardrails are in place. An architectural mistake fails a test.

**003** — the design system is complete. Later screens assemble existing parts.

**018** — the first end-to-end slice works: project, template, context, capture, process, review, approve, export.

**024** — the backend exists and the app runs on it: identity, roles, and AI through the proxy.

**025** — shippable. One gate over both artefacts, including the run that proves a required backend is never a
required connection.
