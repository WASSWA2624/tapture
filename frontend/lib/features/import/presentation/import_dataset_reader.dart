import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/features/reference/reference.dart'
    show DatasetImportDraft;

/// Reads a chosen table into a reference dataset draft for [projectId],
/// with the importers of 105 · Reference data, off the UI thread.
typedef ImportDatasetReader =
    Future<Result<DatasetImportDraft>> Function(
      PickedDocument document, {
      required String projectId,
      CancellationToken? cancel,
    });
