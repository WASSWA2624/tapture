import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/record_status.dart';

import '../domain/deleted_record.dart';
import '../domain/record_entry.dart';
import '../domain/record_facets.dart';
import '../domain/record_filter.dart';
import '../domain/record_history_event.dart';
import '../domain/record_repository.dart';
import '../domain/record_sort.dart';
import '../domain/record_summary.dart';
import '../domain/template_change_plan.dart';

// The Drift implementation of RecordRepository (task 014) joins this file in
// wave B; until then only the provider and its empty stand-in live here.

/// The record store. Defaults to an empty in-memory stand-in so suites never
/// open Drift (FE-TEST-03). `main` replaces it with the Drift implementation
/// against the on-disk database.
final Provider<RecordRepository> recordRepositoryProvider =
    Provider<RecordRepository>((Ref _) {
      return _EmptyRecordRepository();
    });

/// Empty watch streams and failing writes. Production never keeps this;
/// tests that need records inject `FakeRecordRepository` or an in-memory
/// Drift implementation.
final class _EmptyRecordRepository implements RecordRepository {
  @override
  Stream<RecordEntry?> watchEntry(String id) {
    return Stream<RecordEntry?>.value(null);
  }

  @override
  Future<Result<RecordEntry?>> byId(String id) async {
    return const Success<RecordEntry?>(null);
  }

  @override
  Stream<List<RecordSummary>> watchPage(
    String projectId, {
    required RecordFilter filter,
    required RecordSort sort,
    required int offset,
    required int limit,
  }) {
    return Stream<List<RecordSummary>>.value(const <RecordSummary>[]);
  }

  @override
  Stream<int> watchCount(String projectId, RecordFilter filter) {
    return Stream<int>.value(0);
  }

  @override
  Future<Result<RecordFacets>> facets(String projectId) async {
    return const Success<RecordFacets>(RecordFacets.empty);
  }

  @override
  Stream<List<RecordHistoryEvent>> watchHistory(String id) {
    return Stream<List<RecordHistoryEvent>>.value(const <RecordHistoryEvent>[]);
  }

  @override
  Stream<List<DeletedRecord>> watchBin() {
    return Stream<List<DeletedRecord>>.value(const <DeletedRecord>[]);
  }

  @override
  Future<Result<RecordEntry>> save(RecordDraft draft) async {
    return const FailureResult<RecordEntry>(_unavailable);
  }

  @override
  Future<Result<void>> transition(
    String id,
    RecordStatus to, {
    String? reason,
  }) async {
    return const FailureResult<void>(_unavailable);
  }

  @override
  Future<Result<void>> editValues(
    String id,
    List<RecordValueEdit> edits,
  ) async {
    return const FailureResult<void>(_unavailable);
  }

  @override
  Future<Result<TemplateChangePlan>> planTemplateChange(
    String id,
    String templateId,
  ) async {
    return const FailureResult<TemplateChangePlan>(_unavailable);
  }

  @override
  Future<Result<void>> changeTemplate(String id, String templateId) async {
    return const FailureResult<void>(_unavailable);
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    return const FailureResult<void>(_unavailable);
  }

  @override
  Future<Result<void>> restore(String id) async {
    return const FailureResult<void>(_unavailable);
  }
}

/// Every write and template-change plan on the empty stand-in: the records
/// store is not wired to this device's database.
const StorageFailure _unavailable = StorageFailure(
  message: 'Records are not available yet.',
  recoveryAction: 'Restart the app and try again.',
);
