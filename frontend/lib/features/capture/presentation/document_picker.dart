import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart' as platform;
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

import '../domain/capture_document_format.dart';
import 'import_capture_document.dart';

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
    final Result<void> imported = await ImportCaptureDocument.run(
      picker: ref.read(platform.documentPickerProvider),
      pickBytes: pickBytes,
      maxBytes: maxBytes,
      allowedExtensions: allowedExtensions,
      onImported: (Uint8List bytes, String name) async {
        if (context.mounted) await onImported(bytes, name);
      },
    );
    if (!context.mounted) return;
    if (imported case FailureResult<void>(
      :final Failure failure,
    ) when failure is! CancelledFailure) {
      final LocalizedCopy localCopy = Copy.of(context);
      showAppSnack(
        context,
        localCopy.captureImportRejected(localCopy.resolve(failure.explanation)),
        tone: SnackTone.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppButton(
    label: Copy.of(context).captureImportDocument,
    variant: AppButtonVariant.secondary,
    onPressed: () => unawaited(_pick(context, ref)),
  );
}
