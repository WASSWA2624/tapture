# 240 — Performance pass: lists, indexes, start-up, memory and background work

**Phase** 23 · Hardening  |  **Depends on** [019](../02-foundation/019-app-bootstrap.md), [024](../02-foundation/024-hashing-service.md), [068](../05-file-storage/068-thumbnail-cache.md), [160](../13-processing/160-auto-process-on-connect.md), [163](../14-records/163-records-list.md), [164](../14-records/164-records-search.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One measured pass over the five performance budgets on a mid-range device: smooth lists and photo grids, indexed
queries, cold start inside budget, memory that returns to baseline, and a single background-work policy every job
consults. Each fix ships with the measurement that proves it.

## Files

- `frontend/lib/features/records/presentation/records_list_screen.dart` (edit)
- `frontend/lib/core/db/migrations.dart` (edit)
- `frontend/lib/main.dart` (edit)
- `frontend/lib/core/background/background_policy.dart` (new)
- `frontend/tool/profile_memory.dart` (new)
- `frontend/integration_test/memory_test.dart` (new)
- `frontend/test/core/background/background_policy_test.dart` (new)

## Contract

```dart
class BackgroundPolicy {
  bool mayRun({required bool charging, required bool idle, required NetworkState net, required bool foreground});
}

Future<MemoryReport> measure(Future<void> Function() scenario, {required int ceilingMb});
```

## Steps

1. Lists and grids: virtualise and page, render thumbnails only (121), narrow rebuilds to the changed row, and cap
   concurrent image decodes. Measure frame times while scrolling ten thousand records and two thousand photos.
2. Indexes: time the list, search (303), filter (304), duplicate lookup and queue queries against a large seeded
   database, add the indexes they need in `migrations.dart`, and record each query's before and after timing.
3. Cold start: defer non-essential bootstrap work (023), lazy-load providers and remove disk scans from the launch
   path, until the project list renders inside the budget.
4. Memory: drive a two-hundred-record capture session, a five-thousand-record export and a two-thousand-photo merge,
   sampling resident memory throughout. Fail on a ceiling breach or on memory not returning to baseline, then fix every
   leak exposed — undisposed isolates, unclosed streams, retained image handles.
5. Background policy: on-device OCR only while charging and idle, automatic processing only when the setting and the
   network allow (297), and nothing at all while the app is in the foreground. Route background OCR (298) and automatic
   processing through this one object so the rule exists in exactly one place.

## Constraints

- Every performance claim ships its measurement; no optimisation lands unmeasured (FE-PERF-06, FE-TEST-09).
- Heavy work runs through `runIsolate` (033); the UI thread does none of it (FE-PERF-02).
- Memory returns to baseline after each scenario rather than merely staying under the ceiling (FE-PERF-09).

## Definition of done

- [ ] Scrolling ten thousand records and two thousand photos holds the frame budget on the low-end device class.
- [ ] Every screen query is measured, indexed where it needed one, and its timings recorded; cold start reaches the
      project list inside budget.
- [ ] A deliberately leaked stream subscription fails the memory test, and a job bypassing the policy fails the policy
      test.
- [ ] Tests: frame-time test over the records list and photo grid; query-timing test on a large seeded database;
      start-up timing test; `frontend/integration_test/memory_test.dart` across the three scenarios, run nightly;
      `background_policy_test.dart` plus a job test proving background work stops within one poll interval of the app
      returning to the foreground.
