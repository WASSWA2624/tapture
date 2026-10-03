import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/duplicate_pair_view.dart';
import '../domain/quality_counts.dart';
import '../domain/record_variance.dart';
import '../domain/uncaptured_rows.dart';
import '../quality.dart' show qualityRepositoryProvider;

// Providers the quality screens share (task 015). Each is keyed by the
// project, pair or record it reads, and auto-disposes with the last screen
// that reads it (FE-STATE-09). Retry is the screen's: it invalidates.

/// [projectId]'s unresolved duplicate pairs, and again after every change.
final duplicatePairsProvider = StreamProvider.autoDispose
    .family<List<DuplicatePairView>, String>((Ref ref, String projectId) {
      return ref
          .watch(qualityRepositoryProvider)
          .watchUnresolvedPairs(projectId);
    }, retry: (int _, Object _) => null);

/// One unresolved pair read whole, or null when it is resolved or gone.
final duplicatePairProvider = FutureProvider.autoDispose
    .family<DuplicatePairView?, String>((Ref ref, String pairId) async {
      final Result<DuplicatePairView?> read = await ref
          .watch(qualityRepositoryProvider)
          .pair(pairId);
      return switch (read) {
        Success<DuplicatePairView?>(:final DuplicatePairView? value) => value,
        FailureResult<DuplicatePairView?>(:final Failure failure) =>
          throw failure,
      };
    }, retry: (int _, Object _) => null);

/// The records [recordId] is paired with: unresolved, or kept both.
final duplicateCounterpartsProvider = StreamProvider.autoDispose
    .family<List<DuplicateCounterpart>, String>((Ref ref, String recordId) {
      return ref.watch(qualityRepositoryProvider).watchCounterparts(recordId);
    }, retry: (int _, Object _) => null);

/// [projectId]'s stored variances, and again after every change.
final projectVariancesProvider = StreamProvider.autoDispose
    .family<List<RecordVariance>, String>((Ref ref, String projectId) {
      return ref.watch(qualityRepositoryProvider).watchVariances(projectId);
    }, retry: (int _, Object _) => null);

/// [projectId]'s register rows not found and checklist rows not captured.
final missingItemsProvider = FutureProvider.autoDispose
    .family<UncapturedRows, String>((Ref ref, String projectId) async {
      final Result<UncapturedRows> read = await ref
          .watch(qualityRepositoryProvider)
          .missingItems(projectId);
      return switch (read) {
        Success<UncapturedRows>(:final UncapturedRows value) => value,
        FailureResult<UncapturedRows>(:final Failure failure) => throw failure,
      };
    }, retry: (int _, Object _) => null);

/// The counts that still block a clean export of [projectId].
final qualityCountsProvider = StreamProvider.autoDispose
    .family<QualityCounts, String>((Ref ref, String projectId) {
      return ref.watch(qualityRepositoryProvider).watchCounts(projectId);
    }, retry: (int _, Object _) => null);
