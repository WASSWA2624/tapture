import 'package:flutter/material.dart';
import 'package:tapture/core/errors/failure.dart';

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
    return _FailurePanel(
      failure: Failure.from(details.exception),
      onRetry: _retry,
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

class _FailurePanel extends StatelessWidget {
  const _FailurePanel({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(failure.message, style: textTheme.bodyLarge),
            if (failure.recoveryAction case final String action) ...<Widget>[
              const SizedBox(height: 8),
              Text(action, style: textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
