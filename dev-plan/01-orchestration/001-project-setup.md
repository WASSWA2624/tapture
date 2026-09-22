# 001 — Project setup and guardrails

**Phase** 01 · Project setup and guardrails  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The repository and every architectural rule that guards it. The Flutter application lives in `frontend/` under the
Tapture identity with no demo code left behind; ignore and editor configuration keeps generated output and secrets out
of git from the first commit; the analyzer runs as the first reviewer with every warning promoted to an error; the
ninety-nine directories under `frontend/lib/` each own a barrel and are named once in `frontend/tool/paths.dart`; and a
pinned allowlist decides which packages may exist at all. The plan checks itself — `check_plan.dart` validates
numbering, slugs, required sections, tickable checklists and backward dependency links, and `new_task.dart` opens the
next file from a template. One command, `verify.dart`, runs every gate in order and prints one table with one exit
code, and the pre-commit and commit-msg hooks make that gate hard to skip. Eight architecture suites and nine checkers
under `frontend/tool/` hold the architecture itself: layering over a parsed import graph, file naming and one public
type per file, the twelve canonical domain names in `frontend/lib/core/naming/domain_names.dart`, design tokens and the
responsive boundary, state and typed failures, logging discipline and a secret scan over one shared pattern file, test
presence by layer, the accessibility matchers every later widget test asserts through, and the network and raw-evidence
boundaries. From here an architectural mistake fails a test rather than reaching review.

## Files

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

The gate and the hooks:

- `frontend/tool/verify.dart` (new)
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
- `frontend/test/tool/verify_test.dart` (new)
- `frontend/test/tool/install_hooks_test.dart` (new)
- `frontend/test/tool/commit_msg_test.dart` (new)
- `frontend/test/tool/check_naming_test.dart` (new)
- `frontend/test/tool/check_logging_test.dart` (new)
- `frontend/test/tool/check_secrets_test.dart` (new)
- `frontend/test/tool/check_tests_test.dart` (new)

## Contract

```dart
// frontend/lib/main.dart
void main();  // renders an empty MaterialApp scaffold; no counter demo

// One entry point per tool, all the same shape: exit 0 clean, 1 on violation.
//   check_dependencies.dart  check_naming.dart  check_logging.dart
//   check_secrets.dart       patterns loaded from frontend/tool/secret_patterns.yaml
//   check_plan.dart          scans dev-plan/, exits non-zero on any structural error
//   check_tests.dart         --strict turns the report into a failure
//   new_task.dart            new_task <phase-folder> <slug> "<title>"
//   verify.dart              --fast skips the golden and integration suites
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

## Steps

### The repository and its lints

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

### The folder and dependency rules

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

### The plan's own tooling

6. Make the plan check itself. `check_plan.dart` parses every task file and asserts the filename number matches the
   heading number, that numbers are unique and contiguous, that slugs are unique, that Implement, Files and Definition
   of done are all present, that the Definition of done holds something to tick, and that every dependency link
   resolves to a file on disk and points at a lower number. A hole in the numbering passes only where
   `dev-plan/RETIRED.md` retires it, and a retired number is one no file may carry again. Twenty-three tests behind it.
7. Make opening a task cheap. `new_task.dart` scans the plan for the highest number, renders `tool/task_template.md`
   into the given phase folder as the next file, populates the heading, the phase line and the empty sections, refuses
   to overwrite an existing file or reuse a slug, and lists the new task in the phase README checklist and in
   `INDEX.md`. Seventeen tests behind it, one of which runs step 6's checker over the generated tree.

### The verify command and hooks

8. Build the one gate. `verify.dart` runs, in this order: format
   (`dart format --output=none --set-exit-if-changed .`), analyzer (`flutter analyze`), dependency allowlist,
   structure, plan, test presence `--strict`, guardrail tests, unit and widget tests, then golden tests and
   integration tests. It prints a single summary table of gate names and outcomes and exits non-zero if any gate
   fails. `--fast` sets goldens and integration aside for the pre-commit path. The naming and repo-hygiene checkers
   are reached through their own guardrail suites, not as extra rows. Green in seventy-nine seconds, with sixteen
   tests behind it.
9. Install the hooks. `tool/hooks/pre-commit` runs the verify command in fast mode when Dart files are staged.
   `tool/hooks/commit-msg` requires the subject to start with a three-digit task number followed by a space.
   `install_hooks.dart` copies both, makes them executable, normalises line endings, and replaces rather than
   accumulates, so running it repeatedly leaves exactly one copy of each. Twenty-eight tests behind it.

### The architectural test suites

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
    report into a failure that names the missing `test/…_test.dart` path. The strict run is what `verify.dart` calls.
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

## Constraints

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
- Tests ship with the change, so the strict presence run is what `verify.dart` calls, not an advisory report
  (FE-TEST-01).
- 48dp is the minimum for every interactive element, including icon buttons, chips and list actions (FE-A11Y-01).
- Matcher failure messages name the offending widget and the measured value, since these matchers are the only
  accessibility evidence a design-system test produces (FE-A11Y-10).
- The 200 percent text-scale case asserts no clipping in either orientation (FE-A11Y-03, FE-RESP-06).

## Definition of done

### The repository and its lints

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
- [x] Tests: `frontend/tool/verify.dart` runs the analyzer and fails on any issue.

### The folder and dependency rules

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

### The plan's own tooling

- [x] Renumbering a file by hand and forgetting its heading fails the check.
- [x] A dependency pointing at a higher-numbered task fails the check.
- [x] A dependency link that names no file on disk fails the check.
- [x] A number used twice, and a slug used twice, each fail the check.
- [x] A task file missing Implement, Files or Definition of done fails the check, as does a Definition of done with no
      checkbox to tick at all.
- [x] A hole in the numbering passes only where `dev-plan/RETIRED.md` retires the number, and a retired number is one
      no file may carry again.
- [x] Running the scaffolder twice with the same slug fails rather than overwriting.
- [x] The generated file passes the plan integrity checker unchanged.
- [x] The generated task is listed in the phase README checklist and in `INDEX.md`.
- [x] Tests: `frontend/test/tool/check_plan_test.dart` runs the checker over valid and deliberately broken fixture
      trees.
- [x] Tests: `frontend/test/tool/new_task_test.dart` generates into a temporary tree and asserts the result,
      including a run of the plan checker over what it generated.

### The verify command and hooks

- [x] One command reproduces the entire review gate locally, as one summary table with one exit code.
- [x] `--fast` sets the golden and integration suites aside, and is what the pre-commit hook runs.
- [x] A commit message without a task number is rejected.
- [x] Running the installer twice leaves exactly one copy of each hook.
- [x] Tests: `frontend/test/tool/verify_test.dart` asserts the exit code aggregates gate failures correctly.
- [x] Tests: `frontend/test/tool/commit_msg_test.dart` covers valid and invalid subjects.
- [x] Tests: `frontend/test/tool/install_hooks_test.dart` covers a repeated install and the line-ending
      normalisation.

### The architectural test suites

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

## Out of scope

- Riverpod itself. This phase writes the suites that hold the state and error conventions; the package arrives with
  002 · Foundation services, which is where `ProviderScope` and `ConsumerWidget` become real.
- `frontend/lib/core/backend/`. `network_test.dart` names it as one of the three folders allowed to reach the network,
  and the folder itself arrives with 024 · The minimal backend.
- The tokens, `SizeClass`, `AppConstants` and the widget catalogue the token, responsive and accessibility suites name.
  This phase writes the suites that will hold them; 002 · Foundation services and 003 · Design system supply the
  parts.
