import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// Per-project switch that keeps every online action off.
final class AiDisableSwitch extends StatelessWidget {
  /// Creates the switch. A null [manual] with no [failure] is the empty state.
  const AiDisableSwitch({this.manual, this.failure, this.onChanged, super.key});

  /// Whether this project is manual only. Off means online actions exist.
  final bool? manual;

  /// Why the switch could not be read.
  final Failure? failure;

  /// Flips the switch for this project only.
  final ValueChanged<bool>? onChanged;

  /// Runs [send] only when the project still allows online work.
  static Future<void> guard({
    required bool aiEnabled,
    required Future<void> Function() send,
  }) async {
    if (!aiEnabled) {
      return;
    }
    await send();
  }

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    final bool? value = manual;
    if (value == null) {
      return const AppEmptyState(
        icon: AppIcons.project,
        headline: Copy.aiDisableTitle,
        message: Copy.aiDisableMessage,
      );
    }
    return AppSwitchTile(
      key: const ValueKey<String>('ai-disable'),
      title: Copy.aiDisableTitle,
      description: Copy.aiDisableMessage,
      value: value,
      onChanged: (bool next) => onChanged?.call(next),
    );
  }
}
