import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/duplicate_resolution.dart';
import '../domain/quality_repository.dart';
import '../quality.dart' show qualityRepositoryProvider;

/// Whether a duplicate resolution or scan is in flight, and the intents that
/// start one (task 015). Screens call these, never the repository.
final duplicatesControllerProvider =
    NotifierProvider.autoDispose<DuplicatesController, bool>(
      DuplicatesController.new,
    );

/// The duplicate intents: detect, resolve one pair, resolve a group.
///
/// Every resolution goes through the one repository call, so a pair cleared
/// from the prompt, the comparison or a bulk choice leaves the same history,
/// audit rows and links.
final class DuplicatesController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Runs detection over [projectId]; the number of pairs newly queued.
  Future<Result<int>> scan(String projectId) {
    return _busy(
      () => ref.read(qualityRepositoryProvider).scanProject(projectId),
    );
  }

  /// Applies [resolution] to pair [pairId].
  Future<Result<void>> resolve(String pairId, DuplicateResolution resolution) {
    return _busy(
      () => ref.read(qualityRepositoryProvider).resolve(pairId, resolution),
    );
  }

  /// Applies [resolution] to each of [pairIds], one at a time, and returns
  /// how many were applied with the first failure met, if any.
  Future<({int resolved, Failure? failure})> resolveAll(
    List<String> pairIds,
    DuplicateResolution resolution,
  ) {
    final QualityRepository quality = ref.read(qualityRepositoryProvider);
    return _busy(() async {
      var resolved = 0;
      Failure? first;
      for (final String pairId in pairIds) {
        final Result<void> done = await quality.resolve(pairId, resolution);
        switch (done) {
          case Success<void>():
            resolved += 1;
          case FailureResult<void>(:final Failure failure):
            first ??= failure;
        }
      }
      return (resolved: resolved, failure: first);
    });
  }

  Future<T> _busy<T>(Future<T> Function() work) async {
    state = true;
    try {
      return await work();
    } finally {
      if (ref.mounted) {
        state = false;
      }
    }
  }
}
