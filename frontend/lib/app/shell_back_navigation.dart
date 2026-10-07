import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'shell_title.dart';

/// Shares header Back and Android's root fallback without replacing route guards.
class ShellBackNavigation extends StatefulWidget {
  /// Wraps the shell; [isWeb] keeps browser history under the browser's control.
  const ShellBackNavigation({
    required this.child,
    this.isWeb = kIsWeb,
    super.key,
  });

  /// The shell and its active branch navigators.
  final Widget child;

  /// Whether this runs in a browser; injectable for platform-policy tests.
  final bool isWeb;

  /// Gives overlays, route guards and child pages the first chance to go back.
  static Future<bool> back(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_ShellBackScope>()!.onBack();
  }

  @override
  State<ShellBackNavigation> createState() => _ShellBackNavigationState();
}

class _ShellBackNavigationState extends State<ShellBackNavigation> {
  Future<bool>? _pending;

  Future<bool> _back() =>
      _pending ??= _pop().whenComplete(() => _pending = null);

  Future<bool> _pop() async {
    final GoRouter router = GoRouter.of(context);
    final Uri before = router.state.uri;
    // maybePop also reports a refused PopScope as handled. The router checks
    // onExit and chooses the correct navigator for dialogs and nested branches.
    if (await router.routerDelegate.popRoute()) {
      return true;
    }
    if (!mounted || router.state.uri != before) {
      return true;
    }
    final String? parent = ShellTitle.backLocation(before);
    if (parent == null) {
      return false;
    }
    router.go(parent);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final Widget scope = _ShellBackScope(onBack: _back, child: widget.child);
    if (widget.isWeb || defaultTargetPlatform != TargetPlatform.android) {
      return scope;
    }
    return BackButtonListener(onBackButtonPressed: _back, child: scope);
  }
}

class _ShellBackScope extends InheritedWidget {
  const _ShellBackScope({required this.onBack, required super.child});

  final Future<bool> Function() onBack;

  @override
  bool updateShouldNotify(_ShellBackScope oldWidget) => false;
}
