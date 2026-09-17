# 01 — Project setup and guardrails

The repository, and the executable guardrails that enforce every architectural rule. Policies here are code — lints, checkers and tests — not prose.

Tasks 001–018 (18). Each file is a standalone implementation prompt.

- [x] [001 — Create the Flutter project](001-flutter-project-init.md)
- [x] [002 — Repository hygiene files](002-repo-hygiene.md)
- [x] [003 — Strict analyzer configuration](003-strict-lints.md)
- [x] [004 — Create the folder skeleton](004-folder-scaffold.md)
- [x] [005 — Dependency allowlist checker](005-dependency-allowlist.md)
- [x] [006 — Plan integrity checker](006-plan-integrity-checker.md)
- [x] [007 — Task scaffolding tool](007-task-scaffolder.md)
- [x] [008 — The verify command](008-verify-command.md)
- [x] [009 — Git hook installer](009-git-hooks.md)
- [x] [010 — Layering enforcement test](010-layering-test.md)
- [x] [011 — Naming and file-layout checker](011-naming-checker.md)
- [x] [012 — Canonical domain names](012-domain-names.md)
- [x] [013 — Design-token and responsive boundary tests](013-design-token-test.md)
- [x] [014 — State and error-handling convention tests](014-riverpod-test.md)
- [x] [015 — Logging discipline and secret scan](015-logging-checker.md)
- [x] [016 — Test presence checker](016-test-presence-checker.md)
- [x] [017 — Accessibility test matchers](017-accessibility-matchers.md)
- [x] [018 — Network boundary and raw-data safety tests](018-network-test.md)

## As built

Reproduce this phase by implementing 001–018 in order against `frontend/`. The tree that must exist at the end:

| Piece | Where it lives |
| :--- | :--- |
| Flutter app | `frontend/` — application id `com.tapture.app`, label Tapture, demo widgets gone |
| Hygiene | `.gitignore`, `.editorconfig`, `frontend/tool/check_repo_hygiene.dart` |
| Analyzer | `frontend/analysis_options.yaml` — `strict-casts` / `-inference` / `-raw-types`, enabled rules promoted to error; `public_member_api_docs` on `lib/core/` |
| Folders | `frontend/lib/app/`, shared `core/` subsystems, 17 features × 3 layers, each with a barrel. Canonical list: `frontend/tool/paths.dart` |
| Allowlist | `frontend/tool/allowlist.yaml` + `check_dependencies.dart` |
| Plan checker | `frontend/tool/check_plan.dart` — 281 `NNN-slug.md` files, required sections, lower-numbered deps |
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
