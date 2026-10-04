# 01 — Project setup and guardrails

The repository, and the executable guardrails that enforce every architectural rule. Policies here are code — lints, checkers and tests — not prose.

## As built

The numbers this phase used to list (001–018) now live in task 001. Implement 001 for the original guardrails, then
087 for chronological planning and automatic progress updates, and 099 for one prompt file per step. The tree that
must exist at the end:

| Piece | Where it lives |
| :--- | :--- |
| Flutter app | `frontend/` — application id `com.tapture.app`, label Tapture, demo widgets gone |
| Hygiene | `.gitignore`, `.editorconfig`, `frontend/tool/check_repo_hygiene.dart` |
| Analyzer | `frontend/analysis_options.yaml` — `strict-casts` / `-inference` / `-raw-types`, enabled rules promoted to error; `public_member_api_docs` on `lib/core/` |
| Folders | `frontend/lib/app/`, shared `core/` subsystems, 17 features × 3 layers, each with a barrel. Canonical list: `frontend/tool/paths.dart` |
| Allowlist | `frontend/tool/allowlist.yaml` + `check_dependencies.dart` |
| Plan checker | `frontend/tool/check_plan.dart` over `frontend/tool/plan_source.dart` — step files and folders, step headings and step-folder file numbering, required sections, unique IDs and titles with no holes, and dependencies at earlier implementation positions |
| Task scaffolder | `frontend/tool/new_task.dart` + `tool/task_template.md` |
| Progress tracker | `frontend/tool/sync_dev_tracker.dart` and `check_staged_dev_tracker.dart` — acceptance-derived summaries, deterministic drift checks and consistent staged progress |
| Hooks | `frontend/tool/hooks/pre-commit`, `commit-msg`, `install_hooks.dart` |
| Architecture suites | `frontend/test/architecture/` — import graph, tokens, responsive, state, errors, network, data safety, naming |
| Naming | `frontend/tool/check_naming.dart` — snake_case files, one public class, banned words (`manager`, `helper`, `util`, `data`, `info`, `item`) |
| Domain names | `frontend/lib/core/naming/domain_names.dart` |
| A11y matchers | `frontend/test/support/a11y_matchers.dart` — `hasSemanticLabel`, `meetsTapTarget` (48dp), `expectNoA11yIssues` |
| Logging / secrets | `check_logging.dart`, `check_secrets.dart`, `secret_patterns.yaml` |
| Test presence | `check_tests.dart` — every `domain/`, `data/`, `core/widgets/` file and presentation screen owes a mirrored `test/…_test.dart` |

A later agent reproducing chrome, overflow, or catalogue widgets must keep these checkers green: no second public class, no type name containing `item`, no feature `Color`/`TextStyle` literals, and a test file for every new `core/widgets/` source (including `part` files).

## 001 — Project setup and guardrails

### Implement

The repository and every architectural rule that guards it. The Flutter application lives in `frontend/` under the
Tapture identity with no demo code left behind; ignore and editor configuration keeps generated output and secrets out
of git from the first commit; the analyzer runs as the first reviewer with every warning promoted to an error; the
ninety-nine directories under `frontend/lib/` each own a barrel and are named once in `frontend/tool/paths.dart`; and a
pinned allowlist decides which packages may exist at all. The plan checks itself — `check_plan.dart` validates
numbering, slugs, required sections, tickable checklists and dependencies at earlier implementation positions, and `new_task.dart` opens the
next file from a template. There is no review command, and one must not be added. Eight architecture suites and nine checkers
under `frontend/tool/` hold the architecture itself: layering over a parsed import graph, file naming and one public
type per file, the twelve canonical domain names in `frontend/lib/core/naming/domain_names.dart`, design tokens and the
responsive boundary, state and typed failures, logging discipline and a secret scan over one shared pattern file, test
presence by layer, the accessibility matchers every later widget test asserts through, and the network and raw-evidence
boundaries. From here an architectural mistake fails a test rather than reaching review.

### Files

Project and repository:

- `frontend/pubspec.yaml` (new)
- `frontend/lib/main.dart` (new)
- `.gitignore` (changed)
- `.editorconfig` (new)
- `frontend/analysis_options.yaml` (changed)

Structure and dependencies:

- `frontend/lib/app/` (new)
- `frontend/lib/core/` (new)
- `frontend/lib/features/` (new)
- `frontend/tool/paths.dart` (new)
- `frontend/tool/allowlist.yaml` (new)
- `frontend/tool/check_dependencies.dart` (new)
- `frontend/tool/check_structure.dart` (new)
- `frontend/tool/check_repo_hygiene.dart` (new)
- `frontend/tool/check_analyzer_config.dart` (new)

The plan's own tooling:

- `frontend/tool/check_plan.dart` (new)
- `frontend/tool/new_task.dart` (new)
- `frontend/tool/task_template.md` (new)

The hooks:

- `frontend/tool/install_hooks.dart` (new)
- `frontend/tool/hooks/pre-commit` (new)
- `frontend/tool/hooks/commit-msg` (new)

Source checkers:

- `frontend/tool/check_naming.dart` (new)
- `frontend/tool/check_logging.dart` (new)
- `frontend/tool/check_secrets.dart` (new)
- `frontend/tool/secret_patterns.yaml` (new)
- `frontend/tool/check_tests.dart` (new)

