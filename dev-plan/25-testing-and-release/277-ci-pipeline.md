# 277 — Continuous integration pipelines

**Phase** 25 · Testing and release  |  **Depends on** [003](../01-orchestration/003-strict-lints.md), [271](271-test-harness-unit.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Two workflows: a per-push pipeline running format, analyze, unit, widget and golden tests for the app, and an emulator
job running the integration suite nightly and before every release. The app pipeline reports success only when the
backend pipeline (496) is green on the same commit, because neither artefact ships alone.

## Files

- `.github/workflows/ci.yml` (new)
- `.github/workflows/integration.yml` (new)

## Steps

1. `ci.yml` on every push: cache pub and Gradle dependencies, run the verify command, fail on analyzer warnings, and
   upload golden failure images as artefacts.
2. In `ci.yml`, require the backend workflow's conclusion on the same commit; a red backend makes this pipeline red.
3. `integration.yml`: boot an Android emulator, run `frontend/integration_test/` with no network, on a nightly schedule
   and on release branches. Include `signin_proxy_offline_test.dart` (521) in that run.
4. Give each workflow one failing exit for any failing step — no step is allowed `continue-on-error`.

## Constraints

- Guardrail suites are never skipped or excluded to make a pipeline pass (FE-TEST-06).
- The emulator job runs with the network disabled and no real provider credentials present (FE-TEST-05, FE-SEC-02).

## Definition of done

- [ ] A red pipeline blocks merging, and a red backend pipeline on the same commit makes `ci.yml` red.
- [ ] The integration suite runs nightly and before every release, on an emulator, offline.
- [ ] A golden failure leaves a downloadable image behind.
- [ ] Tests: one run per workflow against a branch with a single deliberately broken step, proving each gate fails and
      names the step.
