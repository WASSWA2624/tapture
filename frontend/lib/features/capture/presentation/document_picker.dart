import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

/// Attaches PDF/document bytes after extension and magic validation.
final class DocumentPicker extends StatelessWidget {
  /// Creates a picker. [pickBytes] is the test/import seam (no file plugin).
  const DocumentPicker({
    required this.onImported,
    this.pickBytes,
    this.maxBytes = 40 * 1024 * 1024,
    this.allowedExtensions = const <String>{'pdf', 'png', 'jpg', 'jpeg'},
    super.key,
  });

  /// Validated document bytes + original filename.
  final void Function(Uint8List bytes, String filename) onImported;

  /// Optional seam that returns bytes and a filename.
  final Future<({Uint8List bytes, String filename})?> Function()? pickBytes;

  /// Size ceiling.
  final int maxBytes;

  /// Allowed extensions (lowercase, no dot).
  final Set<String> allowedExtensions;

  Future<void> _pick(BuildContext context) async {
    final Future<({Uint8List bytes, String filename})?> Function()? pick =
        pickBytes;
    if (pick == null) {
      if (!context.mounted) {
        return;
      }
      showAppSnack(
        context,
        Copy.captureImportRejected(Copy.pdfInvalid),
        tone: SnackTone.warning,
      );
      return;
    }
    final ({Uint8List bytes, String filename})? chosen = await pick();
    if (!context.mounted) {
      return;
    }
    if (chosen == null) {
      return;
    }
    final String ext = chosen.filename.contains('.')
        ? chosen.filename.split('.').last.toLowerCase()
        : '';
    if (!allowedExtensions.contains(ext)) {
      showAppSnack(
        context,
        Copy.captureImportRejected('Wrong file type.'),
        tone: SnackTone.warning,
      );
      return;
    }
    if (chosen.bytes.length > maxBytes) {
      showAppSnack(
        context,
        Copy.captureImportRejected('File too large.'),
        tone: SnackTone.warning,
      );
      return;
    }
    if (ext == 'pdf' && !_isPdf(chosen.bytes)) {
      showAppSnack(
        context,
        Copy.captureImportRejected(Copy.pdfInvalid),
        tone: SnackTone.warning,
      );
      return;
    }
    onImported(chosen.bytes, chosen.filename);
  }

  static bool _isPdf(Uint8List bytes) {
    return bytes.length >= 5 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: Copy.captureImportDocument,
      onPressed: () => _pick(context),
    );
  }
}