Application source:

- `frontend/lib/core/naming/domain_names.dart` (new)

Architecture suites:

- `frontend/test/architecture/import_graph.dart` (new)
- `frontend/test/architecture/layering_test.dart` (new)
- `frontend/test/architecture/naming_test.dart` (new)
- `frontend/test/architecture/tokens_test.dart` (new)
- `frontend/test/architecture/responsive_test.dart` (new)
- `frontend/test/architecture/state_test.dart` (new)
- `frontend/test/architecture/errors_test.dart` (new)
- `frontend/test/architecture/network_test.dart` (new)
- `frontend/test/architecture/data_safety_test.dart` (new)
- `frontend/test/architecture/fixtures/` (new)

Test support and the tests that guard the tooling:

- `frontend/test/support/a11y_matchers.dart` (new)
- `frontend/test/support/a11y_matchers_test.dart` (new)
- `frontend/test/smoke_test.dart` (new)
- `frontend/test/tool/check_repo_hygiene_test.dart` (new)
- `frontend/test/tool/check_analyzer_config_test.dart` (new)
- `frontend/test/tool/check_structure_test.dart` (new)
- `frontend/test/tool/check_dependencies_test.dart` (new)
- `frontend/test/tool/check_plan_test.dart` (new)
- `frontend/test/tool/new_task_test.dart` (new)
- `frontend/test/tool/install_hooks_test.dart` (new)
- `frontend/test/tool/commit_msg_test.dart` (new)
- `frontend/test/tool/check_naming_test.dart` (new)
- `frontend/test/tool/check_logging_test.dart` (new)
- `frontend/test/tool/check_secrets_test.dart` (new)
- `frontend/test/tool/check_tests_test.dart` (new)

### Contract

```dart
// frontend/lib/main.dart
void main();  // renders an empty MaterialApp scaffold; no counter demo

// One entry point per tool, all the same shape: exit 0 clean, 1 on violation.
//   check_dependencies.dart  check_naming.dart  check_logging.dart
//   check_secrets.dart       patterns loaded from frontend/tool/secret_patterns.yaml
//   check_plan.dart          scans dev-plan/, exits non-zero on any structural error
//   check_tests.dart         --strict turns the report into a failure
//   new_task.dart            new_task <step> "<title>"
Future<int> main(List<String> args);

// frontend/lib/core/naming/domain_names.dart
abstract final class DomainNames { static const project = 'Project'; /* ... */ }

// frontend/test/architecture/import_graph.dart
ImportGraph buildImportGraph(Directory libDir);
List<Violation> checkLayering(ImportGraph g);

// frontend/test/support/a11y_matchers.dart
Matcher hasSemanticLabel(String label);
Matcher meetsTapTarget({double min = 48});
Future<void> expectNoA11yIssues(WidgetTester t);
```

### Steps

#### The repository and its lints

1. Create the application. Run the Flutter create command into `frontend/` with organisation com.tapture and project
   name tapture, Android platform first. Set the display name to Tapture and the application id to `com.tapture.app`
   in the Android manifest and Gradle config. Delete the counter demo widget and its generated test, leaving
   `main.dart` rendering an empty scaffold and `frontend/test/smoke_test.dart` green.
2. Write the hygiene files. `.gitignore` covers `build/`, `.dart_tool/`, generated `.g.dart` and `.freezed.dart`
   output, `*.keystore`, `key.properties`, local `.env` files and sample bundles. `.editorconfig` fixes UTF-8, LF
   endings, two-space indentation for Dart and a final newline. `check_repo_hygiene.dart` guards the ignore list, with
   nine tests behind it; it is reached through its own guardrail suite rather than as a row of the verify table.
3. Configure the analyzer as the first reviewer. Include flutter_lints, then enable strict-casts, strict-inference and
   strict-raw-types under the analyzer language section. Turn on the rules for const usage, sorted directives,
   unnecessary awaits, unused elements and public API documentation on `core/`. Promote every warning and hint to an
   error. The analyzer has no wildcard promotion, so all 171 enabled rules and diagnostics are named one at a time and
   `public_member_api_docs` is scoped to `lib/core/`. `check_analyzer_config.dart` guards the file, with fourteen
   config tests and twenty-nine analyzer fixtures behind it.

#### The folder and dependency rules

4. Create the folder skeleton — ninety-nine directories under `frontend/lib/`, each owning a barrel: `app/`; `core/`
   with its twenty-eight shared subsystems ai, background, bundle, cloud, concurrency, constants, copy, db, device,
   errors, export, feedback, files, hash, ids, import, lifecycle, logging, naming, network, normalise, permissions,
   security, serialisation, team, time, validation and widgets; and `features/` with one folder per feature named in
   the plan, seventeen of them, each holding empty `data/`, `domain/` and `presentation/` directories. That core list
   is exhaustive: it is every shared directory the plan goes on to use. `frontend/tool/paths.dart` exports the
   canonical list as constants so the checkers read the structure from one place rather than hardcoding paths, and
   `check_structure.dart` fails a missing required directory or an unexpected top-level one, with fifteen tests behind
   it.
