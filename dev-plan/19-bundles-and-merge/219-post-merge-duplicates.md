# 219 — Post-merge duplicate scan

**Phase** 19 · Bundles and merge  |  **Depends on** [172](../15-data-quality/172-identity-hash.md), [218](218-merge-apply.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Two people captured the same asset independently, so the merge produced two records with different identifiers and no
conflict. The scan runs automatically after every applied merge and lists the suspected pairs for review.

## Files

- `frontend/lib/features/merge/domain/post_merge_scan.dart` (new)

## Steps

1. Compare only across the merge boundary — an incoming record against a local one — so pre-existing duplicates are not
   re-reported.
2. Score pairs with the detector of 320; attach the resulting pairs to the merge record so they survive a restart.
3. Run the scan off the UI thread after the transaction commits, and never block the merge on it.

## Constraints

- Reuse the detector of 320 unchanged; a second similarity implementation is a defect (FE-CONS-02).
- The scan proposes; nothing is merged or deleted without a person (FE-SEC-09).

## Definition of done

- [ ] The scan runs automatically after every merge and lists candidate pairs with their scores for review.
- [ ] Pairs survive a restart, and a merge whose scan finds nothing shows that plainly.
- [ ] Tests: unit tests of `post_merge_scan.dart` over a fixture where the same asset was captured on both devices, asserting cross-boundary-only comparison, with no Flutter binding.
