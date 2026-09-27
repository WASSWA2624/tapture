import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/db/app_database.dart' show AppDatabase;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
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
import 'record_queries.dart';
import 'record_writes.dart';

/// The Drift-backed [RecordRepository] (task 014): the one store every
/// records screen reads and changes this device's records through.
///
/// It holds no SQL of its own. Every read is answered by [RecordQueries]
/// (a record read whole, pages, counts, facets, history and the recycle bin,
/// all filtered, searched and ordered in the query) and every write by
/// [RecordWrites] (one transaction per call, status moves checked with the
/// lifecycle first, values never deleted). The search index is kept by the
/// schema's triggers inside the same transaction as each write (D5), so a
/// page read straight after a write already finds the new text.
///
/// Both halves share one database and one operator: [RecordRepositoryImpl]
/// stamps audit rows, verified values and approvals with `operatorName` when
/// given, else with the device profile's operator name, and labels this
/// device in the operator facet the same way.
final class RecordRepositoryImpl implements RecordRepository {
  /// Opens the store against [db]. Writes are stamped with [clock] and
  /// [deviceId] and new rows take ids from [ids]. [operatorName], when
  /// given, names the operator on every write and in the operator facet in
  /// place of the device profile's name; a blank name means no operator.
  RecordRepositoryImpl({
    required AppDatabase db,
    required Clock clock,
    required String deviceId,
    required IdService ids,
    String Function()? operatorName,
  }) : _queries = RecordQueries(db: db, localOperator: operatorName),
       _writes = RecordWrites(
         db: db,
         clock: clock,
         deviceId: deviceId,
         ids: ids,
         operatorName: operatorName,
       );

  final RecordQueries _queries;
  final RecordWrites _writes;

  @override
  Stream<RecordEntry?> watchEntry(String id) {
    return _queries.watchEntry(id);
  }

  @override
  Future<Result<RecordEntry?>> byId(String id) {
    return _queries.byId(id);
  }

  @override
  Stream<List<RecordSummary>> watchPage(
    String projectId, {
    required RecordFilter filter,
    required RecordSort sort,
    required int offset,
    required int limit,
  }) {
    return _queries.watchPage(
      projectId,
      filter: filter,
      sort: sort,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Stream<int> watchCount(String projectId, RecordFilter filter) {
    return _queries.watchCount(projectId, filter);
  }

  @override
  Future<Result<RecordFacets>> facets(String projectId) {
    return _queries.facets(projectId);
  }

  @override
  Stream<List<RecordHistoryEvent>> watchHistory(String id) {
    return _queries.watchHistory(id);
  }

  @override
  Stream<List<DeletedRecord>> watchBin() {
    return _queries.watchBin();
  }

  /// Saves the record in one transaction, then reads it back whole, so the
  /// entry returned is exactly what [byId] finds: its allocated number, its
  /// name and identifier from the search document, and its values as stored.
  @override
  Future<Result<RecordEntry>> save(RecordDraft draft) async {
    final Result<String> saved = await _writes.save(draft);
    switch (saved) {
      case FailureResult<String>(:final Failure failure):
        return FailureResult<RecordEntry>(failure);
      case Success<String>(value: final String id):
        final Result<RecordEntry?> read = await _queries.byId(id);
        return read.flatMap(
          (RecordEntry? entry) => entry == null
              ? const FailureResult<RecordEntry>(_savedButUnread)
              : Success<RecordEntry>(entry),
        );
    }
  }

  @override
  Future<Result<void>> transition(
    String id,
    RecordStatus to, {
    String? reason,
  }) {
    return _writes.transition(id, to, reason: reason);
  }

  @override
  Future<Result<void>> editValues(String id, List<RecordValueEdit> edits) {
    return _writes.editValues(id, edits);
  }

  @override
  Future<Result<TemplateChangePlan>> planTemplateChange(
    String id,
    String templateId,
  ) {
    return _writes.planTemplateChange(id, templateId);
  }

  @override
  Future<Result<void>> changeTemplate(String id, String templateId) {
    return _writes.changeTemplate(id, templateId);
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) {
    return _writes.moveToBin(id, reason: reason);
  }

  @override
  Future<Result<void>> restore(String id) {
    return _writes.restore(id);
  }
}

/// The record store. Defaults to an empty in-memory stand-in so suites never
/// open Drift (FE-TEST-03). `main` replaces it with [RecordRepositoryImpl]
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

/// A save that committed but whose record could not be read back: only a
/// concurrent purge of the new record between the two calls can cause it.
const StorageFailure _savedButUnread = StorageFailure(
  message: 'The record was saved but could not be opened.',
  recoveryAction: 'Open it from the records list.',
);