5. Close the dependency list. `allowlist.yaml` approves three packages, each with its pinned version, its purpose and
   the task that introduced it. `check_dependencies.dart` parses `frontend/pubspec.yaml`, compares direct dependencies
   against the allowlist, reads additions and version drift as errors and removals as warnings, and prints the
   offending package together with the rule that adding one takes its own task. Twelve tests behind it.

#### The plan's own tooling

6. Make the plan check itself. `check_plan.dart` parses every step — a step file holding `## NNN — Title` tasks, or
   a step folder of prompt files numbered on from its step number (task 099) — and asserts that each step heading
   matches its file name and each step-folder file its place in sequence, that task numbers are unique and contiguous, that titles and slugs are unique, that Implement, Files and
   Definition of done are all present, that the Definition of done holds something to tick, and that every dependency
   link resolves to the file holding that task and points to an earlier step/substep position. Stable task IDs do not
   determine execution order (task 087). A hole in the task numbering fails the check.
7. Make opening a task cheap. `new_task.dart` scans the plan for the highest number, renders `tool/task_template.md`
   as the next task — appended to the given step file, or written into a step folder as its own file — populates the
   heading and the empty sections, refuses a title already in use or an existing file, and refreshes
   `dev-tracker.md`. One of its tests runs step 6's checker over the generated tree.

#### The hooks

8. Do not add a review command. `install_hooks.dart` copies the hooks, makes them executable, normalises line endings, and replaces rather than
   accumulates, so running it repeatedly leaves exactly one copy of each. The hooks do not run a review and do not reject a commit.

#### The architectural test suites

10. Enforce layering. `import_graph.dart` builds the graph by parsing directives from every file under
    `frontend/lib/`, and `layering_test.dart` reads it against all four clauses of FE-STR-04 plus FE-STR-08:
    presentation never imports data, data never imports presentation, core never imports features, and no feature
    imports another feature's internals, only its exported barrel. Every violation carries the file, the import and
    the rule broken. A clean and a violating fixture under `frontend/test/architecture/fixtures/` prove both
    directions. Twenty tests behind it.
11. Enforce naming and file layout. `check_naming.dart` reads every hand-written file under `frontend/lib/` and
    reports a file name that is not snake_case, a first public type that is not the one the file is named for, a
    second public class sharing a file, a provider that is not lowerCamelCase ending in `Provider`, and a type built
    out of a banned word — manager, helper, util, data, info or item. Matching takes a whole camel-case word at a
    time, so `ReferenceDataset` passes where `RecordData` does not, and it reads declarations only, so Flutter's
    `ThemeData` and `IconData` are never flagged. Forty-two tests behind it.
12. Fix one word per concept. `domain_names.dart` holds the twelve canonical specification type names — Project,
    TemplateDef, FieldDef, RecordEntry, FieldValue, CaptureSession, PhotoAsset, ContextState, ReferenceDataset,
    ProcessingJob, Bundle and MergeSession — each mapped to the synonyms it displaces, RecordModel, PhotoItem,
    TemplateData and the like, so a failure message can name the replacement. `naming_test.dart` scans
    `frontend/lib/` for a declaration matching a synonym and fails with file, line and the canonical term, whole
    identifiers only. Nine tests behind it.
13. Hold the design-system boundary. `tokens_test.dart` scans `frontend/lib/features/` for `Color(`, `Colors.`,
    `EdgeInsets.all(` with a literal, `BorderRadius.circular(` with a literal, `Duration(` and `TextStyle(`, allows
    those constructs only under `frontend/lib/app/theme/` and `frontend/lib/core/widgets/`, and emits the token that
    should have been used in each violation message. `responsive_test.dart` fails any comparison of `MediaQuery` size
    or width outside `frontend/lib/core/widgets/responsive/`, and a hardcoded pixel width at or above the token
    maximum in a feature widget, naming `context.sizeClass` and `SizeClass.expanded` as the accessors to use instead.
    Fourteen tests over allowed and forbidden fixtures.
14. Hold the controller-to-repository boundary. `state_test.dart` asserts every provider declaration ends in
    `Provider` and lives in the feature that owns it, that no `StatefulWidget` calls `setState` outside
    `frontend/lib/core/widgets/` and animation code, that controllers expose intent methods, and that no widget calls
    a repository directly. `errors_test.dart` asserts no file under `domain/` or `data/` bare-throws a non-`Failure`
    type, that every public repository method returns `Result` or `Future<Result>`, and that every `Failure` subclass
    declares a user-facing message field. Eighteen tests over compliant and non-compliant fixtures. Riverpod itself
    was not added here: this task names only the two suites.
15. Scan the source for what must never be logged or committed. `check_logging.dart` fails any `print(` or
    `debugPrint(` outside `frontend/tool/` and `frontend/test/`, fails a log call that interpolates an identifier
    matching key, secret, token, password, credential, caption, transcript or value, and requires every log call to
    pass a level and a tag. `secret_patterns.yaml` defines named patterns for provider keys, bearer tokens, private
    keys, connection strings and long base64 blobs, and is the single definition the logger's redaction and the
    log-export test read as well. `check_secrets.dart` scans `frontend/lib/`, `frontend/android/`, `frontend/ios/` and
    the asset files against it, allows documented placeholders in test fixtures only, and reports file, line and the
    matched pattern name without echoing the matched value. Thirty-seven tests behind the pair.
