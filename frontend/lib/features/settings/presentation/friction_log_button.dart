import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';

/// One-tap report, hidden in ordinary builds.
class FrictionLogButton extends StatelessWidget {
  /// Creates the button. [trial] false builds nothing.
  const FrictionLogButton({
    super.key,
    required this.trial,
    required this.onReport,
  });

  /// Trial builds show the control. Production builds do not.
  final bool trial;

  /// Opens the same local report sheet as the shared overflow command.
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    if (!trial) {
      return const SizedBox.shrink();
    }
    return AppIconButton(
      icon: AppIcons.friction,
      semanticLabel: localCopy.frictionLogAction,
      tooltip: localCopy.frictionLogAction,
      onPressed: onReport,
    );
  }
}
