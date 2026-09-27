import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';

/// Asks once before any upload. Confirm and cancel are the only answers.
///
/// Cancel returns false before a request is built and before a credential
/// is read. There is no remembered consent: each call asks again.
Future<bool> confirmUpload(
  BuildContext context, {
  required String name,
  required String size,
  required String destination,
  required String folder,
}) {
  return showAppConfirm(
    context,
    title: Copy.uploadConfirmTitle,
    message: Copy.uploadConfirmMessage(
      name: name,
      size: size,
      destination: destination,
      folder: folder,
    ),
    confirmLabel: Copy.uploadConfirm,
  );
}
