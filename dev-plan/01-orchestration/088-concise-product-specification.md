# 088 — Keep the product specification complete and concise

**Implementation step:** 01.03

**Phase** 01 · Project setup and guardrails  |  **Depends on** [001](001-project-setup.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

**Implementation started:** Yes

## Implement

Edit `app-write-up.md` for completeness and concision: remove repetition, tighten prose and retain each distinct
product requirement, technical contract, default, limit and acceptance rule. Keep the existing numbered sections
and internal references stable. Distinguish the specification from implementation progress in the generated tracker.

Preserve captured projects as default but optional Documentation inputs, uploaded-only workflows, multiple projects
and archives, output definitions, optional prompts, review/approval and the mobile three-dot More menu. Align the
delivery summary with the ordered development plan, whose final folder is hardening. Resolve clear editorial
contradictions against existing requirements without adding product scope.

## Files

- `app-write-up.md`
- `AGENTS.md` specification maintenance instruction
- This task's acceptance record and automatically generated tracker/index/folder summaries

## Definition of done

- [x] All parts, numbered sections and subsection headings remain present; schemas, field/catalogue definitions, numeric limits and distinct requirements are preserved.
- [x] Repeated explanations are consolidated and wording is materially shorter without replacing the specification with an overview.
- [x] Documentation defaults, optional sources/prompts, source/format roles, grounding, offline behaviour and mobile More navigation remain explicit and consistent.
- [x] Delivery order names final hardening, links and section references resolve, and Markdown tables/code fences remain valid.
- [x] Comparison review records the reduction and any resolved editorial contradictions; plan validation and tracker synchronization pass.

## Verification

Revision 4 reduces the specification from 29,874 to 23,192 whitespace-delimited words (22.4%). All 240 headings,
including 84 numbered sections, remain in their original order. JSON/Dart contracts are unchanged; JSON syntax,
numeric section references, contents anchors, local links, table columns and code fences validate. Independent
comparisons of all parts found no remaining distinct requirement omissions after corrections.

Clarifications align record automation with explicit consent, Documentation with explicit start/resume, photo
removal with retention, local operator labels with account attribution, and device storage with the configured
root. They distinguish field/record import provenance, edit/evidence controls and backend-managed/personal keys,
retain the specified Photo index, and keep optional source projects distinct from the workspace's owner. Delivery
milestones point to the canonical implementation order with hardening last. No runtime code changed; this
documentation task was verified through comparison and structural checks rather than rerunning application suites.

Plan validation passes for 88 tasks; tracker synchronization and read-only drift checks pass for 27 folders.
