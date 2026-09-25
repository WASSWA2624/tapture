import 'dart:async';
import 'dart:math' as math;
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
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/responsive/form_factor.dart';
import 'package:tapture/core/widgets/responsive/viewport_metrics.dart';
import 'package:tapture/features/settings/settings.dart';

import '../domain/feedback_origin.dart';
import 'delete_feedback_screen.dart';
import 'download_feedback_screen.dart';
import 'feedback_confirmations.dart';
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
/// a compact bar while the operator moves around. The app host supplies
/// [origin]; this widget never reads the router. [child] is the root Navigator,
/// so its dialogs, sheets and popup menus are captured while Feedback paints
/// and receives input in a separate layer above them.
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
  final GlobalKey _layerKey = GlobalKey();
  final GlobalKey _foldedKey = GlobalKey();
  final GlobalKey<NavigatorState> _feedbackNavigatorKey =
      GlobalKey<NavigatorState>();
  late final LeaveGuard _leaveGuard;
  late final ProviderSubscription<bool> _leave;
  late final LifecycleObserver _lifecycle;
  late final Future<bool> Function() _exitCheck;
  late final _FeedbackNavigatorObserver _navigatorObserver;
  bool _feedbackRouteCoversApp = false;
  bool _openingMenu = false;
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    _navigatorObserver = _FeedbackNavigatorObserver(_setRouteCoverage);
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
    _lifecycle = ref.read(lifecycleObserverProvider);
    _exitCheck = _confirmDesktopExit;
    _lifecycle.addExitCheck(_exitCheck);
  }

  @override
  void dispose() {
    _lifecycle.removeExitCheck(_exitCheck);
    _leave.close();
    _leaveGuard.release(this);
    super.dispose();
  }

  Future<bool> _confirmDesktopExit() async {
    if (!(ref.read(feedbackDraftProvider)?.hasWork ?? false)) {
      return true;
    }
    if (!mounted) {
      return false;
    }
    final BuildContext? uiContext = _layerKey.currentContext;
    if (uiContext == null) {
      return false;
    }
    final bool confirmed = await confirmDiscardFeedbackDraft(
      uiContext,
      images: ref.read(feedbackDraftProvider)?.shots.length ?? 0,
    );
    if (confirmed) {
      ref.read(feedbackDraftProvider.notifier).clear();
    }
    return confirmed;
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
    final bool docked = expanded && context.sizeClass == SizeClass.expanded;
    final Widget app = RepaintBoundary(key: _boundaryKey, child: widget.child);
    final Widget appFrame = docked
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: app),
              SizedBox(width: AppConstants.userFeedback.panelWidth),
            ],
          )
        : app;
    return RepaintBoundary(
      key: _workspaceKey,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          appFrame,
          Positioned.fill(
            child: _FeedbackHitRegion(
              hitTestAt: (Offset position) => _hitTestFeedback(
                context,
                position,
                open: fold.open,
                expanded: expanded,
                docked: docked,
              ),
              child: HeroControllerScope.none(
                child: Navigator(
                  key: _feedbackNavigatorKey,
                  observers: <NavigatorObserver>[_navigatorObserver],
                  onGenerateRoute: (RouteSettings settings) {
                    return PageRouteBuilder<void>(
                      settings: settings,
                      opaque: false,
                      barrierColor: null,
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      pageBuilder:
                          (
                            BuildContext _,
                            Animation<double> _,
                            Animation<double> _,
                          ) {
                            return _FeedbackLayer(key: _layerKey, host: this);
                          },
                    );
                  },
                ),
              ),
            ),
          ),
          if (!expanded)
            AppFloatingButton(
              key: const ValueKey<String>('feedback-button'),
              icon: AppIcons.feedback,
              label: Copy.feedback,
              hint: Copy.feedbackButtonHint,
              expandOnHover: context.formFactor == FormFactor.desktop,
              startX: AppConstants.userFeedback.buttonStartX,
              startY: AppConstants.userFeedback.buttonStartY,
              onPressed: (Rect anchor) {
                final BuildContext? uiContext = _layerKey.currentContext;
                if (uiContext != null) {
                  unawaited(_openMenu(uiContext, anchor));
                }
              },
            ),
        ],
      ),
    );
  }

  void _setRouteCoverage(bool coversApp) {
    if (!mounted || _feedbackRouteCoversApp == coversApp) {
      return;
    }
    setState(() => _feedbackRouteCoversApp = coversApp);
  }

  bool _hitTestFeedback(
    BuildContext context,
    Offset position, {
    required bool open,
    required bool expanded,
    required bool docked,
  }) {
    if (_feedbackRouteCoversApp) {
      return true;
    }
    if (expanded) {
      if (!docked) {
        return true;
      }
      final double panel = AppConstants.userFeedback.panelWidth;
      final double width =
          (context.findRenderObject() as RenderBox?)?.size.width ?? 0;
      return Directionality.of(context) == TextDirection.rtl
          ? position.dx <= panel
          : position.dx >= width - panel;
    }
    if (!open) {
      return false;
    }
    final RenderBox? folded =
        _foldedKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? overlay = context.findRenderObject() as RenderBox?;
    if (folded == null ||
        overlay == null ||
        !folded.hasSize ||
        !overlay.hasSize) {
      return false;
    }
    final Offset topLeft = overlay.globalToLocal(
      folded.localToGlobal(Offset.zero),
    );
    return (topLeft & folded.size).contains(position);
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

  Future<void> _openMenu(BuildContext uiContext, Rect anchor) async {
    if (_menuOpen) {
      _feedbackNavigatorKey.currentState?.pop();
      return;
    }
    if (_openingMenu) {
      return;
    }
    _openingMenu = true;
    try {
      final bool alreadyOpen = ref.read(feedbackDraftProvider)?.open ?? false;
      if (!alreadyOpen) {
        await _captureDraft();
      }
      if (!mounted || !uiContext.mounted) {
        return;
      }
      final bool open = ref.read(feedbackDraftProvider)?.open ?? false;
      _menuOpen = true;
      await showAppOverflowActions(
        uiContext,
        anchor: anchor,
        useRootNavigator: false,
        items: <AppOverflowAction>[
          AppOverflowAction(
            key: ValueKey<String>(open ? 'feedback-continue' : 'feedback-give'),
            icon: AppIcons.feedback,
            label: open ? Copy.feedbackContinue : Copy.feedbackGive,
            onTap: () => ref.read(feedbackDraftProvider.notifier).expand(),
          ),
          if (open)
            AppOverflowAction(
              key: const ValueKey<String>('feedback-add-screen'),
              icon: AppIcons.screenshot,
              label: Copy.feedbackAddScreen,
              onTap: () => unawaited(_addThisScreen(uiContext)),
            ),
          AppOverflowAction(
            key: const ValueKey<String>('feedback-download'),
            icon: AppIcons.download,
            label: Copy.feedbackDownload,
            onTap: () => unawaited(_openDownload(uiContext)),
          ),
          AppOverflowAction(
            key: const ValueKey<String>('feedback-delete'),
            icon: AppIcons.delete,
            label: Copy.feedbackDelete,
            onTap: () => unawaited(_openDelete(uiContext)),
          ),
        ],
      );
    } finally {
      _menuOpen = false;
      _openingMenu = false;
    }
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

  Future<void> _addThisScreen(BuildContext uiContext) async {
    final String? problem = await _captureDraft();
    if (!mounted || !uiContext.mounted) {
      return;
    }
    showAppSnack(
      uiContext,
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

  Future<void> _openDownload(BuildContext uiContext) async {
    await openFeedbackFlow<void>(
      uiContext,
      page: const DownloadFeedbackScreen(),
      useRootNavigator: false,
    );
  }

  Future<void> _openDelete(BuildContext uiContext) async {
    await openFeedbackFlow<void>(
      uiContext,
      page: const DeleteFeedbackScreen(),
      useRootNavigator: false,
    );
  }
}

/// The interaction layer has its own transparent Navigator. It is the final
/// child of the app-level Stack, so app routes, dialogs, sheets and popup menus
/// stay rendered below it while Feedback remains reachable above all of them.
class _FeedbackLayer extends ConsumerWidget {
  const _FeedbackLayer({super.key, required this.host});

  final _FeedbackOverlayState host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ({bool open, bool expanded}) fold = ref.watch(
      feedbackDraftProvider.select(
        (FeedbackDraft? d) =>
            (open: d?.open ?? false, expanded: d?.expanded ?? false),
      ),
    );
    final bool expanded = fold.open && fold.expanded;
    final bool docked = expanded && context.sizeClass == SizeClass.expanded;
    final Widget form = GiveFeedbackScreen(
      onAddScreen: () => unawaited(host._addThisScreen(context)),
    );
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (expanded && docked)
          PositionedDirectional(
            top: 0,
            end: 0,
            bottom: 0,
            width: AppConstants.userFeedback.panelWidth,
            child: host._dockedPanel(context, form),
          ),
        if (expanded && !docked) Positioned.fill(child: form),
        if (fold.open && !expanded)
          _FoldedFeedbackBar(
            key: host._foldedKey,
            onAddScreen: () => unawaited(host._addThisScreen(context)),
          ),
      ],
    );
  }
}

