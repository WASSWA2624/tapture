# 093 — Audit implementation and efficiency against the full plan

**Implementation step:** 24.55

**Phase** 24 · Product refinements  |  **Standard** [STANDARD.md](../STANDARD.md)

**Implementation started:** Yes

## Implement

Review the repository against all existing implementation tasks except steps 25 and 26, repair concrete gaps,
and improve durability, bounded work and shared UI reuse. Review the pre-existing staged/unstaged changes before
including them in incremental GitHub commits. Update original task acceptance records with executable evidence;
keep real-device, deployment and whole-product verification open when it has not run.

Inspect step 27 and remove its contents only if its implementation and acceptance are already complete. Its
unchecked whole-product requirements and unfinished excluded prerequisites currently make that condition false.
Retain the final hardening folder and its stable task 023 reference.

## Files

- Original task checklists in `dev-plan/01-*` through `24-*`; `27-hardening/023-hardening.md`
- `frontend/lib/`, corresponding tests and intentional synthetic golden baselines
- `frontend/.gitignore`, frontend guardrails and generated tracker/index/folder summaries
- `backend/src/`, repositories, migrations, OpenAPI contract, deployment and tests
- `run-tools/common.py`, web/Android entry points and script regression tests

## Definition of done

- [x] Audit work preserves and reviews existing local changes; the user's instruction includes reviewed pre-existing changes.
- [x] Steps 25 and 26 receive no feature implementation; the incomplete hardening plan is retained under the conditional deletion request.
- [ ] Every included original task satisfies its complete Definition of done; unverified hardware, deployment and performance criteria remain open.
- [ ] Concrete code fixes pass their regression tests and the standard frontend/backend gates on the final tree.
- [ ] Synthetic UI baselines are reviewed and committed, with failure dumps and captured evidence excluded.
- [ ] Acceptance source changes and automatically synchronized tracker views accompany the implementation commits.
- [ ] Reviewed changes are committed incrementally and pushed to GitHub.

## Audit evidence — 2026-09-30

The audit covers shared foundation/design/database/storage/navigation, every application feature and the backend.
Original checklists retain distinct requirements and stable task references. Concrete repairs include worker
exit/cancellation, authenticated database recovery, project-relative integrity checks, safe export publication,
scoped/password bundles, causal merge/conflict/history/undo, secure cloud checkpoints and native account/folder ports.
Only generated summary updates touch excluded steps 25 and 26. Step 27 remains because its acceptance is incomplete.

Historical focused evidence: foundation/accessibility 16 passes; encryption 6; integrity/writers 10; cache 8;
native storage/archive 21. A 400 MiB archive fixture completed in 18,627 ms with about 31 MiB additional sampled
process RSS against its 120 MiB ceiling. These host measurements do not certify physical-device performance.

## Frontend checkpoint — 2026-10-01

The initial reviewed UI checkpoint passed 648 collection layout/accessibility cells, six Projects title-bar menu
cases and 47 screenshot suites (259 cases). Subsequent changes expand coverage to all 35 primary screen fixtures,
add inherited English/pseudo catalogues and preserve semantic errors through durable state while keeping English
text for audit and older clients. The affected domain libraries compile and execute on the plain Dart VM.
These changes require the final current-tree analyzer, regressions, layout matrices and browser run before acceptance.

Actual browser IndexedDB integration previously passed three named cases: durable evidence reopening, preservation
after an interrupted write and bounded thumbnail recovery through a new service. Production processing,
export/download, thumbnail rendering and asynchronous password/cipher browser fixtures are now added; their final
Chrome execution remains pending. Native SDK consent, removable-folder grants, biometrics and OS incoming transports
require actual platform checks. Android Kotlin/resources/manifest/link compilation passed all 315 targets again
after the final share-intent and AppCompat theme changes. The freshly merged Android manifest passed the real-output
permission review; iOS aggregate privacy verification requires Xcode.

## Durability and bounded-work checkpoint — 2026-10-01

Photo inspection retains current/neighbor originals with serial reads. Project/template rows build lazily.
Native attachment imports stream through the atomic writer; metadata and browser packages have explicit ceilings.
Queue summaries omit historical failure arrays, and one indexed 50-row keyset failure page stays live with retries.
Relay preflights the deployment's 20,000,000-byte ciphertext limit before a whole native read and encrypts on a worker.
Native package operations use cancellable workers and parent-owned scratch; compatible browser encryption yields
between aligned AES chunks and authenticates asynchronously. Focused final regressions remain pending.

The indexed duplicate scan preserved the frozen prior pairs/scores/priority across 100 randomized pure-Dart datasets.
The 100-incoming/10,000-local identity fixture measured 755,195 microseconds for 1,000,000 all-pairs comparisons versus
73,963 microseconds indexed, retaining 100 matches. The bounded asynchronous logger reduced a 1,000-entry desktop
caller's time from 45,430,771 to 32,331 microseconds; final flush took 27,132 microseconds. Logging/thumbnail services
passed 20 cases, opaque relay pagination eight and authenticated database recovery eight before the final locale edits.

Ten offline host fault cases passed, including an actual SQLite lock and killed SQLite child. The combined earlier
foundation run passed 318 cases and exposed eleven generated/test-fixture failures; those were repaired with further
regressions. Strict retained-RSS measurements remain open: resource counters returning to zero do not prove RSS
returned to baseline, and the same measured capture/export/merge scenarios must be rerun after streaming changes.
Physical cold-start, frame, battery, camera, recording, permission and provider budgets remain open.

