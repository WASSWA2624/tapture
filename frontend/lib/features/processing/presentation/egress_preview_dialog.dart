import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';

/// Asks, with the shared confirm dialog, before the session's first online
/// call, naming what would leave the device. Cancel, Back or a tap outside
/// answers false and keeps the session offline.
Future<bool> showEgressPreview(
  BuildContext context, {
  required int imageCount,
  required int payloadBytes,
  String? selectionDetails,
}) {
  final LocalizedCopy localCopy = Copy.of(context);

  return showAppConfirm(
    context,
    title: localCopy.egressTitle,
    message: <String>[
      localCopy.egressBody(
        images: imageCount,
        size: localCopy.fileSize(payloadBytes),
      ),
      if (selectionDetails != null && selectionDetails.isNotEmpty)
        selectionDetails,
    ].join('\n\n'),
    confirmLabel: localCopy.egressSend,
  );
}
