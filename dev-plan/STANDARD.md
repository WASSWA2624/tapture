# The standing prompt

Every task file in this plan inherits this page. Read it once. A task repeats only what is specific to it.

## What a task is

Build exactly what the task file describes, against the current repository state, then stop. The deliverable is
working, analysed, tested code — not a description of it.

A task names its own **Files**, a **Contract** where it publishes an API other tasks call, **Steps** where the order
of work is not obvious, **Constraints** where a rule bites harder than usual, and a **Definition of done** that must
be fully ticked before it closes (FE-FLOW-03, BE-FLOW-03). Everything below is required of every task and is never
repeated inside one.

## Required of every task

- Obey `frontend/.rules/` for application work and `backend/.rules/` for server work, in full. A task's Constraints
  section names the rules that bite hardest there; it never narrows the set.
- Reuse before building — FE-CONS-01, FE-CONS-02 and FE-STR-09. A second copy of anything already in `core/` or in a
  shared module is a defect, not a shortcut.
- Build only what the file describes. Anything else discovered becomes its own task file
  (`dart run tool/new_task.dart`), never extra scope here — FE-FLOW-04, FE-FLOW-08.
- Write the tests the Definition of done names, at the layer it names them. Tests are never a follow-up task —
  FE-TEST-01, BE-TEST-01.
- Leave behind no `print`, no `debugPrint`, no `console.log`, no `any`, no `TODO` without a task number, no hardcoded
  secret and no commented-out code.
- Make public only what the Contract names.

## Progress updates are part of implementation

Use the numbered folder and generated substep order in [INDEX.md](INDEX.md). Stable task IDs remain the identity
used by code, commits and historical notes; an execution position such as `24.03` states when to implement it.
Finish declared prerequisites before starting dependent work. Task 025 is the baseline release infrastructure;
task 086 adds the Documentation release acceptance after that module exists. Task 023 in the final hardening
folder verifies the integrated product after both; release approval requires this final pass.

The task's **Definition of done** is the source of progress. Check only verified requirements. If implementation
has begun but no requirement is fully verified, add `**Implementation started:** Yes` and a short evidence or
remaining-work note. Never copy a completion claim from an old summary onto unchecked acceptance criteria.

| Task state | Rule |
| --- | --- |
| Complete | Every acceptance checkbox is checked, including required verification |
| Partially complete | Some boxes are checked, or implementation is explicitly marked as started |
| Pending | No boxes are checked and implementation has not started |

A folder is Complete when all its files are Complete, Pending when every file is Pending, and Partially complete
otherwise. Counts report acceptance coverage, not estimated effort. Blocked prerequisites are shown separately
from these three completion states. Historical completion is preserved as evidence, not fresh validation.

Keep the root tracker brief: visual completion bars, folder rows and open file IDs. Bars count fully completed
task files equally, never estimated partial effort. Detailed acceptance counts and dependencies belong in the
index and folder READMEs; the tracker links to them and flags prerequisite reviews.

After **every implementation or progress change**, automatically refresh the generated plan views as part of
the same work, before reporting completion:

```text
cd frontend
dart run tool/sync_dev_tracker.dart
dart run tool/sync_dev_tracker.dart --check
```

This updates `dev-tracker.md`, the ordered index, folder summaries and task step numbers. `new_task.dart`, the
frontend verification command and the installed pre-commit hook invoke the same synchronizer. CI checks drift
before a verification command can repair it. The hook never stages files: review and include generated changes
with the implementation. Backend-only and plan-only work follow the same progress rule. Do not hand-edit
generated sections, silently drop older decisions, auto-check acceptance, or mark failed verification complete.

## The gate, before a task closes

| Work | Gate |
| :--- | :--- |
| Flutter | `dart format` applied, `flutter analyze` clean, `dart run tool/verify.dart --fast` green |
| Backend | `npm run verify` green — format, lint, type check, unit, integration and contract tests |

A guardrail or checker this plan asks for must pass on the current tree, fail on a deliberate violation, ship a
fixture proving both, and report every violation it finds with file and line rather than stopping at the first.

## Out of scope, always

Anything the task file does not name. Raise it as its own task rather than widening this one. A task carries its own
**Out of scope** section only where a specific temptation has to be fenced off by name.

## Rules that outrank convenience

1. Raw evidence is never destroyed. Refinement writes beside the original.
2. No screen invents a widget, colour, spacing value or error style the design system already has.
3. Nothing blocks capture — not a missing network, not an unreachable server, not a slow provider, not a missing
   template.
4. Every write is local-first and durable before the interface confirms it.
5. AI proposes; a person approves.
6. The backend is required to exist and never required to be reachable. It holds people, permissions and keys; it is
   never the store of record, never a backup, and never in the way of a field worker.
