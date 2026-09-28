# 01 — Project setup and guardrails

The repository, and the executable guardrails that enforce every architectural rule. Policies here are code — lints, checkers and tests — not prose.

<!-- dev-plan:generated:start -->

## Implementation progress

**Step 01 — Partially complete**

4 total · 2 Complete · 2 Partially complete · 0 Pending. Status is generated from each task’s Definition of done; follow sub-step order below.

| Sub-step | Task ID | File / implementation | Status | Done | Dependencies / readiness |
| --- | --- | --- | --- | ---: | --- |
| 01.01 | 001 | [Project setup and guardrails](001-project-setup.md) | **Complete** | 72/72 | None; Dependencies complete |
| 01.02 | 087 | [Arrange implementation flow and automatically synchronize progress](087-chronological-plan-and-tracker.md) | **Partially complete** | 8/9 | 01.01 (001); Ready |
| 01.03 | 088 | [Keep the product specification complete and concise](088-concise-product-specification.md) | **Complete** | 5/5 | 01.01 (001); Dependencies complete |
| 01.04 | 089 | [Show a concise visual development tracker](089-compact-progress-dashboard.md) | **Partially complete** | 4/5 | 01.01 (001); Ready |

<!-- dev-plan:generated:end -->

## As built

The numbers this phase used to list (001–018) now live in task 001. Implement 001 for the original guardrails, then
087 for chronological planning and automatic progress updates. The tree that must exist at the end:

| Piece | Where it lives |
| :--- | :--- |
| Flutter app | `frontend/` — application id `com.tapture.app`, label Tapture, demo widgets gone |
| Hygiene | `.gitignore`, `.editorconfig`, `frontend/tool/check_repo_hygiene.dart` |
| Analyzer | `frontend/analysis_options.yaml` — `strict-casts` / `-inference` / `-raw-types`, enabled rules promoted to error; `public_member_api_docs` on `lib/core/` |
| Folders | `frontend/lib/app/`, shared `core/` subsystems, 17 features × 3 layers, each with a barrel. Canonical list: `frontend/tool/paths.dart` |
| Allowlist | `frontend/tool/allowlist.yaml` + `check_dependencies.dart` |
| Plan checker | `frontend/tool/check_plan.dart` — every `NNN-slug.md` file, required sections, dependencies at earlier implementation positions, and holes only where `dev-plan/RETIRED.md` retires the number |
| Task scaffolder | `frontend/tool/new_task.dart` + `tool/task_template.md` |
| Progress tracker | `frontend/tool/sync_dev_tracker.dart` and `check_staged_dev_tracker.dart` — acceptance-derived summaries, deterministic drift checks and consistent staged progress |
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
