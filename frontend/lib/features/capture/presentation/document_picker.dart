import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/files/document_picker.dart' as platform;
import 'package:tapture/core/files/file_validation.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

import '../domain/capture_document_format.dart';

/// Picks and validates original documents at the same gate as other imports.
final class DocumentPicker extends ConsumerWidget {
  /// Production uses the platform picker; tests may supply [pickBytes].
  const DocumentPicker({
    required this.onImported,
    this.pickBytes,
    this.maxBytes,
    this.allowedExtensions = CaptureDocumentFormat.extensions,
    super.key,
  });

  /// Receives validated bytes without modifying the operator's source.
  final FutureOr<void> Function(Uint8List bytes, String filename) onImported;

  /// Focused picker seam for widget tests.
  final Future<({Uint8List bytes, String filename})?> Function()? pickBytes;

  /// An optional stricter ceiling; the standard import limit still applies.
  final int? maxBytes;

  /// Allowed lowercase extensions.
  final Set<String> allowedExtensions;

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final LocalizedCopy localCopy = Copy.of(context);

    try {
      final platform.PickedDocument chosen;
      final Future<({Uint8List bytes, String filename})?> Function()? pick =
          pickBytes;
      if (pick != null) {
        final ({Uint8List bytes, String filename})? value = await pick();
        if (value == null) return;
        chosen = platform.PickedBytes(value.bytes, value.filename);
      } else {
        chosen =
            (await ref
                    .read(platform.documentPickerProvider)
                    .pick(
                      extensions: allowedExtensions.toList(),
                      mimeType: CaptureDocumentFormat.pickerMimeTypes,
                      maxBytes:
                          maxBytes ?? AppConstants.imports.documentMaxBytes,
                    ))
                .fold(
                  (Failure failure) => throw failure,
                  (platform.PickedDocument value) => value,
                );
      }
      if (!allowedExtensions.contains(
            chosen.name.split('.').last.toLowerCase(),
          ) ||
          chosen.byteLength >
              (maxBytes ?? AppConstants.imports.documentMaxBytes)) {
        throw ValidationFailure(
          message: localCopy.captureDocumentInvalid(chosen.name),
          recoveryAction: localCopy.tryAnotherFile,
        );
      }
      (await FileValidation().validateDocument(
        chosen,
        allowed: CaptureDocumentFormat.kinds,
      )).fold((Failure failure) => throw failure, (_) {});
      final Uint8List bytes = (await platform.readPickedDocument(
        chosen,
      )).fold((Failure failure) => throw failure, (Uint8List value) => value);
      if (context.mounted) await onImported(bytes, chosen.name);
    } on CancelledFailure {
      return;
    } on Object catch (error) {
      if (context.mounted) {
        showAppSnack(
          context,
          localCopy.captureImportRejected(Failure.from(error).message),
          tone: SnackTone.warning,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppButton(
    label: Copy.of(context).captureImportDocument,
    variant: AppButtonVariant.secondary,
    onPressed: () => unawaited(_pick(context, ref)),
  );
}
