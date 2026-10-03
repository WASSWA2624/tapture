import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';

/// Asks whether to drop the in-progress feedback draft, naming how many
/// images it holds (FE-SIMP-07).
Future<bool> confirmDiscardFeedbackDraft(
  BuildContext context, {
  required int images,
}) {
  final LocalizedCopy localCopy = Copy.of(context);

  return showAppConfirm(
    context,
    title: localCopy.feedbackDiscardDraftTitle,
    message: localCopy.feedbackDiscardDraftMessage(images),
    confirmLabel: localCopy.discard,
    destructive: true,
    useRootNavigator: false,
  );
}