/// Positions the folded bar above the larger of its resting offset and the
/// keyboard, so only this widget rebuilds when the inset changes.
class _FoldedFeedbackBar extends StatelessWidget {
  const _FoldedFeedbackBar({super.key, this.onAddScreen});

  final VoidCallback? onAddScreen;

  @override
  Widget build(BuildContext context) {
    final bool compact = context.sizeClass == SizeClass.compact;
    final double resting = compact
        ? (Theme.of(context).navigationBarTheme.height ?? Sizes.minTapTarget) +
              MediaQuery.viewPaddingOf(context).bottom
        : 0;
    return PositionedDirectional(
      start: 0,
      end: 0,
      bottom: math.max(resting, MediaQuery.viewInsetsOf(context).bottom),
      child: FeedbackDraftBar(bottomInset: !compact, onAddScreen: onAddScreen),
    );
  }
}

class _FeedbackNavigatorObserver extends NavigatorObserver {
  _FeedbackNavigatorObserver(this.onCoverageChanged);

  final ValueChanged<bool> onCoverageChanged;
  int _routeCount = 0;
  bool _reportedCoverage = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeCount += 1;
    _reportCoverage();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeCount = math.max(0, _routeCount - 1);
    _reportAfterRemoval(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeCount = math.max(0, _routeCount - 1);
    _reportAfterRemoval(route);
  }

  void _reportAfterRemoval(Route<dynamic> route) {
    if (route is TransitionRoute<dynamic>) {
      unawaited(route.completed.then((_) => _reportCoverage()));
      return;
    }
    _reportCoverage();
  }

  void _reportCoverage() {
    final bool coverage = _routeCount > 1;
    if (_reportedCoverage == coverage) {
      return;
    }
    _reportedCoverage = coverage;
    onCoverageChanged(coverage);
  }
}

class _FeedbackHitRegion extends SingleChildRenderObjectWidget {
  const _FeedbackHitRegion({required this.hitTestAt, required super.child});

  final bool Function(Offset position) hitTestAt;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderFeedbackHitRegion(hitTestAt);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderFeedbackHitRegion renderObject,
  ) {
    renderObject.hitTestAt = hitTestAt;
  }
}

class _RenderFeedbackHitRegion extends RenderProxyBox {
  _RenderFeedbackHitRegion(this.hitTestAt);

  bool Function(Offset position) hitTestAt;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!hitTestAt(position)) {
      return false;
    }
    return super.hitTest(result, position: position);
  }
}
