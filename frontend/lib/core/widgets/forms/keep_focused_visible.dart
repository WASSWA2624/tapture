import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:tapture/core/constants/app_constants.dart';

/// Scrolls the focused descendant above the keyboard as focus moves
/// (FE-RESP-06, FE-A11Y-06).
class KeepFocusedVisible extends StatelessWidget {
  /// Creates a keeper. [child] is usually a scrollable form body.
  const KeepFocusedVisible({super.key, required this.child});

  /// Subtree whose focused control must stay in view.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _KeepFocusedVisibleHost(child: child);
  }
}

class _KeepFocusedVisibleHost extends StatefulWidget {
  const _KeepFocusedVisibleHost({required this.child});

  final Widget child;

  @override
  State<_KeepFocusedVisibleHost> createState() =>
      _KeepFocusedVisibleHostState();
}

class _KeepFocusedVisibleHostState extends State<_KeepFocusedVisibleHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_scheduleEnsure);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_scheduleEnsure);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _scheduleEnsure();
  }

  void _scheduleEnsure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ensure();
      }
    });
  }

  void _ensure() {
    final FocusNode? node =
        FocusScope.of(context).focusedChild ??
        FocusManager.instance.primaryFocus;
    final BuildContext? focused = node?.context;
    if (focused == null || !focused.mounted) {
      return;
    }
    final RenderObject? render = focused.findRenderObject();
    if (render is! RenderBox || !render.attached || !render.hasSize) {
      return;
    }
    final ScrollableState? scrollable = Scrollable.maybeOf(focused);
    if (scrollable == null) {
      return;
    }
    final RenderAbstractViewport? viewport = RenderAbstractViewport.maybeOf(
      render,
    );
    if (viewport == null) {
      return;
    }
    final RevealedOffset revealed = viewport.getOffsetToReveal(render, 0);
    final double target = revealed.offset.clamp(
      scrollable.position.minScrollExtent,
      scrollable.position.maxScrollExtent,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      scrollable.position.jumpTo(target);
      return;
    }
    scrollable.position.animateTo(
      target,
      duration: AppConstants.motion.short,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
