import 'package:flutter/widgets.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/trial_report_scope.dart';

/// The shared overflow command, absent when no trial scope is installed.
AppOverflowAction? trialReportAction(BuildContext context) {
  final TrialReportScope? trial = TrialReportScope.of(context);
  return trial == null
      ? null
      : AppOverflowAction(
          key: const ValueKey<String>('field-trial-report'),
          label: trial.label,
          icon: AppIcons.friction,
          onTap: trial.onReport,
        );
}
