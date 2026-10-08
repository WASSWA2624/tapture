import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/value_formatter.dart' show ExportFormat;
import 'package:tapture/features/exports/exports.dart';

/// Empty deliverable store; opening options never writes or reaches a platform.
final class FakeDeliverableRepository implements DeliverableRepository {
  @override
  Future<Result<ExportRequest>> options(String projectId) async =>
      Success<ExportRequest>(
        ExportRequest(
          projectId: projectId,
          formats: const <ExportFormat>{ExportFormat.xlsx},
          scope: (
            kind: ExportScopeKind.approved,
            context: null,
            from: null,
            to: null,
            filter: null,
          ),
          columns: (
            raw: false,
            refined: true,
            confidence: false,
            evidence: false,
          ),
          extras: (
            dictionary: false,
            photoIndex: true,
            photoMode: 'relative',
            pdfPhotos: 'thumbnail',
            delimiter: ',',
          ),
        ),
      );

  @override
  Future<Result<void>> remember(ExportRequest request) async =>
      const Success<void>(null);

  @override
  Stream<int> watchCount(ExportRequest request) => Stream<int>.value(0);

  @override
  Future<Result<PreparedDeliverable>> prepare(
    ExportRequest request, {
    required CancellationToken cancel,
  }) async => Success<PreparedDeliverable>((
    request: request,
    validation: (
      incomplete: <String>[],
      unapproved: <String>[],
      blocked: <String>[],
    ),
  ));

  @override
  Future<Result<DeliverableEntry>> write(
    ExportRequest request, {
    required CancellationToken cancel,
    void Function(DeliverableProgress)? onProgress,
  }) async => const FailureResult<DeliverableEntry>(
    ValidationFailure(
      message: 'There are no records to export.',
      recoveryAction: 'Capture a record first.',
    ),
  );

  @override
  Stream<List<DeliverableEntry>> watchHistory({String? projectId}) =>
      Stream<List<DeliverableEntry>>.value(const <DeliverableEntry>[]);

  @override
  Future<Result<ExportRequest>> replay(String exportId) async =>
      const FailureResult<ExportRequest>(
        ValidationFailure(
          message: 'There is no saved export.',
          recoveryAction: 'Create an export.',
        ),
      );
}