Current database, permission, verification-runner, incoming-service and duplicate regressions passed 302 cases;
thumbnail regressions passed 19 and the real bootstrap error-handler fixture passed separately. Migration coverage
includes every released version through schema 31 and retains prior error text alongside semantic descriptors.
The cloud/security batch passed 243 cases and exposed eleven failures. Cancellation must unwind native ZIP handles
before scratch removal, password derivation must remain strong and efficient, and isolated locale/biometric fixtures
must use their proper boundaries. Those repairs and the final full gates are still in progress.

Backend checkpoints `202cd1d5` and `bd855380` are committed, pushed and verified against the remote branch. Scoped
collections use bounded keyset pagination/composite indexes, and limiter buckets preserve active limits with bounded
retention. Five additional real-PostgreSQL tests cover identity, scoped/cross-organisation membership, actual CLI
export/destroy, transactional pool draining and exact-expiry relay cleanup. Final backend verify/build pass: 136
successful tests, nine explicit PostgreSQL/Docker skips, zero audit vulnerabilities. Skips do not satisfy real-database,
live deployment or protected-CI acceptance. Frontend commits and final gate evidence follow after verification.

## Requested run-script checkpoint — 2026-10-01

The exact web entry point compiled and served the application at localhost:5173. The initial Chrome load exposed
a view-focus geometry assertion. A public binding coordinator now delays only the initial focus transfer until
its target has layout; seven engine-boundary regressions pass. The exact script retry compiled in 109.6 seconds.
Fresh Chrome checks rendered Projects, its menu, Settings and Language with no startup assertion or console error.
The Android entry point initially could not connect to its Gradle daemon because the shortened Windows socket
directory only reached the launcher. Commit `f8ab255d`, pushed and remotely verified, passes the setting to the
daemon through `JAVA_TOOL_OPTIONS` while preserving caller options; three Python regressions pass. The exact
Android entry point then completed `assembleProdRelease` and copied a fresh 189,525,581-byte universal release
APK to `run-tools/dist/android/app-release.apk`. No ADB device is connected, so native installation/launch remains
unverified. Subsequent source repairs require a final build of the final tree before completion is claimed.

## Current efficiency checkpoint — 2026-10-01

The coherent streaming, cancellation, paging, lazy photo-grid/viewer and feedback-archive batch passed 213 of 213
tests. A refused atomic writer now cancels an already-open native source even before accepting its first chunk.
The actual record screen builds only visible photo tiles; 240 continuous host drag samples measured a 66,099
microsecond p90 and 320,838 microsecond worst frame within the unchanged host gate. These are host measurements,
not physical-device frame acceptance.

Capture 200, export 5,000 and merge 2,000-photo workloads passed their three functional/resource tests. The exact
strict command `dart run tool/profile_memory.dart build/memory-profile.json 134217728 0` failed its three retained
RSS checks. Additional peaks were 97.57, 37.00 and 123.93 MiB; retained RSS was 39.50, 21.95 and 69.95 MiB respectively.
Databases, subscriptions, bundles, containers and isolates returned to zero. No baseline allowance, forced garbage
collection or operating-system working-set manipulation was introduced; memory baseline acceptance remains open.

The follow-up audit found two concrete data-path gaps: bootstrap did not bind the real record repository, and
field deletion used an empty count provider without retiring stored values. Production bindings, fresh scoped
count queries, transactional value retirement and historical retired-value exports now have source repairs and
real database/UI regressions; their current-tree verification is pending. Desktop external-browser PKCE is tracked
in [098](../21-cloud-upload/098-desktop-oauth-sign-in.md), with registered provider consent still unverified.

## Incremental publishing checkpoint — 2026-10-01

Plan/evidence commit `e4ef641e` is pushed and its hash matches the remote branch. The publication review found no
captured evidence, credentials or oversized artifacts in the pending changes. Source, generated catalogues,
migrations, native integrations and their regressions remain a coupled application checkpoint.

Current backend verification passes with 136 successful tests, nine explicit database/Docker skips and zero audit
vulnerabilities. The real native PDFium capture batch passes 22 tests without skips. The initial golden run passed
251 cases and found five failures; visual review confirmed six intentional branding/gallery image updates, while
an explicit thumbnail readiness condition preserved all three existing missing-photo baselines. All seven affected
golden cases pass on rerun.

Preparation exposed formatting/analyzer issues and ten guardrail failures. Repairs preserve the architecture rules,
generated-source inclusion and literal-duration detection, and distinguish runtime serialization from style tokens.
Focused tooling checks pass 29 cases; feature architecture and affected regressions pass. Disposable-file cleanup
now proves fresh ownership and exclusive creation before deletion. The focused cleanup batch passes 62 durability,
10 safety and eight related-service tests, including preservation of a concurrently created cipher target.
The publication hook then found three redundant test imports, two missing queue type tests and a transitive
Flutter dependency in the plain-Dart domain probe. Import repairs and queue identity/cursor tests pass 45 focused
cases with a clean analyzer; all owed source files now have tests. Feedback workbook code imports its existing
pure XLSX types directly, and the unchanged 19-library headless probe plus 11 affected regressions pass.
An independent review also exposed marker-path aliases and published temporary roots escaping the cleanup proof;
those negative cases require stronger ownership checks before the application checkpoint can be committed.
Final aggregate verification and application publication remain pending; unverified acceptance stays open.
