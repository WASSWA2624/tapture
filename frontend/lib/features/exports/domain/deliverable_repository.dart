import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/export_request.dart';

import 'export_validation.dart';

/// The persisted deliverable workflow, shared by the export screen and its
/// history.
abstract interface class DeliverableRepository {
  /// Last chosen options, or the default: the project package (task 076,
  /// D13) over approved records, refined columns on.
  Future<Result<ExportRequest>> options(String projectId);

  /// Remembers options only; captured values never enter project settings.
  Future<Result<void>> remember(ExportRequest request);

  /// Live count using the same query as [prepare].
  Stream<int> watchCount(ExportRequest request);

  /// Resolves the query and validates every record against its captured
  /// shape; a meeting whose actions lack an owner or due date, when its
  /// template requires them, is named as blocked.
  Future<Result<PreparedDeliverable>> prepare(
    ExportRequest request, {
    required CancellationToken cancel,
  });

  /// Writes the resolved request into its own dated, versioned folder,
  /// then records its history. [onProgress] reports the `records`,
  /// `photos`, `reports` and `archive` stages in that order.
  Future<Result<DeliverableEntry>> write(
    ExportRequest request, {
    required CancellationToken cancel,
    void Function(DeliverableProgress progress)? onProgress,
  });

  /// Completed exports of either kind, deliverables and project packages,
  /// newest first, optionally for one project.
  Stream<List<DeliverableEntry>> watchHistory({String? projectId});

  /// The exact resolved request stored beside a deliverable, including its
  /// values. A project package has none: run the package again instead.
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
/// [package] marks a project package rather than a deliverable.
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
  bool package,
});