16. Make missing tests visible. `check_tests.dart` requires a test file for every file under `domain/` and `data/`,
    for every widget under `core/widgets/`, and reports presentation screens too; barrels, generated files and screens
    covered by an integration test are exempt. It prints a coverage-of-files table by layer, and `--strict` turns the
    report into a failure that names the missing `test/…_test.dart` path.
    Thirteen tests behind it.
17. Give accessibility one place to be asserted. `a11y_matchers.dart` implements `hasSemanticLabel` for semantic label
    presence, `meetsTapTarget` for minimum tap target size, and `expectNoA11yIssues`, which runs the framework
    accessibility guidelines over the pumped widget and asserts survival of 200 percent text scale without clipping.
    Failure messages name the offending widget and the measured value. Seven tests behind it.
18. Hold the security invariants. `network_test.dart` fails any import of a HTTP client outside
    `frontend/lib/core/ai/`, `frontend/lib/core/cloud/` and `frontend/lib/core/backend/`, fails a widget or a
    `domain/` file that references a network client type, and asserts no capture, records or export file imports a
    networking package. `data_safety_test.dart` fails any assignment or update writing a field named `valueRaw`,
    `textRaw` or `transcriptRaw` outside the repository method that creates the row, any hard row delete in a
    repository where the tombstone helper belongs, and any file delete call outside the purge job. Eighteen tests over
    allowed and forbidden fixtures. `frontend/lib/core/backend/` itself was not added here: this task names only the
    two suites.

### Constraints

- The rule files that bite hardest across this phase are `frontend/.rules/01-structure.md`,
  `frontend/.rules/02-coding-standards.md` and `frontend/.rules/13-workflow.md`.
- Layering has four clauses, and the barrel rule between features is the fifth thing the suite reads (FE-STR-04,
  FE-STR-08).
- One word per concept, in code and on screen; the registry is the reference and synonyms fail its test (FE-CONS-07).
- Match whole camel-case segments only, so `ReferenceDataset` and `FieldValue` pass while `RecordData` fails
  (FE-CODE-03).
- Colour, spacing, radius, elevation, duration and text style come from the token files; a literal in `lib/features/`
  fails the build (FE-THEME-01).
- The 600dp and 1024dp breakpoints exist only inside `SizeClass`, and features never compare `MediaQuery` width
  (FE-RESP-01, FE-RESP-02).
- Numbers and durations come from tokens or `AppConstants`, never from a call site (FE-CODE-09).
- Riverpod only — no service locator, no global singleton, `setState` confined to `core/widgets/` and animation code
  (FE-STATE-01).
- Providers are declared in the owning feature and exported through its barrel; `core/` declares none that depends on
  a feature (FE-STATE-03).
- Widgets read state and call intent methods; persistence and orchestration sit in the controller or domain, never in
  `build` (FE-STATE-04, FE-STATE-05).
- `Failure` is sealed and every variant carries a message and a recovery action (FE-CODE-06).
- `print` and `debugPrint` do not exist in `lib/`; every log call carries a level and a tag and never logs a key,
  token, caption, transcript, field value or file content (FE-CODE-08).
- Keys and credentials belong in platform secure storage and nowhere else — not the database, logs, exports, bundles
  or preferences (FE-SEC-01).
- Nothing ships with a provider key compiled in, so a match in `lib/`, a Gradle file or an asset is a failure, not a
  warning (FE-SEC-02).
- Egress is a closed list: networking imports live only in `core/ai/`, `core/cloud/` and `core/backend/`, and a screen
  never speaks to a server (FE-SEC-03).
- Raw values, captions, transcripts and original photos are written once; refinement writes a separate column,
  deletion is a tombstone, and files go only to the purge job after the retention window (FE-SEC-08).
- `domain/` imports no HTTP client at all, so a finding there is a layering defect as well as a security one
  (FE-STR-05).
- The layer decides what is owed: unit tests for domain and pure logic, in-memory database tests for repositories and
  DAOs, behaviour tests for widgets, goldens for design-system widgets (FE-TEST-02).
- Tests ship with the change (FE-TEST-01).
- 48dp is the minimum for every interactive element, including icon buttons, chips and list actions (FE-A11Y-01).
- Matcher failure messages name the offending widget and the measured value, since these matchers are the only
  accessibility evidence a design-system test produces (FE-A11Y-10).
- The 200 percent text-scale case asserts no clipping in either orientation (FE-A11Y-03, FE-RESP-06).

### Definition of done

#### The repository and its lints

- [x] The app builds and launches to a blank scaffold on a device or emulator.
- [x] No generated demo code remains anywhere in `frontend/lib/` or `frontend/test/`.
- [x] A clean checkout followed by a build produces no untracked files.
- [x] Running the analyzer on the fresh project reports zero issues.
- [x] Introducing an implicit dynamic cast fails the analyzer.
- [x] Every enabled rule and diagnostic is promoted to an error, with `public_member_api_docs` scoped to `lib/core/`.
- [x] Tests: `frontend/test/smoke_test.dart` pumps the app and asserts it builds without exception.
- [x] Tests: `frontend/tool/check_repo_hygiene.dart` fails if a build artefact path is missing from `.gitignore`.
- [x] Tests: `frontend/test/tool/check_repo_hygiene_test.dart` covers the hygiene checker in both directions.
- [x] Tests: `frontend/tool/check_analyzer_config.dart` and `frontend/test/tool/check_analyzer_config_test.dart` hold
      the analyzer configuration against its fixtures.

