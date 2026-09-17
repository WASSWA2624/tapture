# Frontend rules

The standardisation rules for the Tapture Flutter application. They exist so that 281 tasks, built over months,
produce one codebase rather than forty dialects.

## How to use them

- **Every rule has an identifier** (`FE-STR-04`). Cite it in review instead of arguing style.
- **Most rules are enforced by a test**, not by goodwill. The enforcing task is named at the top of each file; if you
  can break a rule without a test failing, that is a gap — raise a task.
- **A rule may be broken exactly once**: in the pull request that deletes it. Rules change by editing this folder and
  the test that enforces it, in the same change.
- Dev-plan tasks cite the rule files that apply to them. Read those before starting.

## The files

| File | Covers |
|---|---|
| [01-structure.md](01-structure.md) | Repository and code layout, layering, file organisation |
| [02-coding-standards.md](02-coding-standards.md) | Dart style, naming, immutability, errors, async |
| [03-state-and-data.md](03-state-and-data.md) | Riverpod, repositories, persistence discipline |
| [04-theming.md](04-theming.md) | Tokens, the three themes, colour and elevation |
| [05-responsiveness.md](05-responsiveness.md) | Breakpoints, adaptive layout, orientation, text scale |
| [06-simplicity.md](06-simplicity.md) | The interaction budget that keeps the app usable in the field |
| [07-consistency.md](07-consistency.md) | Component reuse, the four states, copy tone, icon vocabulary |
| [08-localization.md](08-localization.md) | Strings, formats, direction, voice languages |
| [09-accessibility.md](09-accessibility.md) | Semantics, targets, contrast, screen readers |
| [10-performance.md](10-performance.md) | Budgets, threading, lists and images |
| [11-security-privacy.md](11-security-privacy.md) | Secrets, egress, untrusted input, evidence safety |
| [12-testing.md](12-testing.md) | What each layer tests, and how |
| [13-workflow.md](13-workflow.md) | Branches, commits, review, dependencies |

## The five that outrank everything else

1. Raw evidence is never destroyed. Refinement writes beside the original, never over it.
2. No screen invents a widget, colour, spacing value or error style the design system already has.
3. Nothing blocks capture — not a missing network, not a slow provider, not a missing template.
4. Every write is local-first and durable before the interface confirms it.
5. AI proposes; a person approves.
