import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

import 'verification_session.dart';

/// The switch in project settings and on the session (task 015).
final class VerificationModeToggle extends ConsumerWidget {
  /// Creates the toggle. [failure] is the failure state.
  const VerificationModeToggle({this.failure, this.onChanged, super.key});

  /// Why the setting could not be read. Null when it could.
  final Failure? failure;

  /// Called with the next value. Null uses the session controller.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    final bool on = ref.watch(verificationSessionProvider);
    return AppSwitchTile(
      key: const ValueKey<String>('verification-mode'),
      title: localCopy.verificationModeTitle,
      description: on
          ? localCopy.verificationModeOn
          : localCopy.verificationModeOff,
      value: on,
      onChanged: (bool value) {
        final ValueChanged<bool>? changed = onChanged;
        if (changed != null) {
          changed(value);
          return;
        }
        ref.read(verificationSessionProvider.notifier).set(value);
      },
    );
  }
}