#### The folder and dependency rules

- [x] Every directory named in the plan exists and contains a barrel file.
- [x] `frontend/tool/paths.dart` is the one place the canonical directory list is written, and every checker reads it
      from there.
- [x] Adding a package to pubspec without the allowlist entry fails the check.
- [x] Removing an allowlisted package reports a warning rather than an error.
- [x] Version drift between pubspec and the allowlist is reported as an error.
- [x] Tests: `frontend/tool/check_structure.dart` fails when a required directory is missing or an unexpected
      top-level directory appears, with `frontend/test/tool/check_structure_test.dart` behind it.
- [x] Tests: `frontend/test/tool/check_dependencies_test.dart` covers approved, unapproved and version-drift
      fixtures.

#### The plan's own tooling

- [x] Renumbering a file by hand and forgetting its heading fails the check.
- [x] A dependency pointing to a later step/substep position fails the check; stable IDs may be higher or lower.
- [x] A dependency link that names no file on disk fails the check.
- [x] A number used twice, and a title or slug used twice, each fail the check.
- [x] A task missing Implement, Files or Definition of done fails the check, as does a Definition of done with no
      checkbox to tick at all.
- [x] A hole in the task numbering fails the check.
- [x] Running the scaffolder twice with the same title fails rather than overwriting.
- [x] The generated task passes the plan integrity checker unchanged.
- [x] The generated task appears in its step and in the regenerated `dev-tracker.md`.
- [x] Tests: `frontend/test/tool/check_plan_test.dart` runs the checker over valid and deliberately broken fixture
      trees.
- [x] Tests: `frontend/test/tool/new_task_test.dart` generates into a temporary tree and asserts the result,
      including a run of the plan checker over what it generated.

#### The hooks

- [x] There is no review command, and CI, rules, and prompts do not require one.
- [x] Running the installer twice leaves exactly one copy of each hook.
- [x] Tests: `frontend/test/tool/commit_msg_test.dart` covers valid and invalid subjects.
- [x] Tests: `frontend/test/tool/install_hooks_test.dart` covers a repeated install and the line-ending
      normalisation.

#### The architectural test suites

- [x] The layering suite passes on the empty scaffold and fails when a deliberate cross-layer import is added.
- [x] Every layering violation names the file, the import and the rule broken, and one run reports all of them.
- [x] Renaming a class without renaming its file fails the naming check.
- [x] A second public class in one file, and a provider that is not lowerCamelCase ending in `Provider`, each fail the
      naming check.
- [x] A type built out of manager, helper, util, data, info or item fails, while `ReferenceDataset` passes and
      Flutter's `ThemeData` is never flagged.
- [x] Declaring `RecordModel` or `PhotoItem` fails the test with `RecordEntry` and `PhotoAsset` in the message.
- [x] All twelve concepts resolve through `DomainNames`, with no second spelling anywhere in `frontend/lib/`.
- [x] A literal colour added to a feature widget fails `tokens_test.dart`; the same literal under
      `frontend/lib/app/theme/` passes.
- [x] A screen comparing screen width fails `responsive_test.dart`; the same comparison under
      `frontend/lib/core/widgets/responsive/` passes.
- [x] Every violation message names the replacement token or `SizeClass` accessor, not just the offending line.
- [x] A widget calling a repository method, and a provider declared outside its feature, each fail `state_test.dart`.
- [x] `setState` outside `frontend/lib/core/widgets/` and animation code, and a controller with no intent method, each
      fail `state_test.dart`.
- [x] A repository method returning a bare `Future`, and a `Failure` subclass with no message field, each fail
      `errors_test.dart`.
- [x] A bare throw of a non-`Failure` type under `domain/` or `data/` fails `errors_test.dart`.
- [x] Logging an API key variable fails `check_logging.dart` with the file and line; a log call missing a level or a
      tag fails too.
- [x] A pasted provider key in a Dart file, a Gradle file or an asset fails `check_secrets.dart`, and neither checker
      ever prints the matched value.
- [x] Every pattern in `frontend/tool/secret_patterns.yaml` is named, so a violation report is readable without
      opening the file.
- [x] Adding a domain service without a test fails the strict run and names the missing test path.
- [x] A barrel, a generated file and an integration-covered screen produce no finding.
- [x] A button without a semantic label fails `hasSemanticLabel` with a readable message.
- [x] A 40dp icon button fails `meetsTapTarget`, and a 48dp one passes.
- [x] `expectNoA11yIssues` fails a widget that breaks the framework guidelines and passes a compliant one.
- [x] A HTTP call added inside a feature repository fails `network_test.dart`, while the same import under
      `frontend/lib/core/backend/` passes.
- [x] A widget or a `domain/` file referencing a network client type fails `network_test.dart`, as does a capture,
      records or export file importing a networking package.
- [x] An update to `valueRaw` in a refinement service, a hard row delete and a file delete outside the purge job each
      fail `data_safety_test.dart`.
