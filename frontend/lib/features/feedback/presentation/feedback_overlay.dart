import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/lifecycle/lifecycle.dart';
import 'package:tapture/core/widgets/app_floating_button.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/responsive/form_factor.dart';
import 'package:tapture/core/widgets/responsive/viewport_metrics.dart';
import 'package:tapture/features/settings/settings.dart';

import '../domain/feedback_origin.dart';
import 'delete_feedback_screen.dart';
import 'download_feedback_screen.dart';
import 'feedback_context_capture.dart';
import 'feedback_draft.dart';
import 'feedback_draft_bar.dart';
import 'feedback_draft_controller.dart';
import 'feedback_providers.dart';
import 'give_feedback_screen.dart';
import 'open_feedback_flow.dart';

/// Hosts the draggable Feedback control over [child] and opens the flows
/// from its menu. Give us feedback is a persistent workspace: a side panel
/// beside the app on wide windows, the whole screen on narrower ones, and
/// a compact bar while the operator moves around. The shell supplies
/// [origin]; this widget never reads the router.
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
  final GlobalKey _workspaceKey = GlobalKey();
  late final LeaveGuard _leaveGuard;
  late final ProviderSubscription<bool> _leave;

  @override
  void initState() {
    super.initState();
    _leaveGuard = ref.read(leaveGuardProvider);
    _leave = ref.listenManual<bool>(
      feedbackDraftProvider.select((FeedbackDraft? d) => d?.hasWork ?? false),
      (bool? _, bool next) {
        if (next) {
          _leaveGuard.hold(this);
        } else {
          _leaveGuard.release(this);
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _leave.close();
    _leaveGuard.release(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only the fold state is watched: typing into the draft must not
    // rebuild the shell underneath.
    final ({bool open, bool expanded}) fold = ref.watch(
      feedbackDraftProvider.select(
        (FeedbackDraft? d) =>
            (open: d?.open ?? false, expanded: d?.expanded ?? false),
      ),
    );
    final bool expanded = fold.open && fold.expanded;
    final bool compact = context.sizeClass == SizeClass.compact;
    final bool docked = expanded && context.sizeClass == SizeClass.expanded;
    final Widget form = GiveFeedbackScreen(
      onAddScreen: () => unawaited(_addThisScreen()),
    );
    final Widget app = RepaintBoundary(key: _boundaryKey, child: widget.child);
    return Stack(
      children: <Widget>[
        if (docked)
          RepaintBoundary(
            key: _workspaceKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: app),
                SizedBox(
                  width: AppConstants.userFeedback.panelWidth,
                  child: _dockedPanel(context, form),
                ),
              ],
            ),
          )
        else
          app,
        if (expanded && !docked)
          Positioned.fill(
            child: RepaintBoundary(key: _workspaceKey, child: form),
          ),
        if (fold.open && !expanded)
          PositionedDirectional(
            start: 0,
            end: 0,
            // Above the phone's navigation bar, which already spans the
            // gesture inset; elsewhere the bar takes the inset itself.
            bottom: compact
                ? (Theme.of(context).navigationBarTheme.height ??
                          Sizes.minTapTarget) +
                      MediaQuery.viewPaddingOf(context).bottom
                : 0,
            child: FeedbackDraftBar(bottomInset: !compact),
          ),
        if (!expanded)
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

  Widget _dockedPanel(BuildContext context, Widget form) {
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(
            color: context.colors.outline,
            width: Theme.of(context).dividerTheme.thickness ?? Space.x0 / 2,
          ),
        ),
      ),
      child: form,
    );
  }

  Future<void> _openMenu(Rect anchor) async {
    final bool alreadyOpen = ref.read(feedbackDraftProvider)?.open ?? false;
    if (!alreadyOpen) {
      await _captureDraft();
    }
    if (!mounted) {
      return;
    }
    final bool open = ref.read(feedbackDraftProvider)?.open ?? false;
    await showAppOverflowActions(
      context,
      anchor: anchor,
      items: <AppOverflowAction>[
        AppOverflowAction(
          key: ValueKey<String>(open ? 'feedback-continue' : 'feedback-give'),
          icon: Icons.rate_review_outlined,
          label: open ? Copy.feedbackContinue : Copy.feedbackGive,
          onTap: () => ref.read(feedbackDraftProvider.notifier).expand(),
        ),
        if (open)
          AppOverflowAction(
            key: const ValueKey<String>('feedback-add-screen'),
            icon: Icons.screenshot_monitor_outlined,
            label: Copy.feedbackAddScreen,
            onTap: () => unawaited(_addThisScreen()),
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

  /// Captures this screen into the draft. Returns why an open draft could
  /// not take it, or null.
  Future<String?> _captureDraft() async {
    final FeedbackDraft? open = ref.read(feedbackDraftProvider);
    OperatorProfile? operator = ref.read(currentOperatorProvider);
    if (operator == null && (open == null || !open.open)) {
      try {
        await ref.read(operatorProfileProvider.future);
        operator = ref.read(currentOperatorProvider);
      } on Object {
        operator = null;
      }
    }
    if (!mounted) {
      return null;
    }
    final Uint8List? screenshot = await _screenshot();
    if (!mounted) {
      return null;
    }
    return ref
        .read(feedbackDraftProvider.notifier)
        .capture(
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
        );
  }

  Future<void> _addThisScreen() async {
    final String? problem = await _captureDraft();
    if (!mounted) {
      return;
    }
    showAppSnack(
      context,
      problem ?? Copy.feedbackShotAdded(widget.origin.screen),
      tone: problem == null ? SnackTone.success : SnackTone.warning,
    );
  }

  Future<Uint8List?> _screenshot() async {
    final FeedbackDraft? draft = ref.read(feedbackDraftProvider);
    final bool includeWorkspace =
        (draft?.includeUi ?? false) && (draft?.expanded ?? false);
    if (includeWorkspace) {
      final Uint8List? workspace = await _capture(_workspaceKey);
      if (workspace != null) {
        return workspace;
      }
    }
    return _capture(_boundaryKey);
  }

  Future<Uint8List?> _capture(GlobalKey key) async {
    final BuildContext? boxContext = key.currentContext;
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
      // The operator asked for this shot; rasterize the frame they see.
      final ui.Image image = object.toImageSync(pixelRatio: ratio);
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

  Future<void> _openDownload() async {
    await openFeedbackFlow<void>(context, page: const DownloadFeedbackScreen());
  }

  Future<void> _openDelete() async {
    await openFeedbackFlow<void>(context, page: const DeleteFeedbackScreen());
  }
}
