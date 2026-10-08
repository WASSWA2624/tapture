import 'dart:async';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart' as platform;
import 'package:tapture/core/files/file_validation.dart';

import '../domain/capture_document_format.dart';

/// Validates original document intake before handing bytes to durable capture.
abstract final class ImportCaptureDocument {
  /// Uses the existing picker and import gate; cancellation remains typed.
  static Future<Result<void>> run({
    required platform.DocumentPicker picker,
    required FutureOr<void> Function(Uint8List bytes, String filename)
    onImported,
    Future<({Uint8List bytes, String filename})?> Function()? pickBytes,
    int? maxBytes,
    Set<String> allowedExtensions = CaptureDocumentFormat.extensions,
  }) => Result.captureAsync<void>(() async {
    final int ceiling = maxBytes ?? AppConstants.imports.documentMaxBytes;
    final platform.PickedDocument chosen;
    if (pickBytes != null) {
      final ({Uint8List bytes, String filename})? value = await pickBytes();
      if (value == null) throw const CancelledFailure();
      chosen = platform.PickedBytes(value.bytes, value.filename);
    } else {
      chosen = (await picker.pick(
        extensions: allowedExtensions.toList(),
        mimeType: CaptureDocumentFormat.pickerMimeTypes,
        maxBytes: ceiling,
      )).getOrThrow();
    }
    if (!allowedExtensions.contains(
          chosen.name.split('.').last.toLowerCase(),
        ) ||
        chosen.byteLength > ceiling) {
      throw ValidationFailure(
        localizedMessage: Copy.messages.captureDocumentInvalid(chosen.name),
        localizedRecovery: Copy.messages.tryAnotherFile,
      );
    }
    (await FileValidation().validateDocument(
      chosen,
      allowed: CaptureDocumentFormat.kinds,
    )).getOrThrow();
    final Uint8List bytes = (await platform.readPickedDocument(
      chosen,
    )).getOrThrow();
    await onImported(bytes, chosen.name);
  });
}
