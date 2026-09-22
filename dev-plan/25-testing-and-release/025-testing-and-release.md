# 025 — Testing and release: the suites, the pipeline and the gate over both artefacts

**Phase** 25 · Testing and release  |  **Depends on** [004](../04-data-layer/004-local-database.md), [012](../12-capture/012-capture.md), [015](../15-data-quality/015-data-quality.md), [017](../17-meetings/017-meetings.md), [018](../18-export/018-export.md), [019](../19-bundles-and-merge/019-bundles-and-merge.md), [022](../22-privacy-and-security/022-privacy-and-security.md), [023](../23-hardening/023-hardening.md), [024](../24-backend/024-minimal-backend.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Everything that decides whether a build may leave the building. Three layers of shared test scaffolding — hand-written
fakes, domain matchers and fixture factories for unit tests, a widget pump helper that installs theme, providers,
router and a fixed clock, and an integration harness that boots the real app against an in-memory Drift database with
every service faked, the network refused and a clock the test drives; ten integration runs written on top of them,
covering capture to export processed as it goes, forty records captured with the network off and processed later,
inherited context across records, caption scope across a record's photos, a capture checked against an imported
register, the same identifier captured twice on purpose, a bundle crossing between two databases, every export format
an operator can hand over, the meeting record type end to end, and the sign-in, proxy and offline run that proves the
sentence the MVP definition of done turns on (A67); two continuous integration workflows, a per-push pipeline running
format, analyze, unit, widget and golden tests that reports success only when the backend workflow is green on the same
commit, and an emulator job running the integration suite nightly and before every release with no network; a signed,
shrunk, split-ABI release variant produced by one documented command with the signing key supplied from the
environment and no keystore in the repository; the release gate program that verifies every release condition over
both artefacts — the app and the backend it requires (A70) — refuses to produce a build when one fails and writes
its gate table beside the artefact as the release record; and the backlog report generator that turns everything
unbuilt, every friction entry and every waived gate into one ordered report nobody has to assemble by hand.

## Files

The harnesses:

- `frontend/test/support/fakes.dart` (new)
- `frontend/test/support/matchers.dart` (new)
- `frontend/test/support/pump_app.dart` (new)
- `frontend/integration_test/support/harness.dart` (new)

The end-to-end journeys:

- `frontend/integration_test/capture_to_export_test.dart` (new)
- `frontend/integration_test/offline_deferred_test.dart` (new)
- `frontend/integration_test/context_test.dart` (new)
- `frontend/integration_test/caption_scope_test.dart` (new)
- `frontend/integration_test/verification_test.dart` (new)
- `frontend/integration_test/duplicate_test.dart` (new)
- `frontend/integration_test/merge_test.dart` (new)
- `frontend/integration_test/export_formats_test.dart` (new)
- `frontend/integration_test/meeting_test.dart` (new)
- `frontend/integration_test/signin_proxy_offline_test.dart` (new)

The pipelines:

- `.github/workflows/ci.yml` (new)
- `.github/workflows/integration.yml` (new)

The release build:

- `frontend/android/app/build.gradle` (changed)
- `frontend/android/key.properties.example` (new)
- `frontend/docs/release-build.md` (new)

The gate and the backlog:

- `frontend/tool/release_gate.dart` (new)
- `frontend/tool/backlog_report.dart` (new)

Tests over this phase's own scaffolding and tools:

- `frontend/test/support/harness_smoke_test.dart` (new)
- `frontend/test/tool/release_build_config_test.dart` (new)
- `frontend/test/tool/release_gate_test.dart` (new)
- `frontend/test/tool/backlog_report_test.dart` (new)

## Contract

```dart
// frontend/test/support/pump_app.dart
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  Brightness brightness = Brightness.light,
  DateTime? now,
});

// frontend/integration_test/support/harness.dart
Future<TestApp> bootTestApp({List<Override> overrides = const [], DateTime? now});

abstract class TestApp {
  AppDatabase get db;
  TestClock get clock;          // advance() drives every cache and retention window
  FakeAiService get ai;
  FakeBackend get backend;      // reachable() and unreachable() flip server availability
  int get outboundCallCount;    // any non-zero value in an offline stretch is a failure
  Future<void> dispose();
}
```

```dart
// frontend/tool/release_gate.dart     — --tag <version>; exits 0 only when every gate passes
// frontend/tool/backlog_report.dart   — writes build/backlog.md
Future<int> main(List<String> args);
```

## Steps

### The harnesses

1. Build `frontend/test/support/` first: fakes for every service interface of 062, matchers for domain failures, and
   factories giving a valid project, template, record and photo in one line each. Layer `pumpApp` on those fakes so a
   widget test names only its overrides, then layer `bootTestApp` on `pumpApp`'s provider wiring plus
   `AppDatabase.memory()` from 049, installing a socket guard that fails the test on any real outbound call rather
   than letting it hang. Expose pump-to-condition helpers so no suite reaches for a fixed delay. Every suite below is
   written on these three layers and adds no infrastructure of its own.

### The end-to-end journeys

2. Cover the capture spine twice, immediate and deferred; together they are the vertical slice no change may break
   silently. `capture_to_export_test.dart` creates a project, picks a template, sets context, captures, processes,
   reviews, approves and exports, asserting the exported file carries the approved values for every captured record
   and that the run touches no screen state the app cannot rebuild from the database.
   `offline_deferred_test.dart` — with the backend and provider unreachable — captures forty records saved raw
   through the two save paths of 107, processes them in a later pass, then exports, asserting `outboundCallCount`
   stays zero for the whole capture stretch, that each save is durable before the interface confirms it, and that raw
   values survive beside the refined ones. Export the same input through both runs and compare: deferred processing
   must produce an identical export to immediate processing.
3. Cover the machinery that decides how far one edit reaches, each run proving a different scope rule and failing on
   its own. `context_test.dart` captures five records under one project context and asserts all five inherit it,
   overrides the context on one record and asserts only that record changes, then changes the district on the project
   and asserts the change cascades to the four still inheriting and leaves the overridden record alone.
   `caption_scope_test.dart` applies a caption to one photo, to a selection of three and to all photos of a record,
   asserting after each that exactly the intended set carries it, then edits one photo's caption and asserts the
   others keep the previous text.
4. Cover data quality, each run proving a separate guarantee. `verification_test.dart` imports a register, scans an
   identifier, asserts the record prefills from the matching row, confirms it, then edits one prefilled value; assert
   the variance report names that field with both the register value and the observed one, and that the register
   itself is untouched. `duplicate_test.dart` captures the same serial twice; assert the duplicate is detected and the
   two records are offered side by side, override with a reason, then assert both records survive, the override reason
   is stored, and the history holds who, when, from what and to what for every changed value.
5. Cover the file boundary — everything the app writes out and reads back. `merge_test.dart` exports a bundle from one
   database and imports it into a second, resolves one conflicting record, undoes and redoes, asserting idempotency by
   importing the same bundle twice and finding no second change, and a complete undo by comparing the second database
   against its pre-merge snapshot row for row. `export_formats_test.dart`, with the network off, produces XLSX, CSV,
   JSON, PDF and ZIP from one project, asserting each opens in a reader, each carries the same record count as the
   database, and the ZIP's manifest checksums verify by the same routine the merge path uses before extraction.
6. Cover the meeting record type, which no other journey touches. `meeting_test.dart` creates a meeting with a date,
   location and inherited project context; adds attendance by photographing a sign-in sheet, asserting the extracted
   names arrive as a proposal, that nothing is recorded until a person approves, and that a corrected name replaces
   only its own entry; refines the minutes, asserting the raw transcript and the refined text both exist and the raw
   copy is unchanged; then exports the minutes PDF, asserting it names the meeting, the approved attendance list and
   the decisions, and that the export runs with the network off.

### The pipeline

7. Write the two workflows. `ci.yml` on every push: cache pub and Gradle dependencies, run the verify command, fail on
   analyzer warnings, and upload golden failure images as artefacts; require the backend workflow's conclusion on the
   same commit, so a red backend — the workflow delivered inside 119 — makes this pipeline red, because neither
   artefact ships alone. `integration.yml`: boot an Android emulator and run `frontend/integration_test/` with no
   network, on a nightly schedule and on release branches, including `signin_proxy_offline_test.dart` in that run.
   Give each workflow one failing exit for any failing step — no step is allowed `continue-on-error`.

### The release build and the gate

8. Configure the release variant: signing config read from `key.properties` or environment variables, resource and
   code shrinking on, and per-ABI splits. Document the signing key handling in `frontend/docs/release-build.md` —
   where the keystore lives, how it reaches the pipeline, how it is rotated — and never commit a keystore or a
   password. Name the single build command in that document and use the same one in the pipeline.
9. Build `release_gate.dart`, the program that verifies every release condition and refuses to produce a build when
   one fails. Run and record, for the app: the full verify command, a secret scan over the built artefacts, a
   migration test from the previously released schema, an offline end-to-end run, an export opened by a spreadsheet
   reader, and the permission list diffed against the previous release. Run and record, for the backend:
   `npm run verify`, its own migration test from the last released schema, the contract tests against the published
   specification, and a scan proving no provider key can leave the server. Run and record, for the pair: the sign-in,
   proxy and offline end-to-end run of step 11, which is the gate that proves a required backend is never a required
   connection (A70.4). Print a gate table of pass, fail and waived, write it beside the artefact as the release
   record, and exit non-zero on any failure; a skipped gate counts as a failure unless waived explicitly on the
   command line.
10. Build `backlog_report.dart`, so nobody assembles the backlog by hand. Scan the plan for unticked tasks, grouped by
    phase, with dependencies resolved to titles; merge in friction-log entries and waived release gates, each with its
    date and source; and emit one ordered report naming, for every deferred item, the reason it was deferred and the
    trigger for revisiting it.
11. Finish with the run the gate turns on, `signin_proxy_offline_test.dart`: an operator signs in once, runs AI through
    the backend with no key on the device, then does everything else with the server unreachable. Start against the
    fake backend — sign in once, enrol the device, and assert the device holds no provider key at any point in the
    run. Capture a record and process it through the AI proxy, asserting the extraction succeeds and the usage counter
    moves. Take the server away and capture, review, approve, edit and export; all must succeed, with no login screen
    and no blocking dialog. Advance the clock past both cache lifetimes with the server still away and assert capture,
    review, edit and export still work, and that only relay, the proxy and a role change are refused, each with a
    plain-language reason. Bring the server back and assert the session and grant refresh silently and queued proxy
    jobs drain on their own.

## Constraints

- A release is two artefacts, the app and the backend it requires (A70), and neither ships alone: the gate covers
  both, and a red backend pipeline on the same commit makes the app pipeline red.
- One end-to-end run must prove that a required backend is never a required connection (A70.4). The sign-in, proxy and
  offline run is that proof, and the release is blocked when it fails even if every other gate passes.
- Fakes are hand-written; a mocking framework appears only for third-party surfaces we do not own (FE-TEST-03).
- The harness disables the network by default and no fake ever reaches a real AI service (FE-TEST-05).
- Helpers pump to an explicit condition; the harness offers no sleep or fixed-delay API (FE-TEST-07).
- Every run reuses the harnesses, the fake backend and the clock injection of step 1 rather than adding infrastructure
  of its own (FE-CONS-01).
- Capture is never blocked by a missing network, an unreachable server or a slow provider; the offline run asserts this
  rather than assuming it (FE-SEC-04).
- Raw evidence is append-only: the deferred run reads the raw column after refinement and finds it unchanged, and the
  meeting run reads the raw transcript column after refinement and asserts it identical (FE-SEC-08).
- No run deletes a record to resolve a conflict; the loser of an override is tombstoned at most (FE-SEC-08).
- Every run asserts the audit trail for each value it changes — who, when, from what, to what — and after a bundle
  import every value change still names its origin device (FE-SEC-09).
- Register content is data, never instruction: prefilled text is quoted where it reaches a provider prompt and escaped
  where it is rendered (FE-SEC-05).
- The bundle is checksum-verified and traversal-checked before extraction; a tampered archive is refused, not partly
  applied (FE-SEC-06).
- Extracted attendance is a proposal a person approves, never an accepted write, and the rejection path is covered as
  well, so a discarded proposal leaves no attendance row (FE-TEST-10).
- Guardrail suites are never skipped or excluded to make a pipeline pass (FE-TEST-06).
- The emulator job runs with the network disabled and no real provider credentials present (FE-TEST-05, FE-SEC-02).
- Nothing ships or stores a provider key on the device; the run asserts the absence, it does not merely avoid the path
  (FE-SEC-02).
- Credentials come from secure storage or the environment, never the repository or the built artefact (FE-SEC-01).
- The release build is reproducible: the same commit and the same key produce the same artefact set.
- The backend migration and contract gates run from the last released schema, not from empty (BE-TEST-09).
- A waiver is recorded with its reason in the release record and surfaces in the backlog report.

## Definition of done

- [ ] A unit test needs no boilerplate beyond its assertions, a widget test starts from one `pumpApp` call, and an
      integration test starts from one `bootTestApp` call.
- [ ] An integration test that opens a real socket or calls a real provider fails with a named harness error.
- [ ] The fixed clock makes goldens in light, dark and outdoor reproducible across runs (FE-TEST-02).
- [ ] Tests: `frontend/test/support/harness_smoke_test.dart` proves each layer boots and that the socket guard bites;
      one domain suite, one widget suite and one integration suite are moved onto the harnesses and stay green.
- [ ] A break anywhere between capture and export fails one of the two spine runs loudly, naming the step, and neither
      run depends on screen state the app cannot rebuild from the database.
- [ ] The offline run records zero outbound calls during capture and forty durable records before any processing.
- [ ] Deferred and immediate processing of the same input yield the same export.
- [ ] Tests: `capture_to_export_test.dart` and `offline_deferred_test.dart` run green offline against the harness
      fakes, in the pipeline's integration job.
- [ ] An override never leaks beyond its own record, and a cascade never overwrites an override.
- [ ] Each of the three caption scopes lands on exactly its target set, and a later single edit is independent.
- [ ] Tests: `context_test.dart` and `caption_scope_test.dart` run green offline against fakes, end to end.
- [ ] A confirmed capture that differs from the register produces a variance entry, not a silent overwrite.
- [ ] An overridden duplicate leaves both records and a reason behind, readable in history after a restart.
- [ ] Tests: `verification_test.dart` and `duplicate_test.dart` run green offline against fakes, end to end.
- [ ] Re-importing a bundle changes nothing, and undo returns the target database to its exact pre-merge state.
- [ ] All five export formats are produced with zero outbound calls and each matches the record count it claims.
- [ ] A corrupt or traversal-bearing bundle is rejected with a plain-language reason and no partial write.
- [ ] Tests: `merge_test.dart` and `export_formats_test.dart` run green offline against fakes, end to end.
- [ ] Attendance derived from a photo is editable and reaches the record only through approval.
- [ ] The exported minutes PDF matches the approved minutes and attendance, and is produced offline.
- [ ] Tests: `meeting_test.dart` runs green offline against fakes, end to end, including the discarded-proposal path.
- [ ] A red pipeline blocks merging, and a red backend pipeline on the same commit makes `ci.yml` red.
- [ ] The integration suite runs nightly and before every release, on an emulator, offline.
- [ ] A golden failure leaves a downloadable image behind.
- [ ] Tests: one run per workflow against a branch with a single deliberately broken step, proving each gate fails and
      names the step.
- [ ] A release build is produced from one documented command, signed, shrunk and split by ABI.
- [ ] A missing signing key fails the build with a clear message rather than falling back to a debug key.
- [ ] Tests: `frontend/test/tool/release_build_config_test.dart` parses `build.gradle` and asserts shrinking, splits
      and an environment-sourced signing config, and asserts no keystore, password or key alias is committed anywhere.
- [ ] A build cannot be produced while any gate fails, in either the app or the backend.
- [ ] A backend whose contract tests fail blocks the app release, and the record says why.
- [ ] The release record written beside the artefact names every gate as passed, failed or waived, with the reason for
      each waiver.
- [ ] The sign-in, proxy and offline gate failing blocks the release even when every other gate passes.
- [ ] Tests: `frontend/test/tool/release_gate_test.dart` covers the pass, fail and waiver paths, including a failing
      backend gate and a skipped gate treated as a failure.
- [ ] Running the backlog tool after a release produces a backlog ordered by phase, with every waiver from the release
      record present and attributed.
- [ ] An item with no stated deferral reason is reported as a defect in the report itself, not omitted.
- [ ] Tests: `frontend/test/tool/backlog_report_test.dart` runs over a fixture plan and asserts grouping, ordering and
      the inclusion of a waived gate and a friction entry.
- [ ] The sign-in run passes with the backend reachable exactly once, at sign-in.
- [ ] No assertion in that run depends on a provider key existing on the device.
- [ ] After both cache lifetimes expire offline, capture, review, edit and export still work, and only relay, the
      proxy and a role change are refused.
- [ ] A failure anywhere in the offline stretch fails the release gate, not just that test.
- [ ] Tests: `signin_proxy_offline_test.dart` itself, running in the pipeline's integration job.

## Out of scope

- Relay, which is not in the MVP (A67, A72).
