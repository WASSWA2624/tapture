import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// Records that a person confirmed a value, without changing it (task 016).
final class VerifyAction extends StatelessWidget {
  /// Creates the action.
  const VerifyAction({
    this.fieldLabel,
    this.verifier,
    this.confidentCount = 0,
    this.failure,
    this.onVerify,
    this.onVerifyConfident,
    super.key,
  });

  /// The field a single verify applies to. Null when there is no field.
  final String? fieldLabel;

  /// Who verified it, once they have.
  final String? verifier;

  /// How many confident fields a bulk verify would cover.
  final int confidentCount;

  /// Why verification could not be recorded.
  final Failure? failure;

  /// Verifies the one field.
  final VoidCallback? onVerify;

  /// Verifies every confident field.
  final VoidCallback? onVerifyConfident;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    final String? field = fieldLabel;
    if ((field == null || field.trim().isEmpty) && confidentCount == 0) {
      return const AppEmptyState(
        icon: AppIcons.verified,
        headline: Copy.reviewVerifyEmpty,
        message: Copy.reviewVerifyEmpty,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (verifier != null && verifier!.trim().isNotEmpty)
          Text(
            Copy.reviewVerifiedBy(verifier!),
            key: const ValueKey<String>('review-verifier'),
          ),
        if (field != null && field.trim().isNotEmpty)
          AppButton(
            key: const ValueKey<String>('review-verify'),
            label: Copy.reviewVerify,
            icon: AppIcons.verified,
            onPressed: onVerify,
          ),
        if (confidentCount > 0)
          AppButton(
            key: const ValueKey<String>('review-verify-confident'),
            label: Copy.reviewVerifyConfident,
            variant: AppButtonVariant.secondary,
            onPressed: onVerifyConfident,
          ),
      ],
    );
  }
}
