import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';

/// Asks whether to resume or discard an interrupted capture session, naming
/// its photo count (task 012 step 19).
///
/// One dialog that must be answered: it has no Cancel, and neither the
/// barrier nor Back closes it, so the stored session is never dropped by a
/// stray tap. Discard is undone from a snack afterwards, not confirmed in a
/// second dialog.
abstract final class CaptureRecoveryPrompt {
  /// Shows the prompt for a session holding [photoCount] photos.
  static Future<CaptureRecoveryChoice> show(
    BuildContext context, {
    required int photoCount,
  }) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool resume = await showAppConfirm(
      context,
      title: localCopy.captureRecoveryTitle,
      message: localCopy.captureRecoveryMessage(photoCount),
      confirmLabel: localCopy.captureResume,
      alternativeLabel: localCopy.captureDiscard,
      dismissible: false,
    );
    return resume
        ? CaptureRecoveryChoice.resume
        : CaptureRecoveryChoice.discard;
  }
}

/// The operator's answer to [CaptureRecoveryPrompt].
enum CaptureRecoveryChoice {
  /// Restore the photos, captions and values.
  resume,

  /// Tombstone the photos, keeping them recoverable, and start afresh.
  discard,
}
