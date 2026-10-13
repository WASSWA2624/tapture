# Repository instructions

- Write efficient, professional, standard code and prefer reuse.
- Reuse uniform UI components and use the minimal corner radius (`Radii`, never zero).
- Follow the relevant rules in `frontend/.rules/` for application work and `backend/.rules/` for server work.
- Keep `app-write-up.md` complete and concise: preserve distinct requirements, contracts and stable section
  references; consolidate repetition and use cross-references.
- Build the requested scope against the current repository state. Read its dependencies, contracts and acceptance
  criteria before implementing; finish prerequisites before dependent work.
- Reuse before building — FE-CONS-01, FE-CONS-02 and FE-STR-09. A second copy of anything already in `core/` or a
  shared module is a defect, not a shortcut.
- Keep unrelated improvements out of the change. Record them separately with enough evidence to act on them.
- Ship required tests with the implementation, at the layer the acceptance criteria specify — FE-TEST-01, BE-TEST-01.
- Report only verified acceptance. If implementation or required verification remains unfinished, report Partially
  complete and identify the remaining work. Historical evidence does not certify the current repository is green.
- Leave behind no `print`, no `debugPrint`, no `console.log`, no `any`, no unresolved `TODO`, no hardcoded secret
  and no commented-out code.
- Make public only what the contract names. Preserve unrelated user edits and do not automatically stage them.
- Keep whole-product hardening after feature work and release infrastructure. Release approval requires an integrated
  product pass, including Documentation acceptance in §84 of `app-write-up.md`.

## Verification

| Work | Gate |
| :--- | :--- |
| Flutter | No review command. Do not add `frontend/tool/verify.dart`. Run the checks required by the changed scope. |
| Backend | `npm run verify` green — format, lint, type check, unit, integration and contract tests |

A requested guardrail or checker must pass on the current tree, fail on a deliberate violation, ship a fixture proving
both, and report every violation with file and line rather than stopping at the first.

## Rules that outrank convenience

1. Raw evidence is never destroyed. Refinement writes beside the original.
2. No screen invents a widget, colour, spacing value or error style the design system already has.
3. Nothing blocks capture — not a missing network, not an unreachable server, not a slow provider, not a missing
   template.
4. Every write is local-first and durable before the interface confirms it.
5. AI proposes; a person approves.
6. The backend is required to exist and never required to be reachable. It holds people, permissions and keys; it is
   never the store of record, never a backup, and never in the way of a field worker.
