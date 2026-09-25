import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;

/// One changed field on the record edit sheet. [stored] is true when the
/// record already has a row for [fieldKey].
typedef RecordFieldEdit = ({String fieldKey, String value, bool stored});

/// Save progress of one record's edit sheet. Ephemeral (FE-STATE-02).
typedef RecordEditState = ({bool saving, Failure? failure});

/// Edit state for the record id it is created with. Auto-dispose: the sheet
/// is its only reader (FE-STATE-09).
final recordEditControllerProvider = NotifierProvider.autoDispose
    .family<RecordEditController, RecordEditState, String>(
      RecordEditController.new,
    );

/// Writes the fields a person changed on one record.
final class RecordEditController extends Notifier<RecordEditState> {
  /// Creates the controller for [recordId].
  RecordEditController(this.recordId);

  /// The record being edited.
  final String recordId;

  @override
  RecordEditState build() => (saving: false, failure: null);

  /// Writes [edits] in order and stops at the first failure. A stored field
  /// is refined beside its original; a field with no row is stored as the
  /// typed original (FE-SEC-08). The raw column is never rewritten.
  Future<Result<void>> save(List<RecordFieldEdit> edits) async {
    if (state.saving) {
      return const Success<void>(null);
    }
    state = (saving: true, failure: null);
    final ProjectRepository repository = ref.read(projectRepositoryProvider);
    for (final RecordFieldEdit edit in edits) {
      final Result<void> written = edit.stored
          ? await repository.refineRecordField(
              recordId: recordId,
              fieldKey: edit.fieldKey,
              value: edit.value,
            )
          : await repository.addRecordField(
              recordId: recordId,
              fieldKey: edit.fieldKey,
              value: edit.value,
            );
      if (!ref.mounted) {
        return written;
      }
      if (written case FailureResult<void>(:final Failure failure)) {
        state = (saving: false, failure: failure);
        return written;
      }
    }
    state = (saving: false, failure: null);
    return const Success<void>(null);
  }
}
