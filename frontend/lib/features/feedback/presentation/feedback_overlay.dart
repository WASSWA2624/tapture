import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_floating_button.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/responsive/form_factor.dart';
import 'package:tapture/core/widgets/responsive/viewport_metrics.dart';
import 'package:tapture/features/settings/settings.dart';

import '../domain/feedback_origin.dart';
import 'delete_feedback_controller.dart';
import 'delete_feedback_screen.dart';
import 'download_feedback_controller.dart';
import 'download_feedback_screen.dart';
import 'feedback_context_capture.dart';
import 'feedback_draft.dart';
import 'feedback_draft_controller.dart';
import 'feedback_providers.dart';
import 'give_feedback_controller.dart';
import 'give_feedback_screen.dart';
import 'open_feedback_flow.dart';

/// Hosts the draggable Feedback control over [child] and opens the three
/// flows from its menu. The shell supplies [origin]; this widget never
/// reads the router.
class FeedbackOverlay extends ConsumerStatefulWidget {
  /// Creates the overlay.
  const FeedbackOverlay({super.key, required this.child, required this.origin});

  /// The current screen, under the floating control.
  final Widget child;

  /// Where Feedback is being tapped from.
  final FeedbackOrigin origin;

  @override
  ConsumerState<FeedbackOverlay> createState() => _FeedbackOverlayState();
}

class _FeedbackOverlayState extends ConsumerState<FeedbackOverlay> {
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        RepaintBoundary(key: _boundaryKey, child: widget.child),
        AppFloatingButton(
          key: const ValueKey<String>('feedback-button'),
          icon: Icons.feedback_outlined,
          label: Copy.feedback,
          hint: Copy.feedbackButtonHint,
          expandOnHover: context.formFactor == FormFactor.desktop,
          startX: AppConstants.userFeedback.buttonStartX,
          startY: AppConstants.userFeedback.buttonStartY,
          onPressed: (Rect anchor) {
            unawaited(_openMenu(anchor));
          },
        ),
      ],
    );
  }

  Future<void> _openMenu(Rect anchor) async {
    await _captureDraft();
    if (!mounted) {
      return;
    }
    await showAppOverflowActions(
      context,
      anchor: anchor,
      items: <AppOverflowAction>[
        AppOverflowAction(
          key: const ValueKey<String>('feedback-give'),
          icon: Icons.rate_review_outlined,
          label: Copy.feedbackGive,
          onTap: () => unawaited(_openGive()),
        ),
        AppOverflowAction(
          key: const ValueKey<String>('feedback-download'),
          icon: Icons.download_outlined,
          label: Copy.feedbackDownload,
          onTap: () => unawaited(_openDownload()),
        ),
        AppOverflowAction(
          key: const ValueKey<String>('feedback-delete'),
          icon: Icons.delete_outline,
          label: Copy.feedbackDelete,
          onTap: () => unawaited(_openDelete()),
        ),
      ],
    );
  }

  Future<void> _captureDraft() async {
    OperatorProfile? operator = ref.read(currentOperatorProvider);
    if (operator == null) {
      try {
        await ref.read(operatorProfileProvider.future);
        operator = ref.read(currentOperatorProvider);
      } on Object {
        operator = null;
      }
    }
    if (!mounted) {
      return;
    }
    final Uint8List? screenshot = await _screenshot();
    if (!mounted) {
      return;
    }
    ref
        .read(feedbackDraftProvider.notifier)
        .capture(
          FeedbackDraft(
            context: FeedbackContextCapture.from(
              context: context,
              origin: widget.origin,
              clock: ref.read(feedbackClockProvider),
              facts: ref.read(feedbackPlatformFactsProvider),
              device: ref.read(feedbackDeviceProvider),
              operator: operator,
              deviceId: ref.read(feedbackDeviceIdProvider),
            ),
            screenshot: screenshot,
          ),
        );
  }

  Future<Uint8List?> _screenshot() async {
    final BuildContext? boxContext = _boundaryKey.currentContext;
    if (boxContext == null) {
      return null;
    }
    final RenderObject? object = boxContext.findRenderObject();
    if (object is! RenderRepaintBoundary || !object.hasSize) {
      return null;
    }
    final ViewportMetrics metrics = context.viewportMetrics;
    final double longest = metrics.viewport.width > metrics.viewport.height
        ? metrics.viewport.width
        : metrics.viewport.height;
    if (longest <= 0) {
      return null;
    }
    final double edge = AppConstants.userFeedback.screenshotLongEdge.toDouble();
    final double physical = longest * metrics.devicePixelRatio;
    final double ratio = physical > edge
        ? edge / longest
        : metrics.devicePixelRatio;
    if (ratio <= 0) {
      return null;
    }
    try {
      final ui.Image image = await object.toImage(pixelRatio: ratio);
      try {
        final ByteData? bytes = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        return bytes?.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } on Object {
      return null;
    }
  }

  Future<void> _openGive() async {
    ref.invalidate(giveFeedbackControllerProvider);
    final bool? saved = await openFeedbackFlow<bool>(
      context,
      title: Copy.feedbackGive,
      page: const GiveFeedbackScreen(),
      panel: const GiveFeedbackScreen.embedded(),
    );
    if (saved == true && mounted) {
      showAppSnack(context, Copy.feedbackSaved, tone: SnackTone.success);
    }
  }

  Future<void> _openDownload() async {
    ref.invalidate(downloadFeedbackControllerProvider);
    await openFeedbackFlow<void>(
      context,
      title: Copy.feedbackDownload,
      page: const DownloadFeedbackScreen(),
      panel: const DownloadFeedbackScreen.embedded(),
    );
  }

  Future<void> _openDelete() async {
    ref.invalidate(deleteFeedbackControllerProvider);
    await openFeedbackFlow<void>(
      context,
      title: Copy.feedbackDelete,
      page: const DeleteFeedbackScreen(),
      panel: const DeleteFeedbackScreen.embedded(),
    );
  }
}
