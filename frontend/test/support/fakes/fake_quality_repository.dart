import 'dart:async';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/quality/quality.dart';
import 'package:tapture/features/records/records.dart' show RecordPhoto;

/// The quality store in memory (task 015): pairs, variances, missing items
/// and counts as given, every resolution recorded in the order it came.
///
/// Set [failure] to make every read fail; clear it and retry to read again.
final class FakeQualityRepository implements QualityRepository {
  /// Creates a store holding [pairs], [variances], [missing] and [counts].
  FakeQualityRepository({
    List<DuplicatePairView> pairs = const <DuplicatePairView>[],
    this.variances = const <RecordVariance>[],
    this.missing = const UncapturedRows(<String>[], <String>[]),
    this.counts = (invalid: 0, duplicates: 0, conflicts: 0, unreviewed: 0),
    this.counterparts = const <DuplicateCounterpart>[],
    this.scanResult = 0,
    this.failure,
  }) : pairs = List<DuplicatePairView>.of(pairs);

  /// Unresolved pairs; a resolution removes its pair.
  final List<DuplicatePairView> pairs;

  /// Stored variances.
  final List<RecordVariance> variances;

  /// Register rows not found and checklist rows not captured.
  final UncapturedRows missing;

  /// The counts the summary reads.
  QualityCounts counts;

  /// What every record's badge lists.
  final List<DuplicateCounterpart> counterparts;

  /// How many new pairs a scan reports.
  final int scanResult;

  /// When set, every read fails with it.
  Failure? failure;

  /// Every resolution applied, in order.
  final List<(String, DuplicateResolution)> resolved =
      <(String, DuplicateResolution)>[];

  /// How many scans ran.
  int scans = 0;

  /// Record ids every scan was asked about, in order.
  final List<String> scanned = <String>[];

  /// When set, a scan does not finish until this completes, as a slow
  /// detection would.
  Completer<void>? holdScans;

  /// How many times each watch was opened, by name.
  final Map<String, int> reads = <String, int>{};

  Stream<T> _watch<T>(String name, T Function() value) {
    reads[name] = (reads[name] ?? 0) + 1;
    final Failure? failed = failure;
    if (failed != null) {
      return Stream<T>.error(failed);
    }
    return Stream<T>.value(value());
  }

  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// The pairs now, then again after every resolution, as the Drift store
  /// re-emits after a write.
  @override
  Stream<List<DuplicatePairView>> watchUnresolvedPairs(
    String projectId,
  ) async* {
    reads['pairs'] = (reads['pairs'] ?? 0) + 1;
    final Failure? failed = failure;
    if (failed != null) {
      throw failed;
    }
    yield List<DuplicatePairView>.unmodifiable(pairs);
    await for (final void _ in _changes.stream) {
      yield List<DuplicatePairView>.unmodifiable(pairs);
    }
  }

  @override
  Future<Result<DuplicatePairView?>> pair(String pairId) async {
    reads['pair'] = (reads['pair'] ?? 0) + 1;
    final Failure? failed = failure;
    if (failed != null) {
      return FailureResult<DuplicatePairView?>(failed);
    }
    for (final DuplicatePairView each in pairs) {
      if (each.id == pairId) {
        return Success<DuplicatePairView?>(each);
      }
    }
    return const Success<DuplicatePairView?>(null);
  }

  @override
  Stream<List<DuplicateCounterpart>> watchCounterparts(String recordId) =>
      _watch<List<DuplicateCounterpart>>('counterparts', () => counterparts);

  @override
  Future<Result<int>> scanRecords(List<String> recordIds) async {
    scans += 1;
    scanned.addAll(recordIds);
    await holdScans?.future;
    return Success<int>(scanResult);
  }

  @override
  Future<Result<int>> scanProject(String projectId) async {
    scans += 1;
    return Success<int>(scanResult);
  }

  @override
  Future<Result<void>> resolve(
    String pairId,
    DuplicateResolution resolution,
  ) async {
    resolved.add((pairId, resolution));
    pairs.removeWhere((DuplicatePairView each) => each.id == pairId);
    _changes.add(null);
    return const Success<void>(null);
  }

  @override
  Stream<List<RecordVariance>> watchVariances(String projectId) =>
      _watch<List<RecordVariance>>('variances', () => variances);

  @override
  Future<Result<UncapturedRows>> missingItems(String projectId) async {
    final Failure? failed = failure;
    if (failed != null) {
      return FailureResult<UncapturedRows>(failed);
    }
    return Success<UncapturedRows>(missing);
  }

  @override
  Stream<QualityCounts> watchCounts(String projectId) =>
      _watch<QualityCounts>('counts', () => counts);
}

/// A pair [id] of two records named [existing] and [incoming], filed under
/// [signal] and [template], differing in [differences].
DuplicatePairView fakePair(
  String id, {
  String existing = 'Pump',
  String incoming = 'Pump (new)',
  DuplicateSignal signal = DuplicateSignal.identity,
  String templateId = 'template-1',
  String template = 'Assets',
  List<DuplicateDifference> differences = const <DuplicateDifference>[
    (fieldKey: 'serial', label: 'Serial', existing: 'A-1', incoming: 'A-2'),
  ],
  List<RecordPhoto> incomingPhotos = const <RecordPhoto>[],
}) {
  return DuplicatePairView(
    id: id,
    projectId: 'project-1',
    signal: signal,
    score: 0.9,
    templateId: templateId,
    templateName: template,
    existing: DuplicateSide(
      recordId: '$id-old',
      name: existing,
      capturedAt: DateTime.utc(2026, 9, 17, 9),
      capturedBy: 'Ada',
      contextLabel: 'North',
    ),
    incoming: DuplicateSide(
      recordId: '$id-new',
      name: incoming,
      capturedAt: DateTime.utc(2026, 9, 28, 9),
      capturedBy: 'Ben',
      contextLabel: 'North',
      photos: incomingPhotos,
    ),
    differences: differences,
  );
}
