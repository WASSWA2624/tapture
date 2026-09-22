# 01 — Project setup and guardrails

The repository, and the executable guardrails that enforce every architectural rule. Policies here are code — lints, checkers and tests — not prose.

Task 001 (1). One prompt for the completed phase; the atomics it absorbed are listed in [RETIRED.md](../RETIRED.md).

- [x] [001 — Project setup and guardrails](001-project-setup.md)

## As built

The numbers this phase used to list (001–018) now live in task 001. Reproduce this phase by implementing 001 against `frontend/`. The tree that must exist at the end:

| Piece | Where it lives |
| :--- | :--- |
| Flutter app | `frontend/` — application id `com.tapture.app`, label Tapture, demo widgets gone |
| Hygiene | `.gitignore`, `.editorconfig`, `frontend/tool/check_repo_hygiene.dart` |
| Analyzer | `frontend/analysis_options.yaml` — `strict-casts` / `-inference` / `-raw-types`, enabled rules promoted to error; `public_member_api_docs` on `lib/core/` |
| Folders | `frontend/lib/app/`, shared `core/` subsystems, 17 features × 3 layers, each with a barrel. Canonical list: `frontend/tool/paths.dart` |
| Allowlist | `frontend/tool/allowlist.yaml` + `check_dependencies.dart` |
| Plan checker | `frontend/tool/check_plan.dart` — every `NNN-slug.md` file, required sections, lower-numbered deps, and holes only where `dev-plan/RETIRED.md` retires the number |
| Task scaffolder | `frontend/tool/new_task.dart` + `tool/task_template.md` |
| Verify | `frontend/tool/verify.dart` — format, analyzer, dependencies, structure, plan, **test presence (`--strict`)**, guardrail tests, unit/widget tests; goldens and integration run unless `--fast` |
| Hooks | `frontend/tool/hooks/pre-commit`, `commit-msg`, `install_hooks.dart` |
| Architecture suites | `frontend/test/architecture/` — import graph, tokens, responsive, state, errors, network, data safety, naming |
| Naming | `frontend/tool/check_naming.dart` — snake_case files, one public class, banned words (`manager`, `helper`, `util`, `data`, `info`, `item`) |
| Domain names | `frontend/lib/core/naming/domain_names.dart` |
| A11y matchers | `frontend/test/support/a11y_matchers.dart` — `hasSemanticLabel`, `meetsTapTarget` (48dp), `expectNoA11yIssues` |
| Logging / secrets | `check_logging.dart`, `check_secrets.dart`, `secret_patterns.yaml` |
| Test presence | `check_tests.dart` — every `domain/`, `data/`, `core/widgets/` file and presentation screen owes a mirrored `test/…_test.dart` |

`dart run tool/verify.dart --fast` from `frontend/` is the close gate. Naming and repo-hygiene checkers run through their own suites under the guardrail gate, not as extra verify rows.

A later agent reproducing chrome, overflow, or catalogue widgets must keep these checkers green: no second public class, no type name containing `item`, no feature `Color`/`TextStyle` literals, and a test file for every new `core/widgets/` source (including `part` files).
