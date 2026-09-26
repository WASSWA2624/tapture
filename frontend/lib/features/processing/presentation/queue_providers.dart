import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/processing_repository.dart';

/// The job store. Production replaces the empty, disk-free stand-in.
final Provider<ProcessingRepository> processingRepositoryProvider =
    Provider<ProcessingRepository>((Ref _) => _EmptyProcessingRepository());

/// Live queue snapshot. Counts come from the repository query.
final StreamProvider<QueueSnapshot> queueSnapshotProvider =
    StreamProvider<QueueSnapshot>((Ref ref) {
      return ref.watch(processingRepositoryProvider).watchQueue();
    });

/// Project-scoped queue snapshot for an open project.
final queueSnapshotForProjectProvider = StreamProvider.autoDispose
    .family<QueueSnapshot, String>((Ref ref, String projectId) {
      return ref
          .watch(processingRepositoryProvider)
          .watchQueue(projectId: projectId);
    });

final class _EmptyProcessingRepository implements ProcessingRepository {
  @override
  Stream<List<ProcessingJob>> watchAll() {
    return Stream<List<ProcessingJob>>.value(const <ProcessingJob>[]);
  }

  @override
  Stream<QueueSnapshot> watchQueue({String? projectId}) {
    return Stream<QueueSnapshot>.value(emptyQueueSnapshot);
  }

  @override
  Future<Result<int>> enqueuePending({
    String? projectId,
    List<String> groupLabels = const <String>[],
  }) async {
    return const Success<int>(0);
  }

  @override
  Future<Result<ProcessingJob?>> byId(String id) async {
    return const Success<ProcessingJob?>(null);
  }

  @override
  Future<Result<ProcessingJob>> save(ProcessingJob job) async {
    return const FailureResult<ProcessingJob>(_missingJob);
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    return const FailureResult<void>(_missingJob);
  }

  @override
  Future<Result<String>> enqueue(String recordId) async {
    return const FailureResult<String>(_missingJob);
  }

  @override
  Future<Result<ProcessingJob?>> claim(
    Duration lease, {
    String? projectId,
    List<String> groupLabels = const <String>[],
    JobStage? unfinished,
    Set<String> skip = const <String>{},
  }) async {
    return const Success<ProcessingJob?>(null);
  }

  @override
  Future<Result<void>> complete(String jobId) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> fail(
    String jobId,
    String reason, {
    required bool permanent,
  }) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<ProcessingJob>> markStage(String id, JobStage stage) async {
    return const FailureResult<ProcessingJob>(_missingJob);
  }

  @override
  Future<Result<void>> release(String id) async {
    return const FailureResult<void>(_missingJob);
  }

  @override
  Future<Result<void>> retry(String id) async {
    return const FailureResult<void>(_missingJob);
  }

  @override
  Future<Result<({int requests, int images})>> usageOn(
    DateTime day, {
    String? projectId,
  }) async {
    return const Success<({int requests, int images})>((
      requests: 0,
      images: 0,
    ));
  }
}

const StorageFailure _missingJob = StorageFailure(
  message: 'That job is no longer on this device.',
  recoveryAction: 'Refresh the queue and try again.',
);
