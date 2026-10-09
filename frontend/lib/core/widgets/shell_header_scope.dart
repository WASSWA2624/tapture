import 'package:flutter/material.dart';

import 'app_overflow_menu.dart';

/// Owns whether the shell header replaces the page bar, and the actions
/// the page publishes into that row.
///
/// The status line sits beside the page, not under it, so an inherited
/// widget from the page cannot reach it. The shell wraps both, and the
/// page publishes upward through this scope (FE-STR-04).
class ShellHeaderScope extends StatefulWidget {
  /// Creates a scope. [ownsHeader] is true on every route that is not a
  /// branch root.
  const ShellHeaderScope({
    super.key,
    required this.ownsHeader,
    required this.child,
  });

  /// When true, the shell draws the title and the page hides its own bar.
  final bool ownsHeader;

  /// Shell chrome and the routed page.
  final Widget child;

  /// Whether the shell is drawing the header. Does not subscribe: the page
  /// rebuilds with its parent when the route changes, and subscribing would
  /// loop when a publish updates the scope.
  static bool ownsHeaderOf(BuildContext context) {
    final _ShellHeader? scope = context
        .getInheritedWidgetOfExactType<_ShellHeader>();
    return scope?.ownsHeader ?? false;
  }

  /// The page's title and actions, when the shell owns the header.
  static ({
    String title,
    String? headerTitle,
    String? headerDetail,
    List<Widget> actions,
    List<AppOverflowAction> overflow,
  })?
  chromeOf(BuildContext context) {
    final _ShellHeader? scope = context
        .dependOnInheritedWidgetOfExactType<_ShellHeader>();
    if (scope == null ||
        !scope.ownsHeader ||
        scope.owner == null ||
        scope.ownerContext == null ||
        !scope.ownerContext!.mounted ||
        !_onStage(scope.ownerContext!)) {
      return null;
    }
    return (
      title: scope.title,
      headerTitle: scope.headerTitle,
      headerDetail: scope.headerDetail,
      actions: scope.actions,
      overflow: scope.overflow,
    );
  }

  /// Publishes [title] and the page's actions. Ignored when [owner] is off
  /// stage, so a kept-alive branch cannot overwrite the visible page.
  static void publish(
    BuildContext context, {
    required Object owner,
    required String title,
    required List<Widget> actions,
    required List<AppOverflowAction> overflow,
    String? headerTitle,
    String? headerDetail,
  }) {
    if (!_onStage(context)) {
      return;
    }
    context.findAncestorStateOfType<_ShellHeaderScopeState>()?.publish(
      ownerContext: context,
      owner: owner,
      title: title,
      headerTitle: headerTitle,
      headerDetail: headerDetail,
      actions: actions,
      overflow: overflow,
    );
  }

  /// Drops [owner]'s chrome when that page leaves the tree.
  static void release(BuildContext context, Object owner) {
    final _ShellHeaderScopeState? scope =
        context is StatefulElement && context.state is _ShellHeaderScopeState
        ? context.state as _ShellHeaderScopeState
        : context.findAncestorStateOfType<_ShellHeaderScopeState>();
    // Deactivation can occur while the ancestor is rebuilding. Publish its
    // cleared state on the next frame instead of losing that notification.
    WidgetsBinding.instance.addPostFrameCallback((_) => scope?.release(owner));
  }

  @override
  State<ShellHeaderScope> createState() => _ShellHeaderScopeState();
}

class _ShellHeaderScopeState extends State<ShellHeaderScope> {
  Object? _owner;
  BuildContext? _ownerContext;
  String _title = '';
  String? _headerTitle;
  String? _headerDetail;
  List<Widget> _actions = const <Widget>[];
  List<AppOverflowAction> _overflow = const <AppOverflowAction>[];

  void publish({
    required BuildContext ownerContext,
    required Object owner,
    required String title,
    required List<Widget> actions,
    required List<AppOverflowAction> overflow,
    String? headerTitle,
    String? headerDetail,
  }) {
    if (!mounted) {
      return;
    }
    if (_owner == owner &&
        _title == title &&
        _headerTitle == headerTitle &&
        _headerDetail == headerDetail &&
        identical(_actions, actions) &&
        identical(_overflow, overflow)) {
      return;
    }
    setState(() {
      _owner = owner;
      _ownerContext = ownerContext;
      _title = title;
      _headerTitle = headerTitle;
      _headerDetail = headerDetail;
      _actions = actions;
      _overflow = overflow;
    });
  }

  void release(Object owner) {
    if (!mounted || _owner != owner) {
      return;
    }
    setState(() {
      _owner = null;
      _ownerContext = null;
      _title = '';
      _headerTitle = null;
      _headerDetail = null;
      _actions = const <Widget>[];
      _overflow = const <AppOverflowAction>[];
    });
  }

  @override
  void didUpdateWidget(ShellHeaderScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ownsHeader && !widget.ownsHeader) {
      _owner = null;
      _ownerContext = null;
      _title = '';
      _headerTitle = null;
      _headerDetail = null;
      _actions = const <Widget>[];
      _overflow = const <AppOverflowAction>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ShellHeader(
      ownsHeader: widget.ownsHeader,
      owner: _owner,
      ownerContext: _ownerContext,
      title: _title,
      headerTitle: _headerTitle,
      headerDetail: _headerDetail,
      actions: _actions,
      overflow: _overflow,
      child: widget.child,
    );
  }
}

class _ShellHeader extends InheritedWidget {
  const _ShellHeader({
    required this.ownsHeader,
    required this.owner,
    required this.ownerContext,
    required this.title,
    required this.headerTitle,
    required this.headerDetail,
    required this.actions,
    required this.overflow,
    required super.child,
  });

  final bool ownsHeader;
  final Object? owner;
  final BuildContext? ownerContext;
  final String title;
  final String? headerTitle;
  final String? headerDetail;
  final List<Widget> actions;
  final List<AppOverflowAction> overflow;

  @override
  bool updateShouldNotify(_ShellHeader oldWidget) {
    return ownsHeader != oldWidget.ownsHeader ||
        owner != oldWidget.owner ||
        title != oldWidget.title ||
        headerTitle != oldWidget.headerTitle ||
        headerDetail != oldWidget.headerDetail ||
        !identical(actions, oldWidget.actions) ||
        !identical(overflow, oldWidget.overflow);
  }
}

bool _onStage(BuildContext context) {
  bool onStage = true;
  context.visitAncestorElements((Element element) {
    final Widget widget = element.widget;
    if (widget is Offstage && widget.offstage) {
      onStage = false;
      return false;
    }
    return true;
  });
  return onStage;
}
