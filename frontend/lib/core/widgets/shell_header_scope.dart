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
    List<Widget> actions,
    List<AppOverflowAction> overflow,
  })?
  chromeOf(BuildContext context) {
    final _ShellHeader? scope = context
        .dependOnInheritedWidgetOfExactType<_ShellHeader>();
    if (scope == null || !scope.ownsHeader || scope.owner == null) {
      return null;
    }
    return (
      title: scope.title,
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
  }) {
    if (!_onStage(context)) {
      return;
    }
    context.findAncestorStateOfType<_ShellHeaderScopeState>()?.publish(
      owner: owner,
      title: title,
      actions: actions,
      overflow: overflow,
    );
  }

  /// Drops [owner]'s chrome when that page leaves the tree.
  static void release(BuildContext context, Object owner) {
    context.findAncestorStateOfType<_ShellHeaderScopeState>()?.release(owner);
  }

  @override
  State<ShellHeaderScope> createState() => _ShellHeaderScopeState();
}

class _ShellHeaderScopeState extends State<ShellHeaderScope> {
  Object? _owner;
  String _title = '';
  List<Widget> _actions = const <Widget>[];
  List<AppOverflowAction> _overflow = const <AppOverflowAction>[];

  void publish({
    required Object owner,
    required String title,
    required List<Widget> actions,
    required List<AppOverflowAction> overflow,
  }) {
    if (!mounted) {
      return;
    }
    if (_owner == owner &&
        _title == title &&
        identical(_actions, actions) &&
        identical(_overflow, overflow)) {
      return;
    }
    setState(() {
      _owner = owner;
      _title = title;
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
      _title = '';
      _actions = const <Widget>[];
      _overflow = const <AppOverflowAction>[];
    });
  }

  @override
  void didUpdateWidget(ShellHeaderScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ownsHeader && !widget.ownsHeader) {
      _owner = null;
      _title = '';
      _actions = const <Widget>[];
      _overflow = const <AppOverflowAction>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ShellHeader(
      ownsHeader: widget.ownsHeader,
      owner: _owner,
      title: _title,
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
    required this.title,
    required this.actions,
    required this.overflow,
    required super.child,
  });

  final bool ownsHeader;
  final Object? owner;
  final String title;
  final List<Widget> actions;
  final List<AppOverflowAction> overflow;

  @override
  bool updateShouldNotify(_ShellHeader oldWidget) {
    return ownsHeader != oldWidget.ownsHeader ||
        owner != oldWidget.owner ||
        title != oldWidget.title ||
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
