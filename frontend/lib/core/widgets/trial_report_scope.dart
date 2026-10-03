import 'package:flutter/widgets.dart';

/// Supplies a local trial report action without coupling shared controls to a feature.
final class TrialReportScope extends InheritedWidget {
  /// Trial builds install this around the routed application.
  const TrialReportScope({
    super.key,
    required this.label,
    required this.onReport,
    required this.onAction,
    required super.child,
  });

  /// The named report command shared headers expose.
  final String label;

  /// Opens the report sheet without navigating away from the current task.
  final VoidCallback onReport;

  /// Records the most recent named user action without rebuilding the screen.
  final void Function(String label) onAction;

  /// The trial command, or null in ordinary builds.
  static TrialReportScope? of(BuildContext context) => _of(context);

  /// Remembers the action before its callback changes screen state.
  static void recordAction(BuildContext context, String label) {
    final TrialReportScope? scope = _of(context);
    if (scope != null && label != scope.label) {
      scope.onAction(label);
    }
  }

  static TrialReportScope? _of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TrialReportScope>();

  @override
  bool updateShouldNotify(TrialReportScope oldWidget) => false;
}
