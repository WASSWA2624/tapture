import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// What would leave the device on the next online call.
///
/// Raised through [showEgressPreview], which uses the shared dialog.
class EgressPreviewDialog extends StatelessWidget {
  /// Creates the preview. [failure] replaces the body with the error state.
  const EgressPreviewDialog({
    super.key,
    required this.imageCount,
    required this.payloadBytes,
    this.failure,
  });

  /// Images that would be attached.
  final int imageCount;

  /// Approximate payload size, in bytes.
  final int payloadBytes;

  /// Set when the preview itself could not be built.
  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    final Failure? failure = this.failure;
    if (failure != null) {
      return AppErrorState(failure: failure);
    }
    if (imageCount == 0 && payloadBytes == 0) {
      return const AppEmptyState(
        icon: AppIcons.offline,
        headline: Copy.egressEmptyHeadline,
        message: Copy.egressEmptyMessage,
      );
    }
    return Text(Copy.egressBody(images: imageCount, size: _size(payloadBytes)));
  }
}

/// Asks with the shared confirm dialog. False leaves the session offline.
Future<bool> showEgressPreview(
  BuildContext context, {
  required int imageCount,
  required int payloadBytes,
  Failure? failure,
}) {
  if (failure != null || (imageCount == 0 && payloadBytes == 0)) {
    return showAppAlert(
      context,
      title: Copy.egressTitle,
      message: failure?.message ?? Copy.egressEmptyMessage,
    ).then((_) => false);
  }
  return showAppConfirm(
    context,
    title: Copy.egressTitle,
    message: Copy.egressBody(images: imageCount, size: _size(payloadBytes)),
    confirmLabel: Copy.egressSend,
    alternativeLabel: Copy.egressDecline,
  );
}

String _size(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  return '${(bytes / 1024).round()} KB';
}
