import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/processing_findings_repository.dart';
import '../domain/processing_usage_repository.dart';

/// Bootstrap supplies the existing database-backed local findings reader.
final Provider<ProcessingFindingsRepository> processingFindingsStoreProvider =
    Provider<ProcessingFindingsRepository>(
      (Ref _) => const ProcessingFindingsRepository.empty(),
    );

/// Latest findings stream for one reviewed record, disposed on leaving it.
final processingFindingsProvider = StreamProvider.autoDispose
    .family<List<String>, String>(
      (Ref ref, String recordId) =>
          ref.watch(processingFindingsStoreProvider).watchRecord(recordId),
    );

/// Bootstrap supplies the same usage reader used to enforce request caps.
final Provider<ProcessingUsageRepository?> processingUsageStoreProvider =
    Provider<ProcessingUsageRepository?>((Ref _) => null);

/// Actual reserved units and reported tokens; absent metadata stays absent.
final queueSpendProvider = StreamProvider.autoDispose
    .family<({Map<String, double> reservedCosts, int? totalTokens}), String?>(
      (Ref ref, String? projectId) =>
          ref
              .watch(processingUsageStoreProvider)
              ?.watchSpend(projectId: projectId) ??
          Stream<({Map<String, double> reservedCosts, int? totalTokens})>.value(
            (reservedCosts: const <String, double>{}, totalTokens: null),
          ),
    );
