import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/review/domain/review_repository.dart';

import '../../records/fakes/fake_record_repository.dart';

/// In-memory [ReviewRepository] over a [FakeRecordRepository], with the
/// Drift store's semantics (FE-STATE-10): a verify marks values verified by
/// [operator] without changing them, and a side choice sets only the final
/// value, so both stored sides survive.
final class FakeReviewRepository implements ReviewRepository {
  /// Creates the store over [records].
  FakeReviewRepository(this.records, {this.operator = 'Test operator'});

  /// The records a verify or a side choice changes.
  final FakeRecordRepository records;

  /// Who a verify is stamped with.
  final String operator;

  /// Field keys in an unresolved conflict, for every record.
  final Set<String> conflicts = <String>{};

  /// Evidence by field key, for every record.
  final Map<String, List<ValueEvidence>> evidence =
      <String, List<ValueEvidence>>{};

  /// When set, every call fails with this.
  Failure? failure;

  /// Every write, in order: the method, the record and the field keys.
  final List<({String method, String recordId, List<String> keys})> writes =
      <({String method, String recordId, List<String> keys})>[];

  final Map<String, String> _verifiedBy = <String, String>{};

  @override
  Future<Result<ReviewFacts>> facts(String recordId) async {
    final Failure? failed = failure;
    if (failed != null) {
      return FailureResult<ReviewFacts>(failed);
    }
    return Success<ReviewFacts>((
      conflicts: Set<String>.of(conflicts),
      verifiedBy: <String, String>{
        for (final RecordValue value
            in records.entryOf(recordId)?.values ?? const <RecordValue>[])
          if (value.verified)
            value.fieldKey: _verifiedBy['$recordId/${value.fieldKey}'] ?? '',
      },
      evidence: Map<String, List<ValueEvidence>>.of(evidence),
    ));
  }

  @override
  Future<Result<void>> verify(String recordId, List<String> fieldKeys) async {
    final Failure? failed = failure;
    if (failed != null) {
      return FailureResult<void>(failed);
    }
    writes.add((method: 'verify', recordId: recordId, keys: fieldKeys));
    _change(recordId, (RecordValue value) {
      if (!fieldKeys.contains(value.fieldKey) ||
          !value.hasValue ||
          value.verified) {
        return value;
      }
      _verifiedBy['$recordId/${value.fieldKey}'] = operator;
      return value.copyWith(verified: true);
    });
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> chooseFinal(
    String recordId,
    String fieldKey,
    String value,
  ) async {
    final Failure? failed = failure;
    if (failed != null) {
      return FailureResult<void>(failed);
    }
    writes.add((
      method: 'chooseFinal',
      recordId: recordId,
      keys: <String>[fieldKey],
    ));
    _change(
      recordId,
      (RecordValue held) =>
          held.fieldKey == fieldKey ? held.copyWith(approved: value) : held,
    );
    return const Success<void>(null);
  }

  void _change(String recordId, RecordValue Function(RecordValue) change) {
    final RecordEntry? entry = records.entryOf(recordId);
    if (entry == null) {
      return;
    }
    records.seedEntry(
      entry.copyWith(
        values: <RecordValue>[
          for (final RecordValue v in entry.values) change(v),
        ],
      ),
    );
  }
}
