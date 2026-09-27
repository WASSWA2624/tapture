import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'document_picker_stub.dart'
    if (dart.library.io) 'document_picker_io.dart'
    if (dart.library.js_interop) 'document_picker_web.dart'
    as platform;
import 'picked_document.dart';

export 'picked_document.dart';

/// Picks one document, such as a project package, from the device. The
/// files channel, the desktop file dialogs and the browser's file input are
/// reached only here (FE-STR-11). Tests use [DocumentPicker.fake].
abstract interface class DocumentPicker {
  /// The platform picker.
  factory DocumentPicker() => platform.platformDocumentPicker();

  /// A stand-in that returns [document], or [failure], or a cancel when
  /// neither is given.
  const factory DocumentPicker.fake({
    PickedDocument? document,
    Failure? failure,
    bool canPick,
  }) = _FakeDocumentPicker;

  /// Whether this platform can offer a document picker.
  bool get canPick;

  /// The chosen document, [CancelledFailure] when the operator closes the
  /// picker, or a failure. [extensions] are without the dot. In a browser, a
  /// file larger than [maxBytes] is refused before it is read into memory.
  Future<Result<PickedDocument>> pick({
    required List<String> extensions,
    required String mimeType,
    int? maxBytes,
  });
}

/// The process-wide [DocumentPicker].
final Provider<DocumentPicker> documentPickerProvider =
    Provider<DocumentPicker>((_) {
      return DocumentPicker();
    });

final class _FakeDocumentPicker implements DocumentPicker {
  const _FakeDocumentPicker({
    this.document,
    this.failure,
    this.canPick = true,
  });

  final PickedDocument? document;
  final Failure? failure;

  @override
  final bool canPick;

  @override
  Future<Result<PickedDocument>> pick({
    required List<String> extensions,
    required String mimeType,
    int? maxBytes,
  }) async {
    final Failure? failure = this.failure;
    if (failure != null) {
      return FailureResult<PickedDocument>(failure);
    }
    final PickedDocument? document = this.document;
    if (document == null) {
      return const FailureResult<PickedDocument>(CancelledFailure());
    }
    return Success<PickedDocument>(document);
  }
}
