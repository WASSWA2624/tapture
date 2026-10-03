# Repository instructions

- Write efficient, professional, standard code and prefer reuse.
- Reuse uniform UI components and use the minimal corner radius (`Radii`, never zero).
- Follow [the standard](#the-standard) below and the relevant frontend/backend rules.
- Keep `app-write-up.md` complete and concise: preserve distinct requirements, contracts and stable section
  references; consolidate repetition and use cross-references. Record implementation status in the tracker.
- Keep `dev-tracker.md` a brief visual dashboard with a collapsed task index; full task checklists live in the plan.
  Progress bars count completed tasks without estimating partial effort.
- The plan is one prompt file per step, `dev-plan/NN-slug.md`, holding its tasks under `## NNN — Title` headings;
  the final step, `dev-plan/27-hardening/`, keeps one prompt file per task, numbered on from 27 (`27-hardening.md`,
  `28-localization-catalogue.md`, …) with the task ID in its `# NNN — Title` heading. Work steps in number order and
  tasks in file order; a task's position (`PP.SS`) is its place in the plan. The three-digit task IDs are stable
  references, not execution positions; do not renumber them when a task moves.
- Keep whole-product hardening in the final numbered step, after feature work and release infrastructure.
- Before implementing, read the task's dependencies and Definition of done. Set
  `**Implementation started:** Yes` if work has begun before any acceptance item can be checked.
- Update that task's acceptance checklist as verified work lands. Do not mark an item complete just because its
  file exists, a mock succeeds, or a later task is planned to finish it. Reopen criteria contradicted by evidence.
- **Every implementation update must refresh `dev-tracker.md` automatically before the work is reported done.**
  Run `dart run tool/sync_dev_tracker.dart` from `frontend/` after changing task progress, then
  `dart run tool/sync_dev_tracker.dart --check`. Task creation, frontend verification and the installed pre-commit
  hook also invoke the same synchronizer. This applies to frontend, backend and plan-only implementation work.
- Never hand-edit `dev-tracker.md`. Change the task checklist/source notes, then regenerate. Include the generated
  changes with the implementation; preserve unrelated user edits and do not automatically stage them.
- If implementation or required verification remains unfinished, report Partially complete and leave the relevant
  acceptance items open. The tracker records acceptance status; it does not certify the whole repository is green.

## The standard

Every task in the plan inherits this section. A task repeats only what is specific to it.

### What a task is

Build exactly what the task describes, against the current repository state, then stop. The deliverable is working,
analysed, tested code — not a description of it.

A task carries **Implement**, **Files** and a tickable **Definition of done**, which must be fully ticked before it
closes (FE-FLOW-03, BE-FLOW-03). It adds a **Contract** where it publishes an API other tasks call, **Steps** where
the order of work is not obvious, **Constraints** where a rule bites harder than usual and **Out of scope** where a
specific temptation has to be fenced off; empty optional sections are omitted. `**Depends on**` links name earlier
tasks. Paths are written in full (`frontend/lib/...`, `backend/src/...`).

### Required of every task

- Obey `frontend/.rules/` for application work and `backend/.rules/` for server work, in full. A task's Constraints
  name the rules that bite hardest there; they never narrow the set.
- Reuse before building — FE-CONS-01, FE-CONS-02 and FE-STR-09. A second copy of anything already in `core/` or in a
  shared module is a defect, not a shortcut.
- Build only what the task describes. Anything else discovered becomes its own task
  (`dart run tool/new_task.dart <step> "<title>"`), never extra scope — FE-FLOW-04, FE-FLOW-08.
- Write the tests the Definition of done names, at the layer it names them. Tests are never a follow-up task —
  FE-TEST-01, BE-TEST-01.
- Leave behind no `print`, no `debugPrint`, no `console.log`, no `any`, no `TODO` without a task number, no hardcoded
  secret and no commented-out code.
- Make public only what the Contract names.
- Finish declared prerequisites before starting dependent work. Task 025 is the baseline release infrastructure; task
  086 adds the Documentation release acceptance; task 023 in the final hardening step verifies the integrated product
  after both, and release approval requires that final pass.

### Progress updates

The task's Definition of done is the source of progress. Check only verified requirements. If implementation has
begun but no requirement is fully verified, add `**Implementation started:** Yes` and a short evidence or
remaining-work note. Never copy a completion claim from an old summary onto unchecked acceptance criteria.

| Task state | Rule |
| --- | --- |
| Complete | Every acceptance checkbox is checked, including required verification |
| Partially complete | Some boxes are checked, or implementation is explicitly marked as started |
| Pending | No boxes are checked and implementation has not started |

A step is Complete when all its tasks are Complete, Pending when every task is Pending, and Partially complete
otherwise. Counts report acceptance coverage, not estimated effort. Unfinished prerequisites are shown separately from
these states. Historical completion is preserved as evidence, not fresh validation. CI rejects a stale tracker before
verification can refresh it; on a fresh checkout install the managed hooks once with `dart run tool/install_hooks.dart`.

### The gate, before a task closes

| Work | Gate |
| :--- | :--- |
| Flutter | `dart format` applied, `flutter analyze` clean, `dart run tool/verify.dart --changed` green |
| Backend | `npm run verify` green — format, lint, type check, unit, integration and contract tests |

A guardrail or checker a task asks for must pass on the current tree, fail on a deliberate violation, ship a fixture
proving both, and report every violation it finds with file and line rather than stopping at the first.

### Rules that outrank convenience

1. Raw evidence is never destroyed. Refinement writes beside the original.
2. No screen invents a widget, colour, spacing value or error style the design system already has.
3. Nothing blocks capture — not a missing network, not an unreachable server, not a slow provider, not a missing
   template.
4. Every write is local-first and durable before the interface confirms it.
5. AI proposes; a person approves.
6. The backend is required to exist and never required to be reachable. It holds people, permissions and keys; it is
   never the store of record, never a backup, and never in the way of a field worker.
