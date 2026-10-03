import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/result.dart';

import 'import_duplicates.dart';

/// Where imported rows are written (task 020). The Drift implementation and
/// the test fake honour the same rules: every write of one run lands in one
/// transaction or none does, and a created record carries source
/// `IMPORTED_TABLE`.
abstract interface class RecordImportStore {
  /// The stored identity hash of each live record on [templateId] in
  /// [projectId], mapped to that record's id.
  Future<Result<Map<String, String>>> identities({
    required String projectId,
    required String templateId,
  });

  /// Writes [rows] onto [templateId] in [projectId], in one transaction.
  ///
  /// [onBatch] hears how many rows are written after every [batchSize] rows
  /// and after the last. A cancelled [token] or any failure rolls every row
  /// of the call back, so nothing of it is kept.
  Future<Result<void>> write({
    required String projectId,
    required String templateId,
    required List<ImportWrite> rows,
    required int batchSize,
    required void Function(int written) onBatch,
    required CancellationToken token,
  });
}

/// One row to write: a new record ([ImportMatch.create]), or the record
/// [existingId] replaced ([ImportMatch.replace]) or filled where it is empty
/// ([ImportMatch.merge]). [values] are keyed by template field key.
typedef ImportWrite = ({
  int row,
  ImportMatch match,
  String? existingId,
  Map<String, String> values,
});
