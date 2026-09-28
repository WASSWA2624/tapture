import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/features/settings/domain/friction_log.dart';

/// One-tap report. Hidden unless a trial is on, so it never appears in the field.
class FrictionLogButton extends StatelessWidget {
  /// Creates the button. [trial] false builds nothing.
  const FrictionLogButton({
    super.key,
    required this.trial,
    required this.log,
    required this.screen,
    required this.action,
    required this.at,
  });

  /// Trial builds show the control. Production builds do not.
  final bool trial;

  /// Local log. Nothing is uploaded.
  final FrictionLog log;

  /// Screen the tester is on.
  final String screen;

  /// Last action on that screen.
  final String action;

  /// When the flag was raised.
  final DateTime at;

  @override
  Widget build(BuildContext context) {
    if (!trial) {
      return const SizedBox.shrink();
    }
    return AppIconButton(
      icon: Icons.flag_outlined,
      semanticLabel: Copy.frictionLogAction,
      tooltip: Copy.frictionLogAction,
      onPressed: () {
        log.logFriction(screen: screen, action: action, at: at);
      },
    );
  }
}
