import 'package:flutter/material.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// Catches a build error below it and shows a recoverable panel.
class ErrorBoundary extends StatefulWidget {
  /// Creates an error boundary around [child].
  const ErrorBoundary({
    super.key,
    required this.child,
    this.onRetry,
    this.fallback,
  });

  /// The subtree that may throw while building.
  final Widget child;

  /// Called before the subtree is rebuilt after the operator retries.
  final VoidCallback? onRetry;

  /// Last-resort screen for a build failure. When null, a compact
  /// [AppErrorState] is shown instead.
  final Widget Function(Failure failure, VoidCallback retry)? fallback;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  static final List<_ErrorBoundaryState> _stack = <_ErrorBoundaryState>[];
  static ErrorWidgetBuilder? _rootPrevious;

  int _generation = 0;

  @override
  void initState() {
    super.initState();
    if (_stack.isEmpty) {
      _rootPrevious = ErrorWidget.builder;
    }
    _stack.add(this);
    ErrorWidget.builder = _dispatch;
  }

  @override
  void dispose() {
    _stack.remove(this);
    if (_stack.isEmpty) {
      ErrorWidget.builder = _rootPrevious ?? ErrorWidget.builder;
      _rootPrevious = null;
    } else {
      ErrorWidget.builder = _dispatch;
    }
    super.dispose();
  }

  /// Dispatches to the innermost mounted boundary. A stack is required
  /// because a replacement root can mount the next boundary before the
  /// previous one disposes, and a single previous-pointer would restore
  /// a stale builder (flutter_test checks this at the end of every test).
  static Widget _dispatch(FlutterErrorDetails details) {
    if (_stack.isEmpty) {
      return (_rootPrevious ?? ErrorWidget.builder)(details);
    }
    return _stack.last._buildPanel(details);
  }

  Widget _buildPanel(FlutterErrorDetails details) {
    final Failure failure = Failure.from(details.exception);
    final Widget Function(Failure failure, VoidCallback retry)? fallback =
        widget.fallback;
    if (fallback != null) {
      return fallback(failure, _retry);
    }
    return SafeArea(
      child: AppErrorState(failure: failure, onRetry: _retry),
    );
  }

  void _retry() {
    widget.onRetry?.call();
    setState(() => _generation++);
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: ValueKey<int>(_generation), child: widget.child);
  }
}
