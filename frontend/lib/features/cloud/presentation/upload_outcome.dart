import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

import '../domain/upload_runner.dart';

/// The plain name of a stored or live upload outcome.
String uploadOutcomeLabel(String outcome, {LocalizedCopy? copy}) {
  final LocalizedCopy localized = copy ?? Copy.english;
  return switch (outcome) {
    'succeeded' => localized.uploadOutcomeSent,
    'failed' => localized.uploadOutcomeFailed,
    'cancelled' => localized.uploadOutcomeStopped,
    _ => localized.uploadOutcomeInterrupted,
  };
}

/// The glyph beside an attempt. Its meaning is also in the row's text.
IconData uploadOutcomeIcon(String outcome) {
  return switch (outcome) {
    'succeeded' => AppIcons.success,
    'failed' => AppIcons.error,
    'cancelled' => AppIcons.stopped,
    'sending' => AppIcons.upload,
    _ => AppIcons.warning,
  };
}

/// Says how a confirmed upload of [name] to [destination] ended.
void reportUpload(
  BuildContext host,
  UploadProgress outcome, {
  required String name,
  required String destination,
}) {
  final LocalizedCopy localCopy = Copy.of(host);

  switch (outcome.outcome) {
    case 'succeeded':
      showAppSnack(
        host,
        localCopy.uploadSent(name, destination),
        tone: SnackTone.success,
      );
    case 'cancelled':
      showAppSnack(host, localCopy.uploadStopped);
    default:
      showAppSnack(
        host,
        localCopy.uploadNotSent(
          outcome.localizedFailure == null
              ? outcome.failureReason ?? localCopy.uploadOutcomeFailed
              : localCopy.resolve(outcome.localizedFailure!),
        ),
        tone: SnackTone.error,
      );
  }
}
