import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/records/domain/purge_candidate.dart';
import 'package:tapture/features/records/domain/purge_store.dart';

/// In-memory [PurgeStore] for tests of the purge policy (FE-TEST-03).
final class FakePurgeStore implements PurgeStore {
  /// Creates a store holding [candidates].
  FakePurgeStore([List<PurgeCandidate> candidates = const <PurgeCandidate>[]])
    : _candidates = List<PurgeCandidate>.of(candidates);

  final List<PurgeCandidate> _candidates;

  /// When set, [candidates] returns this failure.
  Failure? listFailure;

  /// Records whose purge returns the mapped failure.
  final Map<String, Failure> failuresById = <String, Failure>{};

  /// Records whose purge throws instead of returning a result.
  final Set<String> throwsFor = <String>{};

  /// Files each record owns, removed with it. One when not given.
  final Map<String, int> filesById = <String, int>{};

  /// Ids purged so far, in the order they went.
  final List<String> purged = <String>[];

  /// Ids the job asked to purge, failed ones included.
  final List<String> attempted = <String>[];

  /// Candidates still in the store.
  List<PurgeCandidate> get remaining =>
      List<PurgeCandidate>.unmodifiable(_candidates);

  @override
  Future<Result<List<PurgeCandidate>>> candidates() async {
    final Failure? failure = listFailure;
    if (failure != null) {
      return FailureResult<List<PurgeCandidate>>(failure);
    }
    return Success<List<PurgeCandidate>>(List<PurgeCandidate>.of(_candidates));
  }

  @override
  Future<Result<int>> purge(PurgeCandidate candidate) async {
    attempted.add(candidate.recordId);
    if (throwsFor.contains(candidate.recordId)) {
      throw StateError('store broke on ${candidate.recordId}');
    }
    final Failure? failure = failuresById[candidate.recordId];
    if (failure != null) {
      return FailureResult<int>(failure);
    }
    _candidates.removeWhere(
      (PurgeCandidate held) => held.recordId == candidate.recordId,
    );
    purged.add(candidate.recordId);
    return Success<int>(filesById[candidate.recordId] ?? 1);
  }
}
