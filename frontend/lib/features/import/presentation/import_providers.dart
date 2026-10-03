import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/core/import/import.dart';
import 'package:tapture/features/reference/reference.dart' show DatasetImport;
import 'package:tapture/features/templates/templates.dart'
    show TemplateDef, templateRepositoryProvider;

import 'import_controller.dart';
import 'import_dataset_reader.dart';

export 'import_dataset_reader.dart';

// Providers the import screens share (task 020). Each auto-disposes with
// the last screen that reads it (FE-STATE-09); retry is the screen's, by
// invalidating.

/// The dataset reader the import page and the register purpose use.
final Provider<ImportDatasetReader> importDatasetReaderProvider =
    Provider<ImportDatasetReader>((Ref _) {
      return (
        PickedDocument document, {
        required String projectId,
        CancellationToken? cancel,
      }) {
        return DatasetImport.read(
          document,
          projectId: projectId,
          cancel: cancel,
        );
      };
    });

/// The first sheet of the spreadsheet the import page holds, read by the
/// workbook reader of 009 (its header detection and type inference) on a
/// worker isolate. Null when no spreadsheet is held or it has no sheet.
final importSheetProvider = FutureProvider.autoDispose<WorkbookSheet?>((
  Ref ref,
) async {
  final PickedDocument? document = ref.watch(
    importControllerProvider.select((ImportView view) => view.document),
  );
  if (document == null) {
    return null;
  }
  final Uint8List bytes = switch (document) {
    PickedBytes(:final Uint8List bytes) => bytes,
    PickedFile(:final file) => await file.readAsBytes(),
  };
  final Result<WorkbookSnapshot> read = await WorkbookReader.openBytes(
    bytes,
    sourceName: document.name,
  );
  return switch (read) {
    Success<WorkbookSnapshot>(:final WorkbookSnapshot value) =>
      value.sheets.isEmpty ? null : value.sheets.first,
    FailureResult<WorkbookSnapshot>(:final Failure failure) => throw failure,
  };
}, retry: (int _, Object _) => null);

/// The templates of [projectId] that imported rows can be matched onto.
final importTemplatesProvider = StreamProvider.autoDispose
    .family<List<TemplateDef>, String>((Ref ref, String projectId) {
      return ref.watch(templateRepositoryProvider).watchByProject(projectId);
    }, retry: (int _, Object _) => null);
