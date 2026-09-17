import 'package:flutter/material.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// Catches a build error below it and shows a recoverable panel.
class ErrorBoundary extends StatefulWidget {
  /// Creates an error boundary around [child].
  const ErrorBoundary({super.key, required this.child, this.onRetry});

  /// The subtree that may throw while building.
  final Widget child;

  /// Called before the subtree is rebuilt after the operator retries.
  final VoidCallback? onRetry;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  ErrorWidgetBuilder? _previousBuilder;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _previousBuilder = ErrorWidget.builder;
    ErrorWidget.builder = _buildPanel;
  }

  @override
  void dispose() {
    ErrorWidget.builder = _previousBuilder ?? ErrorWidget.builder;
    super.dispose();
  }

  Widget _buildPanel(FlutterErrorDetails details) {
    return SafeArea(
      child: AppErrorState(
        failure: Failure.from(details.exception),
        onRetry: _retry,
      ),
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
