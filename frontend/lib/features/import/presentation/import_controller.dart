import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/bundle/bundle_format.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/files/file_validation.dart';
import 'package:tapture/core/files/file_writer.dart'
    show discardUnpublishedFile;
import 'package:tapture/features/reference/reference.dart'
    show DatasetImportDraft;

import '../domain/import_flow.dart';
import 'import_providers.dart';

/// The one import entry (task 020): pick any file the app takes, check it
/// through the shared gate, detect its kind from what the gate accepted and
/// the file's own content, and say where it goes. Nothing is written here.
///
/// A bundle is handed to the merge flow of 114, whose reader runs the same
/// archive walk under a package's own ceilings; every other file passes
/// [FileValidation.validateDocument] first. The chosen file's name and text
/// are data, never instruction (FE-SEC-05, FE-SEC-06).
final class ImportController extends Notifier<ImportView> {
  /// A picker copy this controller made and must delete when done with it.
  PickedDocument? _owned;

  CancellationToken? _reading;

  /// Shows [next] as the page's state. A step opened over the import
  /// page reads the file the previous step checked.
  void present(ImportView next) {
    state = next;
  }

  @override
  ImportView build() {
    ref.onDispose(() {
      _reading?.cancel();
      unawaited(_discard(_owned));
      _owned = null;
    });
    return _idle;
  }

  /// Opens the picker, checks the chosen file and returns where it goes, or
  /// null when the picker was closed or the file was refused; the reason is
  /// then [ImportView.failure]. [projectId] is the open project, which
  /// every kind but a bundle is added to.
  Future<ImportDestination?> choose({String? projectId}) async {
    if (state.busy) {
      return null;
    }
    state = (busy: true, failure: null, document: state.document);
    final Result<PickedDocument> picked = await ref
        .read(documentPickerProvider)
        .pick(
          extensions: _extensions,
          mimeType: '',
          maxBytes: kIsWeb ? AppConstants.imports.bundleMaxBytes : null,
        );
    if (!ref.mounted) {
      if (picked case Success<PickedDocument>(:final PickedDocument value)) {
        await _discard(value);
      }
      return null;
    }
    final PickedDocument document;
    switch (picked) {
      case FailureResult<PickedDocument>(:final Failure failure):
        state = (
          busy: false,
          failure: failure is CancelledFailure ? null : failure,
          document: state.document,
        );
        return null;
      case Success<PickedDocument>(:final PickedDocument value):
        document = value;
    }
    await _discard(_owned);
    _owned = document;
    state = (busy: true, failure: null, document: null);
    final ImportFlow? flow = await _flowOf(document);
    if (!ref.mounted) {
      return null;
    }
    if (flow == null) {
      return null;
    }
    if (flow == ImportFlow.bundle) {
      // The merge flow takes the file over, and deletes its copy.
      _owned = null;
      state = _idle;
      return (flow: flow, location: null, extra: null, document: document);
    }
    if (projectId == null || projectId.isEmpty) {
      return _refuse(_needsProjectFailure);
    }
    switch (flow) {
      case ImportFlow.dataset:
        final ImportDestination? next = await _dataset(document, projectId);
        if (next != null) {
          // The draft holds the rows; the picker's copy is done with.
          await _release();
        }
        return next;
      case ImportFlow.template:
        final String text = await _text(document);
        if (!ref.mounted) {
          return null;
        }
        await _release();
        state = _idle;
        return (
          flow: flow,
          location: RoutePaths.templateImport(projectId: projectId),
          extra: text,
          document: document,
        );
      case ImportFlow.spreadsheet:
        state = (busy: false, failure: null, document: document);
        return (
          flow: flow,
          location: RoutePaths.projectImportPurpose,
          extra: null,
          document: document,
        );
      case ImportFlow.bundle:
        return null;
    }
  }

  /// Reads the held spreadsheet as the register of [projectId]: a reference
  /// dataset verification checks against, and no records (task 020 step 2).
  Future<ImportDestination?> asRegister({required String? projectId}) async {
    final PickedDocument? document = state.document;
    if (document == null || state.busy) {
      return null;
    }
    if (projectId == null || projectId.isEmpty) {
      return _refuse(_needsProjectFailure);
    }
    state = (busy: true, failure: null, document: document);
    return _dataset(document, projectId);
  }

