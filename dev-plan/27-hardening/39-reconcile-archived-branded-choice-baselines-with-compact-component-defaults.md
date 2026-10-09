# 160 — Reconcile archived branded choice baselines with compact component defaults

**Depends on** [003](../03-design-system.md), [157](../24-product-refinements.md#157--reduce-shared-component-internal-padding)

## Implement

Determine which archived branded-choice baselines match the current compact component defaults from task 157. Restore verified matching originals when available; otherwise propose a separately reviewed baseline update after proving the difference against `d921abb0`. Preserve prior images, manifests, rendering assertions and zero-test-PNG delivery. Task 158 authorizes regeneration only of its new direct-presenter gallery, not these existing branded-choice images.

## Files

- `frontend/test/core/widgets/fields/app_choice_field_branding_test.dart`
- External `TaptureTestArchives` image archives and their relative-path/SHA-256 manifests
- `frontend/lib/core/widgets/fields/app_choice_field.dart` (diagnosis only unless a defect is proved)

## Definition of done

- [ ] Baseline comparison against `d921abb0` establishes the cause of all twelve mismatches without relying on a completion claim.
- [ ] Matching originals are restored or intended updates are reviewed and normal comparisons pass across all twelve existing corners.
- [ ] Every image is preserved externally with verified relative paths and hashes; zero test PNGs remain, and tracker synchronization and plan checks pass.

## Evidence

2026-10-09: task 158 restored 36 choice/context images only after verifying their original archive lengths and SHA-256 hashes. All twelve `choice_branded_*` comparisons fail against the restored task-153 verification archive. Task 157's newer archive contains component-gallery images and no branded-choice images. Attribution to compact padding remains an inference until the baseline comparison is run; the failures are retained and no acceptance waiver is inferred.

Baseline verification: an isolated archive of `d921abb0` reproduces all twelve failures. Each baseline actual image has the same SHA-256 as the corresponding task-158 actual image (`frontend/build/task158-baseline-image-comparison.json`); Capture setup does not change these rendered outputs. Cause/baseline reconciliation remains open.
