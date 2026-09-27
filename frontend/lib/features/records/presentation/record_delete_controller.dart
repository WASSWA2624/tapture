import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/record_repository.dart';
import '../records.dart' show recordRepositoryProvider;

/// Whether a delete or restore is running. Kept alive deliberately: the undo
/// on the snackbar outlives the row, page or selection that started the
/// delete, and must still find this controller (FE-STATE-09).
final NotifierProvider<RecordDeleteController, bool>
recordDeleteControllerProvider = NotifierProvider<RecordDeleteController, bool>(
  RecordDeleteController.new,
);

/// Moves records to the recycle bin and brings them back (task 014 step 7,
/// D12), for one record or a whole selection.
///
/// Each record is written on its own, in the order given, so one failure
/// neither stops nor rolls back the others; the outcome names every record
/// that changed and every one that did not, with why. The state is true
/// while a delete or restore is running.
final class RecordDeleteController extends Notifier<bool> {
  /// Creates the controller.
  RecordDeleteController();

  /// The reason stored on the tombstone and the audit entry when an operator
  /// deletes records from a list, a record page or a selection.
  static const String operatorReason = 'Deleted by the operator.';

  /// Held so a restore from the snackbar still reaches the store after the
  /// screen that deleted has closed.
  late RecordRepository _records;

  /// Deletes and restores in flight. More than one can overlap.
  int _running = 0;

  @override
  bool build() {
    _records = ref.watch(recordRepositoryProvider);
    _running = 0;
    return false;
  }

  /// Moves every record in [ids] to the recycle bin, with [reason] on each
  /// tombstone. A repeated id is deleted once.
  Future<RecordDeleteOutcome> delete(
    List<String> ids, {
    String reason = operatorReason,
  }) {
    return _each(
      ids,
      (RecordRepository records, String id) =>
          records.delete(id, reason: reason),
    );
  }

  /// Brings every record in [ids] back from the recycle bin, each to the
  /// status it had before it was deleted. The snackbar's undo calls this.
  Future<RecordDeleteOutcome> restore(List<String> ids) {
    return _each(
      ids,
      (RecordRepository records, String id) => records.restore(id),
    );
  }

  Future<RecordDeleteOutcome> _each(
    List<String> ids,
    Future<Result<void>> Function(RecordRepository records, String id) write,
  ) async {
    final List<String> targets = <String>{...ids}.toList();
    final List<String> succeeded = <String>[];
    final Map<String, Failure> failed = <String, Failure>{};
    if (targets.isEmpty) {
      return (succeeded: succeeded, failed: failed);
    }
    final RecordRepository records = _records;
    _begin();
    try {
      for (final String id in targets) {
        final Result<void> written = await _guard(() => write(records, id));
        switch (written) {
          case Success<void>():
            succeeded.add(id);
          case FailureResult<void>(:final Failure failure):
            failed[id] = failure;
        }
      }
    } finally {
      _end();
    }
    return (
      succeeded: List<String>.unmodifiable(succeeded),
      failed: Map<String, Failure>.unmodifiable(failed),
    );
  }

  void _begin() {
    _running++;
    if (ref.mounted) {
      state = true;
    }
  }

  void _end() {
    _running = _running > 0 ? _running - 1 : 0;
    if (ref.mounted) {
      state = _running > 0;
    }
  }
}

/// Runs [call], turning a store that throws into a [FailureResult] so one bad
/// record cannot end the run.
Future<Result<void>> _guard(Future<Result<void>> Function() call) async {
  try {
    return await call();
  } on Object catch (error) {
    return FailureResult<void>(Failure.from(error));
  }
}

/// What a delete or restore did: the records it changed, in the order asked,
/// and the ones it could not change, each with the failure that stopped it.
typedef RecordDeleteOutcome = ({
  List<String> succeeded,
  Map<String, Failure> failed,
});