- [x] Tests: `frontend/test/architecture/layering_test.dart`, plus a negative fixture under
      `frontend/test/architecture/fixtures/`.
- [x] Tests: `frontend/test/tool/check_naming_test.dart` covers each rule with a passing and a failing fixture.
- [x] Tests: `frontend/test/architecture/naming_test.dart` over fixtures for three synonyms and one compliant tree.
- [x] Tests: `tokens_test.dart` and `responsive_test.dart`, each with an allowed-location and a forbidden-location
      fixture under `frontend/test/architecture/fixtures/`.
- [x] Tests: `state_test.dart` and `errors_test.dart` with a compliant and a non-compliant controller fixture, plus
      compliant and non-compliant repository and `Failure` fixtures under `frontend/test/architecture/fixtures/`.
- [x] Tests: `frontend/test/tool/check_logging_test.dart` covers each banned pattern.
- [x] Tests: `frontend/test/tool/check_secrets_test.dart` covers one fixture per pattern plus an allowed placeholder
      fixture.
- [x] Tests: `frontend/test/tool/check_tests_test.dart` over a fixture tree holding one exempt file, one covered file
      and one uncovered file per layer.
- [x] Tests: `frontend/test/support/a11y_matchers_test.dart` proves each matcher both passes and fails correctly.
- [x] Tests: `network_test.dart` and `data_safety_test.dart` with compliant fixtures and one non-compliant fixture per
      violation, under `frontend/test/architecture/fixtures/`.
- [x] Contract above is implemented exactly, with nothing else made public.

### Out of scope

- Riverpod itself. This phase writes the suites that hold the state and error conventions; the package arrives with
  002 · Foundation services, which is where `ProviderScope` and `ConsumerWidget` become real.
- `frontend/lib/core/backend/`. `network_test.dart` names it as one of the three folders allowed to reach the network,
  and the folder itself arrives with 024 · The minimal backend.
- The tokens, `SizeClass`, `AppConstants` and the widget catalogue the token, responsive and accessibility suites name.
  This phase writes the suites that will hold them; 002 · Foundation services and 003 · Design system supply the
  parts.

## 087 — Arrange implementation flow and automatically synchronize progress

**Depends on** [001](01-orchestration.md)

**Implementation started:** Yes

### Implement

Give the plan one dependency-safe implementation order and one source of progress. Numbered folders are steps;
files within them are substeps, shown as `PP.SS`. Keep each existing three-digit task ID and filename so code,
commits and historical decisions retain their references. Backend and feature refinements precede Documentation;
whole-product hardening is the final folder. Test infrastructure is built before the final acceptance pass.

Derive Complete, Partially complete and Pending from each task's Definition of done and optional explicit started
marker. Aggregate the same states for folders. Show checked/total acceptance criteria, dependencies and the next
actionable unfinished task. Never infer completion from file existence, an implementation commit or elapsed time.

Generate the root tracker, ordered index, folder task tables and per-task execution positions through one
dependency-free Dart tool. New-task creation, verification and the repository pre-commit hook refresh those views;
CI checks committed drift before verification can repair it. Every implementation must update its acceptance
record and refresh the tracker before reporting completion, including backend-only and documentation changes.
The hook must preserve the user's staging choices and explain any required generated-file review.

Reconcile stale status claims with the current task records and concrete repository evidence. Preserve the old
tracker verbatim, including dated closure notes and carried decisions, in a clearly labelled historical snapshot.

