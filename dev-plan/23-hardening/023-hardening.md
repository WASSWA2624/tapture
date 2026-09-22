# 023 — Hardening: fast, legible, reachable and unbreakable in the field

**Phase** 23 · Hardening  |  **Depends on** [001](../01-orchestration/001-project-setup.md), [002](../02-foundation/002-foundation-services.md), [003](../03-design-system/003-design-system.md), [006](../06-app-shell/006-application-shell.md), [012](../12-capture/012-capture.md), [013](../13-processing/013-processing.md), [014](../14-records/014-records.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One hardening pass over the whole app, leaving it fast, legible, reachable and hard to break in the field: every
primary screen driven through the size-class matrix, the accessibility matchers and 200 percent text scale, with each
defect fixed in the screen or in the design-system widget rather than waived; landscape and hinged displays supported
everywhere, the two-pane layout split at the fold, and rotating, folding or unfolding never costing the operator an
in-progress capture; every user-facing string rewritten into plain language and one voice, then extracted into ARB
files and verified against a pseudo-locale, so nothing is translated yet and nothing needs a code change when it is;
the suite that fails when a collection or detail screen renders nothing useful with no data, and the shared empty
state with a named next action on every screen it catches; a measured pass over the five performance budgets on a
mid-range device — smooth lists and photo grids, indexed queries, cold start inside budget, memory that returns to
baseline, and a single background-work policy every job consults — each fix shipping the measurement that proves it;
the harness that forces any injectable dependency to fail on demand and the suite that drives each one into failure
and proves the app stays usable with its evidence intact; the Tapture identity applied everywhere the platforms ask
for it — launcher icon, Android adaptive icon, splash and store listing assets, all generated from one vector source
per mark and reachable through typed constants; the script that runs the integration suite across the configured
device classes, captures the field-critical timings on each and fails the run when one regresses against the stored
baseline; and the one-tap "something went wrong here" action a field tester uses during a trial, with the local log
behind it that the tester exports by hand.

## Files

### Audit and state suites

- `frontend/test/responsive/` (new)
- `frontend/test/accessibility/` (new)
- `frontend/test/states/empty_state_coverage_test.dart` (new)

### Shell and layout

- `frontend/lib/app/nav_shell.dart` (changed)

### Copy and localisation

- `frontend/lib/core/copy/copy.dart` (changed)
- `frontend/lib/l10n/` (new)

### Performance and background work

- `frontend/lib/features/records/presentation/records_list_screen.dart` (changed)
- `frontend/lib/core/db/migrations.dart` (changed)
- `frontend/lib/main.dart` (changed)
- `frontend/lib/core/background/background_policy.dart` (new)
- `frontend/tool/profile_memory.dart` (new)
- `frontend/integration_test/memory_test.dart` (new)
- `frontend/test/core/background/background_policy_test.dart` (new)

### Failure injection

- `frontend/test/support/fault_injection.dart` (new)
- `frontend/integration_test/failure_paths_test.dart` (new)

### Branding

- `frontend/assets/branding/` (new)
- `frontend/lib/core/assets/branding_assets.dart` (new)
- `frontend/pubspec.yaml` (changed)

### Device matrix

- `frontend/tool/devices.yaml` (new)
- `frontend/tool/device_matrix.dart` (new)
- `frontend/test/tool/device_matrix_test.dart` (new)

### Field trial

- `frontend/lib/features/settings/domain/friction_log.dart` (new)
- `frontend/lib/features/settings/presentation/friction_log_button.dart` (new)

## Contract

```dart
Future<void> expectEmptyState(WidgetTester t, {required String action});

class BackgroundPolicy {
  bool mayRun({required bool charging, required bool idle, required NetworkState net, required bool foreground});
}

Future<MemoryReport> measure(Future<void> Function() scenario, {required int ceilingMb});

class FaultInjector {
  void fail(Dependency d, Failure f);
  void clear();
}

Future<int> main(List<String> args)  // --devices low,mid,tablet

Future<Result<void>> logFriction({required String screen, String? note, bool withScreenshot = false});
```

## Steps

1. Run the layout, accessibility and text-scale audit first, because everything after it inherits the matrix. Pump
   every primary screen through the shared pump harness that the testing and release phase owns, at compact, medium
   and expanded widths in both orientations, asserting no overflow, no truncated label, correct two-pane behaviour and
   a reachable primary action. Run the accessibility matchers of task 017 over the same screens and over the widget
   gallery of task 047: 48dp targets, a label on every control, traversal order matching visual order, and measured
   contrast in light, dark and outdoor themes. Repeat the whole matrix at 200 percent text scale, asserting no
   clipping, no overlap and no unreachable button. Fix each failure where it belongs — a defect shared by several
   screens is fixed once in the design system, not patched per screen (FE-CONS-02).
2. Make capture and review work in landscape and on a hinged display. Navigation adapts to the size class while state
   stays owned by its providers, so a rotation rebuilds the chrome and nothing else (FE-RESP-03). When a display
   feature reports a hinge, place list and detail either side of it rather than letting content sit under the fold.
   Preserve the in-progress capture across every configuration change: draft field values, queued photos, an active
   recording and scroll position.
3. Take one pass over every user-facing string, then extract them all. Replace jargon, and make every error state —
   the shared error state of task 040 — say what happened and what to do next, in the same voice everywhere
   (FE-SIMP-10, FE-CONS-11). Move every visible literal out of widgets into the generated localisations behind the
   copy helper of task 046; keys name meaning, not position (FE-L10N-01, FE-L10N-02). Use placeholders with
   descriptions and ICU plurals and selects; never assemble a sentence from fragments (FE-L10N-03). Run the
   pseudo-locale, expanded 35 percent, through the responsive matrix built in step 1 and fix the layouts it breaks
   (FE-L10N-06).
4. Close the empty-state gap. Enumerate every screen that renders a collection, pump each against an empty repository
   fake, and assert the shared empty state of task 040 with a primary action is shown. Replace every bespoke "nothing
   here" string found with the shared widget, and give each one an action naming what to do next.
5. Measure and fix the five performance budgets on a mid-range device, each fix shipping its measurement. Lists and
   grids: virtualise and page, render thumbnails only as capture already does (task 107), narrow rebuilds to the
   changed row, and cap concurrent image decodes; measure frame times while scrolling ten thousand records and two
   thousand photos. Indexes: time the list, search, filter, duplicate lookup and queue queries against a large seeded
   database, add the indexes they need in `migrations.dart`, and record each query's before and after timing. Cold
   start: defer non-essential bootstrap work (task 019), lazy-load providers and remove disk scans from the launch
   path, until the project list renders inside the budget. Memory: drive a two-hundred-record capture session, a
   five-thousand-record export and a two-thousand-photo merge, sampling resident memory throughout; fail on a ceiling
   breach or on memory not returning to baseline, then fix every leak exposed — undisposed isolates, unclosed streams,
   retained image handles. Background policy: on-device OCR only while charging and idle, automatic processing only
   when the setting and the network allow, and nothing at all while the app is in the foreground; route background OCR
   and automatic processing through this one object so the rule exists in exactly one place.
6. Build the fault injector and the failure-path suite over it. Make every injectable service consult the injector, so
   a test can fail it per case and restore it with `clear`. Cover camera denied, microphone denied, storage full,
   provider unreachable, key invalid, response malformed, bundle corrupt, database locked and the process killed
   mid-capture. Assert for each case: nothing captured is lost, the message names what happened and the next step, and
   the retry path actually completes.
7. Apply the identity. Keep one vector source per mark and generate every density and platform size from it; no
   hand-resized bitmap. Keep the icon legible at 48 pixels — no fine detail, no text. Build the splash from the
   assembled theme's tokens (task 031) plus the mark, so it matches light, dark and outdoor rather than baking in one
   background colour. Expose every generated path as a constant in `branding_assets.dart`; no widget or platform file
   names a raw path.
8. Deliver the device matrix runner. Declare the device classes, their identifiers and their per-metric tolerances in
   `devices.yaml`. Run the integration suite on each attached device, capturing cold start, shutter latency, export
   duration and merge duration. Write a comparison report against the stored baseline and exit non-zero when a metric
   regresses beyond its tolerance, naming device, metric and margin. Skip an unattached class with a named warning
   rather than passing silently as if it had run.
9. Finish with the in-app friction log. Record screen, timestamp, operator, project, the last user action and an
   optional note and screenshot, all on the device. Expose the action from the overflow menu on every screen while the
   trial flag is enabled, and from nowhere when it is off. Capture happens without leaving the current task: the sheet
   takes an optional note and dismisses back to the same screen state. Export the whole log with its screenshots as
   one file from settings, through the log export action of task 022.

## Constraints

### Guardrails

- Every suite and checker here is a guardrail, so each one passes on the current tree, fails on a deliberate
  violation, ships the fixture proving both, and reports every violation it finds with file and line rather than
  stopping at the first: the responsive and accessibility sweeps, the string-literal scanner, the ARB completeness
  check, the empty-state coverage suite, the memory and background-policy tests, the failure-path suite and the
  device matrix runner alike.

### Layout, orientation and accessibility

- Features never measure the screen; size class comes from the shared breakpoint API (FE-RESP-02).
- No waiver list and no skipped screen: a failing screen is fixed (FE-A11Y-10).
- Contrast and target assertions run in all three themes (FE-A11Y-04, FE-THEME-10).
- Both orientations are supported on every screen; no screen locks rotation (FE-RESP-07).
- Insets and cutouts are respected in landscape, where they bite hardest (FE-RESP-08).

### Copy and localisation

- Template field labels, option lists and template names are user data and are never localised or matched against a
  translation (FE-L10N-07).
- A key without a translation fails the release build rather than reaching a user (FE-L10N-09).
- Dates, numbers and percentages come from `intl` with the active locale, never hand-built (FE-L10N-04).
- Empty tells the operator what to do next, never merely that there is nothing (FE-SIMP-11).
- The screen list is derived from the router, so a new collection screen is covered without editing the test
  (FE-CONS-04).

### Performance and resilience

- Every performance claim ships its measurement; no optimisation lands unmeasured (FE-PERF-06, FE-TEST-09).
- Heavy work runs through `runIsolate` (task 024); the UI thread does none of it (FE-PERF-02).
- Memory returns to baseline after each scenario rather than merely staying under the ceiling (FE-PERF-09).
- Every injectable dependency has a case; adding one without a case fails the suite (FE-TEST-10).
- The failure-path suite runs offline with no real provider reachable (FE-TEST-05).
- Degradation is partial and named, never a freeze or a blank screen (FE-PERF-10).

### Assets, tooling and privacy

- Assets are referenced through typed constants only (FE-STR-12).
- The splash uses tokens, never a hardcoded colour (FE-THEME-01).
- The device matrix runner reports every regression it finds, not just the first.
- Tolerances live in `devices.yaml`, never in Dart (FE-CODE-09).
- Nothing in the friction log is transmitted: no upload, no crash service, no analytics (FE-SEC-10).
- Screenshots are stored beside the log under the app's own storage and are removed with it.

## Definition of done

### Layout, orientation and accessibility

- [ ] No screen overflows, hides its primary action, clips at maximum text scale, or carries an unlabelled control at
      any supported width, orientation or theme.
- [ ] Traversal order matches visual order, every control carries a label and a 48dp target, and measured contrast
      passes in light, dark and outdoor.
- [ ] A deliberately unlabelled icon button and a deliberately fixed-height row each fail the suite.
- [ ] Rotating or folding during capture keeps the draft record, the queued photos, any active recording and the
      scroll position.
- [ ] Tests: `frontend/test/responsive/` widget tests capturing each screen at three widths in both orientations,
      asserting no overflow, no truncated label, correct two-pane behaviour and a reachable primary action.
- [ ] Tests: `frontend/test/accessibility/` assertions per screen and over the widget gallery, including the 200
      percent scale case.
- [ ] Tests: widget tests of `nav_shell.dart` rotating and simulating a hinge mid-capture, asserting draft values,
      queued photos and recording state survive, and that the two-pane split follows the hinge.

### Copy and localisation

- [ ] No message contains a technical term the user cannot act on, and no user-facing literal remains in a widget.
- [ ] Every error state says what happened and what to do next, in the same voice everywhere.
- [ ] Adding a language later requires no code change, and switching locale rebuilds the interface without losing an
      in-progress capture (FE-L10N-10).
- [ ] Tests: a scanner test failing on a string literal in a widget file.
- [ ] Tests: an ARB completeness test failing on a key missing from a locale.
- [ ] Tests: a pseudo-locale layout run, expanded 35 percent, over the primary screens.

### Empty states

- [ ] A new collection screen without an empty state fails the suite.
- [ ] Every empty state names its next action, and none renders a bare message.
- [ ] Tests: `empty_state_coverage_test.dart` itself, one case per collection screen, plus a fixture screen proving
      the matcher fails when the empty state is missing.

### Performance and background work

- [ ] Scrolling ten thousand records and two thousand photos holds the frame budget on the low-end device class.
- [ ] Every screen query is measured, indexed where it needed one, and its before and after timings recorded.
- [ ] Cold start reaches the project list inside budget.
- [ ] Memory returns to baseline after the capture, export and merge scenarios, with every leak they expose fixed.
- [ ] A deliberately leaked stream subscription fails the memory test, and a job bypassing the policy fails the policy
      test.
- [ ] Tests: frame-time test over the records list and the photo grid.
- [ ] Tests: query-timing test on a large seeded database.
- [ ] Tests: start-up timing test.
- [ ] Tests: `frontend/integration_test/memory_test.dart` across the three scenarios, run nightly.
- [ ] Tests: `background_policy_test.dart`, plus a job test proving background work stops within one poll interval of
      the app returning to the foreground.

### Failure injection

- [ ] Every injected failure leaves the app usable, the raw evidence intact and a retry that works.
- [ ] Adding an injectable dependency without a case fails the suite.
- [ ] Tests: `frontend/integration_test/failure_paths_test.dart` with one case per dependency — camera denied,
      microphone denied, storage full, provider unreachable, key invalid, response malformed, bundle corrupt, database
      locked and the process killed mid-capture — plus a fixture proving the injector itself fails a call and restores
      it on `clear`.

### Branding

- [ ] The icon is recognisable at 48 pixels on a crowded home screen, and the splash matches the active theme in
      light, dark and outdoor.
- [ ] Tests: a test asserting every constant in `branding_assets.dart` resolves to a file that exists, at every
      density the platforms require, and that no declared asset is unreferenced.

### Device matrix

- [ ] A regression on the low-end device fails the run, naming the device, the metric and the margin; an unattached
      device class is reported, not ignored.
- [ ] Tests: `frontend/test/tool/device_matrix_test.dart` parses fixture output and asserts the comparison logic,
      including a within-tolerance pass, a beyond-tolerance failure and a missing-device warning.

### Field trial

- [ ] A tester flags a problem in one tap and stays exactly where they were, with a draft record untouched.
- [ ] The log stays local until the tester exports it, and the export contains every entry and every screenshot.
- [ ] Tests: test that an entry captures screen, project and last action.
- [ ] Tests: test that export contains every entry and every screenshot.
- [ ] Tests: test that the action is absent with the trial flag off.

## Out of scope

- Translating anything. This phase extracts every string and proves the scaffolding against a pseudo-locale; shipping
  a second locale is its own task.
- The shared pump harness the responsive sweep runs on, the end-to-end suites the device matrix runner executes, and
  wiring that runner into the pipeline; all three belong to the testing and release phase.
