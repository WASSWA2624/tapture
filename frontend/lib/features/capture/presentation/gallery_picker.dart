import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_picker.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

/// Multi-select gallery import into the capture session.
final class GalleryPicker extends StatelessWidget {
  /// Creates a picker.
  /// Library selection cap shared with the capture add sheet.
  static const int defaultLimit = 20;

  /// Long-edge scale shared with the capture add sheet.
  static const int defaultLongEdge = 2048;

  const GalleryPicker({
    required this.picker,
    required this.onImported,
    this.limit = defaultLimit,
    this.longEdge = defaultLongEdge,
    this.maxBytes = 25 * 1024 * 1024,
    super.key,
  });

  /// Photo library port.
  final PhotoPicker picker;

  /// Called with validated image bytes.
  final ValueChanged<List<Uint8List>> onImported;

  /// Max selection count.
  final int limit;

  /// Long-edge scale.
  final int longEdge;

  /// Reject oversized files.
  final int maxBytes;

  Future<void> _pick(BuildContext context) async {
    final Result<List<Uint8List>> result = await picker.choose(
      limit: limit,
      longEdge: longEdge,
    );
    result.fold(
      (Failure failure) {
        showAppSnack(context, failure.message, tone: SnackTone.error);
      },
      (List<Uint8List> photos) {
        final List<Uint8List> ok = <Uint8List>[];
        for (final Uint8List bytes in photos) {
          if (bytes.length > maxBytes) {
            showAppSnack(
              context,
              Copy.captureImportRejected('File too large.'),
              tone: SnackTone.warning,
            );
            continue;
          }
          if (!_looksLikeImage(bytes)) {
            showAppSnack(
              context,
              Copy.captureImportRejected('Not an image.'),
              tone: SnackTone.warning,
            );
            continue;
          }
          ok.add(bytes);
        }
        if (ok.isNotEmpty) {
          onImported(ok);
        }
      },
    );
  }

  static bool _looksLikeImage(Uint8List bytes) {
    if (bytes.length < 3) {
      return false;
    }
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return true;
    }
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: Copy.captureImportGallery,
      onPressed: () => _pick(context),
    );
  }
}