Task [089](01-orchestration.md#089--show-a-concise-visual-development-tracker) later makes the root tracker a compact visual dashboard. Full
per-task acceptance/dependency tables remain in the tracker's task index; the tracker summarises completed tasks and
links partial/pending tasks without changing the source-of-truth or status rules.

Task [099](01-orchestration.md#099--one-prompt-file-per-plan-step) later makes each step one prompt file. It removes the index, folder READMEs,
per-task position metadata and the historical snapshot; the tracker is the only generated file and git keeps the
history.

### Files

- `AGENTS.md`, `dev-plan/README.md`, `dev-plan/STANDARD.md`, and frontend/backend workflow rules
- Numbered `dev-plan/` folders, task metadata and dependency links
- `dev-tracker.md`, `dev-plan/INDEX.md`, and generated blocks in phase READMEs
- `dev-plan/01-orchestration/history/README.md` and its `dev-tracker-2026-09-28.md` snapshot
- `frontend/tool/sync_dev_tracker.dart`, `check_staged_dev_tracker.dart`, `new_task.dart`, `check_plan.dart`,
  and `tool/hooks/pre-commit`
- Focused tests under `frontend/test/tool/` and the frontend CI workflow

### Contract

- `dart run tool/sync_dev_tracker.dart [--check] [--root <repo-root>]` runs from `frontend/`.
- Default mode validates the complete plan before updating generated files. Repeated runs are deterministic.
- `--check` performs no writes and fails on stale generated content or invalid task/dependency metadata.
- Only checked acceptance criteria prove completion. `**Implementation started:** Yes` makes a task with no
  checked criteria Partially complete; absence of the marker and checked criteria means Pending.
- A folder is Complete if every task is Complete, Pending if all are Pending, and Partially complete otherwise.
- A prerequisite must appear earlier in folder/substep order. Readiness remains separate from completion status.
- Pre-commit checks both the working tree and staged plan projection. Unstaged acceptance changes cannot be
  represented by staged generated summaries, and the hook never stages or discards user changes.

### Definition of done

- [x] Every task appears once in the tracker's task index with its step, substep and stable ID; the tracker covers every step and links to task details (presentation refined by tasks 089 and 099).
- [x] Hardening is the last numbered step; all declared prerequisites resolve and precede their dependants.
- [x] Task and step summaries show the three states consistently, acceptance counts and actionable dependencies.
- [x] Reconciled partial work includes evidence and open criteria; earlier closure notes remain in git history since task 099 removed the snapshot.
- [x] One synchronizer refreshes summaries after task creation, verification and every installed pre-commit run; CI rejects committed drift.
- [x] Repository and workflow instructions require acceptance updates and tracker regeneration for every implementation.
- [x] Tests cover state aggregation, deterministic regeneration, read-only drift checks, invalid plans, task creation and safe hook staging; changed tooling passes targeted formatting and analysis.
- [x] The installed repository hook matches the managed hook, and the real plan passes synchronization and plan checks.

### Verification status

On 2026-09-28, all 96 focused tests passed across tracker synchronization, real pre-commit integration, task
creation, plan integrity, verification orchestration and hook installation. The hook fixtures verify docs/backend
commits, stale generated views, staged-versus-unstaged acceptance records, partial staging and preservation of
unrelated prose without auto-staging. Targeted analysis and formatting pass for the 11 changed Dart source/test
files; no new package is required.

At this task's verification, the plan had 27 ordered folders and 87 unique tasks, each represented in the generated views.
`check_plan.dart` passes; synchronization is deterministic and `--check` reports no drift after regeneration.
All live plan links resolve. The historical snapshot's SHA-256 matches its recorded original value.
The managed pre-commit and commit-message hooks were installed in this checkout and compared with their sources.

## 088 — Keep the product specification complete and concise

**Depends on** [001](01-orchestration.md)

**Implementation started:** Yes

### Implement

Edit `app-write-up.md` for completeness and concision: remove repetition, tighten prose and retain each distinct
product requirement, technical contract, default, limit and acceptance rule. Keep the existing numbered sections
and internal references stable. Distinguish the specification from implementation progress in the generated tracker.

Preserve captured projects as default but optional Documentation inputs, uploaded-only workflows, multiple projects
and archives, output definitions, optional prompts, review/approval and the mobile three-dot More menu. Align the
delivery summary with the ordered development plan, whose final folder is hardening. Resolve clear editorial
contradictions against existing requirements without adding product scope.

### Files

- `app-write-up.md`
- `AGENTS.md` specification maintenance instruction
- This task's acceptance record and automatically generated tracker/index/folder summaries

### Definition of done

- [x] All parts, numbered sections and subsection headings remain present; schemas, field/catalogue definitions, numeric limits and distinct requirements are preserved.
- [x] Repeated explanations are consolidated and wording is materially shorter without replacing the specification with an overview.
- [x] Documentation defaults, optional sources/prompts, source/format roles, grounding, offline behaviour and mobile More navigation remain explicit and consistent.
- [x] Delivery order names final hardening, links and section references resolve, and Markdown tables/code fences remain valid.
- [x] Comparison review records the reduction and any resolved editorial contradictions; plan validation and tracker synchronization pass.

### Verification

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

## 089 — Show a concise visual development tracker

**Depends on** [001](01-orchestration.md)

**Implementation started:** Yes

### Implement

Make `dev-tracker.md` a concise generated dashboard: overall completed-task progress, status totals, next actionable
task and one row per implementation step. Show visual bars with exact completed/total counts and linked partial
and pending task IDs. Keep full per-task acceptance/dependency details in the tracker's collapsed task index
(task 099).

Compute completion only from fully complete tasks, without estimating partial effort. Keep unfinished prerequisites
visible independently of completion. Preserve automatic regeneration, source checklists, stable IDs and the
existing ordered plan, with hardening last.

### Files

- `frontend/tool/sync_dev_tracker.dart` and affected tracker/new-task/hook tests
- `dev-tracker.md` and generated plan views
- `dev-plan/README.md`, `STANDARD.md`, `AGENTS.md` and task 087's superseded tracker-presentation notes

### Definition of done

- [x] The root tracker uses one step table, overall progress bars/counts and a compact legend instead of duplicating every task section.
- [x] Every unfinished task is linked under its actual state; full task details and dependencies remain in the collapsed task index.
- [x] Percentages/bars count only completed tasks, handle empty/all-complete boundaries, preserve next-action dependencies and flag completed scopes with unfinished prerequisites.
- [x] Focused tracker/generator/hook tests, targeted formatting/analysis, plan validation and deterministic synchronization checks pass.

### Verification

54 focused tests passed across tracker generation, task creation and real pre-commit integration. They cover
unweighted file counts, flooring, empty/all-complete bars, one row per folder, partial/pending links, full index
retention, prerequisite warnings, next work and automatic refresh. Changed Dart source/tests pass targeted analysis
and formatting. Plan validation passes for 89 tasks; deterministic regeneration and read-only drift checks pass.

The existing whole-repository gate failures recorded in [079](24-product-refinements.md#079--show-a-mobile-more-menu-in-the-bottom-navigation)
remain unresolved. This presentation change does not rerun or claim success for that gate; its acceptance remains open.

## 099 — One prompt file per plan step

**Depends on** [001](01-orchestration.md), [087](01-orchestration.md), [089](01-orchestration.md)

**Implementation started:** Yes

### Implement

Make each implementation step one prompt file, `dev-plan/NN-slug.md`, holding its tasks verbatim and in order under
`## NNN — Title` headings, with the step's former README prose at the top. The final hardening step stays a folder,
`dev-plan/27-hardening/`, of one prompt file per task, numbered on from its step number like the files before it
(`27-hardening.md` holds task 023, `28-localization-catalogue.md` task 096). Remove the folder READMEs, `INDEX.md`, `README.md`,
`RETIRED.md`, `STANDARD.md` and the historical snapshot: the standing rules move into `AGENTS.md` and git keeps the
history. A task's position is its place in the plan, so nothing generated is written into a prompt.

Rewrite the plan checker, the task scaffolder, the tracker synchronizer and the pre-commit hook for that layout over
one shared reader. `dev-tracker.md` becomes the only generated file and carries a collapsed task index with
acceptance counts, dependencies and readiness. Point every link into the plan at its new home, and reword the
acceptance criteria of tasks 001, 087 and 089 that named the removed files.

### Files

- `dev-plan/` — the step files; links and metadata in the `27-hardening/` task files
- `AGENTS.md`, `prompts/dev-prompt-implementer.md`, `README.md`, `app-write-up.md`, the rule-file headers and other
  references into the plan
- `frontend/tool/plan_source.dart` (new), `check_plan.dart`, `new_task.dart`, `task_template.md`,
  `sync_dev_tracker.dart`, `tool/hooks/pre-commit`
- `frontend/lib/features/settings/presentation/about_screen.dart` — the plan link opens the tracker
- `frontend/test/tool/check_plan_test.dart`, `new_task_test.dart`, `sync_dev_tracker_test.dart`,
  `pre_commit_test.dart`, `support/plan_fixture.dart` and
  `frontend/test/features/settings/presentation/about_screen_test.dart`
- `dev-tracker.md` (generated)

### Contract

- `dart run tool/new_task.dart <step> "<title>"` appends the next task to a step file, or writes the next numbered
  `NN-slug.md` into a step folder, then refreshes the tracker.
- `dart run tool/check_plan.dart [plan-dir]` and `dart run tool/sync_dev_tracker.dart [--check] [--root <repo-root>]`
  keep their command lines; both read the plan through `readPlan` in `frontend/tool/plan_source.dart`.

### Definition of done

- [x] Steps 01–26 are each one `dev-plan/NN-slug.md` holding every task of the step verbatim and in order, under its
      former README prose; `27-hardening/` keeps its task files, numbered on from 27, and no README.
- [x] `INDEX.md`, `README.md`, `RETIRED.md`, `STANDARD.md`, every folder README and the history snapshot are gone, and
      the standing rules live in `AGENTS.md`.
- [x] Every link into the plan, inside and outside `dev-plan/`, resolves to the new location.
- [x] `check_plan.dart` reports with file and line a stray file, a step heading that disagrees with its file name, a
      step-folder prompt numbered out of sequence, a hole or duplicate in the task IDs, a duplicate title, a missing
      section, an empty Definition of done and a dependency that names no file, names the wrong file or points forward.
- [x] `new_task.dart` appends to a step file or writes into a step folder, refuses a title already in use, and leaves
      nothing behind when refused.
- [x] `sync_dev_tracker.dart` writes only `dev-tracker.md`, with a task index holding acceptance counts, dependencies
      and readiness; `--check` and the staged check stay read-only.
- [x] Tests: the focused tool tests and the About screen test pass, and changed Dart files are formatted and analyse
      clean.

### Verification

On 2026-10-03 every merged task matched its source once link targets, heading levels and the dropped metadata were
normalised, and every dependency line kept its task IDs. `check_plan.dart` passes for 27 steps and 99 tasks, and
556 relative links and anchors across the plan, tracker, specification, rules and branding resolve. The focused
tests pass — `check_plan_test` (29), `new_task_test` (13), `sync_dev_tracker_test` (30) and `pre_commit_test` (8) —
with the rest of `test/tool`, `test/support`, `test/architecture`, the About screen and the feedback-guide tests,
apart from three failures that predate this task: `device_matrix_test` and `fault_injection_test` do not compile
against the current tool and support code, and `strict_analysis_test` counts the analyzer findings in drifted local
test copies. `dart analyze lib tool` and the changed tests are clean and formatted, and the installed hook matches
the managed one.

## 100 — No review command

**Depends on** [001](01-orchestration.md)

### Implement

There is no Flutter review command. `frontend/tool/verify.dart` is not part of the repository. Continuous integration, rules, and prompts do not run it and must not gain a step that does.

### Files

- `.github/workflows/ci.yml`
- `AGENTS.md`
- `frontend/.rules/13-workflow.md`
- `prompts/dev-prompt-implementer.md`
- `frontend/assets/feedback/feedback-prompts-generator.md`

### Definition of done

- [x] `frontend/tool/verify.dart` is absent, and nothing in CI, rules, or prompts requires it.

