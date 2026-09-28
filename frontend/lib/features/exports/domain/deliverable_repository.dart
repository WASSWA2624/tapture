import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/export_request.dart';

import 'export_validation.dart';

/// The persisted deliverable workflow, shared by export and history screens.
abstract interface class DeliverableRepository {
  /// Last chosen options, or the approved-record workbook default.
  Future<Result<ExportRequest>> options(String projectId);

  /// Remembers options only; captured values never enter project settings.
  Future<Result<void>> remember(ExportRequest request);

  /// Live count using the same query as [prepare].
  Stream<int> watchCount(ExportRequest request);

  /// Resolves the query and validates every record against its captured shape.
  Future<Result<PreparedDeliverable>> prepare(
    ExportRequest request, {
    required CancellationToken cancel,
  });

  /// Writes the resolved request atomically, then records its history.
  Future<Result<DeliverableEntry>> write(
    ExportRequest request, {
    required CancellationToken cancel,
    void Function(DeliverableProgress progress)? onProgress,
  });

  /// Completed exports, optionally across all projects.
  Stream<List<DeliverableEntry>> watchHistory({String? projectId});

  /// The exact resolved request stored beside an export, including its values.
  Future<Result<ExportRequest>> replay(String exportId);
}

/// The request and record IDs requiring an operator decision.
typedef PreparedDeliverable = ({
  ExportRequest request,
  ExportValidationReport validation,
});

/// One stage's progress, from zero to one.
typedef DeliverableProgress = ({String stage, double fraction});

/// Durable metadata used for sharing without regenerating a file.
typedef DeliverableEntry = ({
  String id,
  String projectId,
  String projectName,
  int version,
  DateTime createdAt,
  String operatorName,
  int recordCount,
  String path,
  String fileName,
  String mimeType,
  String sha256,
  bool missing,
});
