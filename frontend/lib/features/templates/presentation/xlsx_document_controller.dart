import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';

import '../templates.dart' show TemplateDocumentImport;

/// Owns a mapping page's selected workbook and its disposable picker copy.
final class XlsxDocumentController extends Notifier<AsyncValue<Object?>> {
  XlsxDocumentController(this.initial);

  final Object? initial;
  PickedDocument? _owned;

  @override
  AsyncValue<Object?> build() {
    if (initial is PickedDocument) _owned = initial as PickedDocument;
    ref.onDispose(() => unawaited(TemplateDocumentImport.discard(_owned)));
    return AsyncData<Object?>(initial);
  }

  Future<void> choose() async {
    if (state.isLoading) return;
    final AsyncValue<Object?> previous = state;
    state = const AsyncLoading<Object?>();
    final Result<PickedDocument> picked = await ref
        .read(documentPickerProvider)
        .pick(
          extensions: const <String>['csv', 'xlsx'],
          mimeType: '',
          maxBytes: AppConstants.imports.spreadsheetMaxBytes,
        );
    if (picked case FailureResult<PickedDocument>(:final Failure failure)) {
      if (ref.mounted) {
        state = failure is CancelledFailure
            ? previous
            : AsyncError<Object?>(failure, StackTrace.current);
      }
      return;
    }
    final PickedDocument document = (picked as Success<PickedDocument>).value;
    final Result<void> checked = await TemplateDocumentImport.validate(
      document,
    );
    if (!ref.mounted || checked is FailureResult<void>) {
      await TemplateDocumentImport.discard(document);
      if (ref.mounted) {
        if (checked case FailureResult<void>(:final Failure failure)) {
          state = AsyncError<Object?>(failure, StackTrace.current);
        }
      }
      return;
    }
    await TemplateDocumentImport.discard(_owned);
    if (!ref.mounted) {
      await TemplateDocumentImport.discard(document);
      return;
    }
    _owned = document;
    if (ref.mounted) state = AsyncData<Object?>(document);
  }
}

final xlsxDocumentControllerProvider = NotifierProvider.autoDispose
    .family<XlsxDocumentController, AsyncValue<Object?>, Object?>(
      XlsxDocumentController.new,
      retry: (int _, Object _) => null,
    );
