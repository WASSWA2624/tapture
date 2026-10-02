import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/security/consent_stamp.dart';
import 'package:tapture/core/time/clock.dart';

import 'app_switch_tile.dart';

/// Identity stamped when the operator explicitly confirms consent.
final Provider<String> consentActorProvider = Provider<String>((Ref _) => '');

/// Clock stamped on consent; production and tests bind the shared clock.
final Provider<Clock> consentClockProvider = Provider<Clock>(
  (Ref _) => const SystemClock(),
);

/// Standard consent control. A toggle stores who and when, not a boolean.
final class AppConsentField extends ConsumerWidget {
  /// Creates the control for a consent field.
  const AppConsentField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.helpText,
    super.key,
  });

  /// Template label.
  final String label;

  /// Existing record stamp.
  final Object? value;

  /// Template's explanation of the requested consent.
  final String? helpText;

  /// Receives a stamp after confirmation or null after withdrawal.
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String actor = ref.watch(consentActorProvider);
    return AppSwitchTile(
      title: label,
      description: helpText,
      enabled: actor.trim().isNotEmpty,
      value: ConsentStamp.parse(value) != null,
      onChanged: (bool checked) {
        if (actor.trim().isEmpty) return;
        onChanged(
          checked
              ? ConsentStamp(
                  by: actor,
                  at: ref.read(consentClockProvider).nowUtc(),
                ).toJson()
              : null,
        );
      },
    );
  }
}
