import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';

/// Resume or discard an interrupted session, naming the photo count.
final class CaptureRecoveryPrompt extends StatelessWidget {
  /// Creates a prompt.
  const CaptureRecoveryPrompt({
    required this.photoCount,
    required this.onResume,
    required this.onDiscard,
    super.key,
  });

  /// Photos in the interrupted session.
  final int photoCount;

  /// Resume restores photos, captions and values.
  final VoidCallback onResume;

  /// Discard after confirm; tombstones evidence.
  final Future<void> Function() onDiscard;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(Copy.captureRecoveryTitle),
      content: Text(Copy.captureRecoveryMessage(photoCount)),
      actions: <Widget>[
        AppButton(label: Copy.captureResume, onPressed: onResume),
        AppButton(
          label: Copy.captureDiscard,
          variant: AppButtonVariant.destructive,
          onPressed: () async {
            final bool ok = await showAppConfirm(
              context,
              title: Copy.captureDiscardTitle,
              message: Copy.captureDiscardMessage,
              confirmLabel: Copy.captureDiscard,
              destructive: true,
            );
            if (ok) {
              await onDiscard();
            }
          },
        ),
      ],
    );
  }
}
