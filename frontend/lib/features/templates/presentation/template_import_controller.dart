import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';

import '../domain/template_def.dart';
import '../templates.dart'
    show TemplateDocumentImport, templateRepositoryProvider;

/// Owns validated import preview and the explicit durable save.
final class TemplateImportController extends AsyncNotifier<TemplateDef?> {
  TemplateImportController(this.input);

  final ({String projectId, Object? payload}) input;
  final CancellationToken _cancel = CancellationToken();

  @override
  Future<TemplateDef?> build() async {
    ref.onDispose(_cancel.cancel);
    final Object? payload = input.payload;
    if (payload == null || (payload is String && payload.trim().isEmpty)) {
      return null;
    }
    return _value(
      await TemplateDocumentImport.payload(
        payload,
        projectId: input.projectId,
        cancel: _cancel,
      ),
    );
  }

  /// A workbook transfers to the existing mapping page; JSON stays in preview.
  Future<PickedDocument?> choose() async {
    if (state.isLoading) return null;
    final AsyncValue<TemplateDef?> previous = state;
    state = const AsyncLoading<TemplateDef?>();
    final Result<PickedDocument> picked = await ref
        .read(documentPickerProvider)
        .pick(
          extensions: TemplateDocumentImport.extensions,
          mimeType: '',
          maxBytes: AppConstants.imports.spreadsheetMaxBytes,
        );
    if (!ref.mounted) {
      if (picked case Success<PickedDocument>(:final PickedDocument value)) {
        await TemplateDocumentImport.discard(value);
      }
      return null;
    }
    if (picked case FailureResult<PickedDocument>(:final Failure failure)) {
      state = failure is CancelledFailure
          ? previous
          : AsyncError<TemplateDef?>(failure, StackTrace.current);
      return null;
    }
    final PickedDocument document = (picked as Success<PickedDocument>).value;
    var transferred = false;
    try {
      _value(await TemplateDocumentImport.validate(document));
      if (!ref.mounted) return null;
      if (!TemplateDocumentImport.isJson(document)) {
        transferred = true;
        state = const AsyncData<TemplateDef?>(null);
        return document;
      }
      final TemplateDef draft = _value(
        await TemplateDocumentImport.json(
          document,
          projectId: input.projectId,
          cancel: _cancel,
        ),
      );
      if (ref.mounted) state = AsyncData<TemplateDef?>(draft);
    } on Object catch (error, stack) {
      if (ref.mounted) {
        state = AsyncError<TemplateDef?>(Failure.from(error), stack);
      }
    } finally {
      if (!transferred) await TemplateDocumentImport.discard(document);
    }
    return null;
  }

  Future<Result<TemplateDef>?> save() async {
    final TemplateDef? draft = state.asData?.value;
    if (draft == null || state.isLoading) return null;
    state = const AsyncLoading<TemplateDef?>();
    final Result<TemplateDef> result = await ref
        .read(templateRepositoryProvider)
        .save(draft);
    if (ref.mounted) state = AsyncData<TemplateDef?>(draft);
    return result;
  }
}

final templateImportControllerProvider = AsyncNotifierProvider.autoDispose
    .family<
      TemplateImportController,
      TemplateDef?,
      ({String projectId, Object? payload})
    >(TemplateImportController.new, retry: (int _, Object _) => null);

T _value<T>(Result<T> result) => switch (result) {
  Success<T>(:final T value) => value,
  FailureResult<T>(:final Failure failure) => throw failure,
};