  Future<ImportDestination?> _dataset(
    PickedDocument document,
    String projectId,
  ) async {
    final CancellationToken token = CancellationToken();
    _reading = token;
    final Result<DatasetImportDraft> read = await ref.read(
      importDatasetReaderProvider,
    )(document, projectId: projectId, cancel: token);
    if (!ref.mounted) {
      return null;
    }
    _reading = null;
    switch (read) {
      case FailureResult<DatasetImportDraft>(:final Failure failure):
        return failure is CancelledFailure ? null : _refuse(failure);
      case Success<DatasetImportDraft>(:final DatasetImportDraft value):
        state = (busy: false, failure: null, document: state.document);
        return (
          flow: ImportFlow.dataset,
          location: RoutePaths.projectDatasetImport(projectId),
          extra: value,
          document: document,
        );
    }
  }

  /// The flow for [document], or null after refusing it.
  Future<ImportFlow?> _flowOf(PickedDocument document) async {
    final String extension = _extensionOf(document.name);
    if (extension == BundleFormat.extension) {
      return ImportFlow.bundle;
    }
    final Result<ImportKind> gate = await FileValidation().validateDocument(
      document,
      allowed: const <ImportKind>{ImportKind.spreadsheet},
    );
    switch (gate) {
      case FailureResult<ImportKind>(:final Failure failure):
        _refuse(failure);
        return null;
      case Success<ImportKind>(value: final ImportKind kind):
        final ImportFlow? flow = ImportFlow.of(
          kind: kind,
          extension: extension,
          head: extension == 'json' ? await _head(document) : '',
        );
        if (flow == null) {
          _refuse(
            ValidationFailure(
              localizedMessage: Copy.messages.importUnsupported,
              localizedRecovery: Copy.messages.importEmptyMessage,
            ),
          );
        }
        return flow;
    }
  }

  ImportDestination? _refuse(Failure failure) {
    unawaited(_release());
    state = (busy: false, failure: failure, document: null);
    return null;
  }

  Future<void> _release() async {
    final PickedDocument? owned = _owned;
    _owned = null;
    await _discard(owned);
  }
}

/// The import page's state: whether a file is being checked or read, why
/// the last one was refused, and the spreadsheet held for the purpose,
/// mapping and summary steps.
typedef ImportView = ({bool busy, Failure? failure, PickedDocument? document});

/// Where a checked file goes: [flow], and for every flow but a bundle the
/// [location] to open with [extra] (a dataset draft or a template's text).
typedef ImportDestination = ({
  ImportFlow flow,
  String? location,
  Object? extra,
  PickedDocument document,
});

/// One import at a time. Auto-dispose: leaving the import page, and every
/// step pushed over it, drops the held file (FE-STATE-09).
final importControllerProvider =
    NotifierProvider.autoDispose<ImportController, ImportView>(
      ImportController.new,
    );

const ImportView _idle = (busy: false, failure: null, document: null);

/// Every kind but a bundle is added to the open project.
final ValidationFailure _needsProjectFailure = ValidationFailure(
  localizedMessage: Copy.messages.importNeedsProject,
  localizedRecovery: Copy.messages.importNeedsProjectRecovery,
);

/// Every extension the page takes: a bundle, a workbook or a JSON file.
const List<String> _extensions = <String>[
  BundleFormat.extension,
  'xlsx',
  'csv',
  'json',
];

/// How much of a JSON file is read to tell a template from a table.
const int _headBytes = 256;

String _extensionOf(String name) {
  final int dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
}

/// The first [_headBytes] of [document], as text.
Future<String> _head(PickedDocument document) async {
  final Uint8List bytes = switch (document) {
    PickedBytes(:final Uint8List bytes) => Uint8List.sublistView(
      bytes,
      0,
      bytes.length < _headBytes ? bytes.length : _headBytes,
    ),
    PickedFile(:final file) => Uint8List.fromList(
      await file
          .openRead(0, _headBytes)
          .fold<List<int>>(
            <int>[],
            (List<int> all, List<int> chunk) => all..addAll(chunk),
          ),
    ),
  };
  return utf8.decode(bytes, allowMalformed: true);
}

/// The whole of [document], as text.
Future<String> _text(PickedDocument document) async {
  return switch (document) {
    PickedBytes(:final Uint8List bytes) => utf8.decode(
      bytes,
      allowMalformed: true,
    ),
    PickedFile(:final file) => file.readAsString(),
  };
}

/// Deletes [document] when it is a copy the picker made for this app.
Future<void> _discard(PickedDocument? document) async {
  if (document case PickedFile(isCopy: true, :final file)) {
    try {
      await discardUnpublishedFile(file);
    } on Object {
      // The platform clears its cache in time.
    }
  }
}
