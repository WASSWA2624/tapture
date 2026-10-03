import 'package:flutter/widgets.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

/// Records that a person confirmed a value without changing it (task 016).
///
/// Verifying is separate from editing: the value stays exactly as it is and
/// processing never overwrites it afterwards. Once verified, the row shows
/// who confirmed it. With [confidentCount] it verifies every confident
/// field of the record at once.
final class VerifyAction extends StatelessWidget {
  /// Creates the action for the field named [fieldLabel], or for the
  /// [confidentCount] confident fields.
  const VerifyAction({
    this.fieldLabel,
    this.verified = false,
    this.verifier,
    this.confidentCount = 0,
    this.failure,
    this.onVerify,
    this.onVerifyConfident,
    super.key,
  });

  /// The field a single verify applies to. Null when there is no field.
  final String? fieldLabel;

  /// Whether the field is verified already.
  final bool verified;

  /// Who verified it, once they have. Blank when no operator was known.
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
    final LocalizedCopy localCopy = Copy.of(context);

    final Failure? failed = failure;
    if (failed != null) {
      return AppBanner(
        key: const ValueKey<String>('review-verify-failure'),
        message: failed.message,
        icon: AppIcons.error,
        tone: SnackTone.error,
      );
    }
    final String field = (fieldLabel ?? '').trim();
    if (field.isEmpty && confidentCount == 0) {
      return AppBanner(
        key: const ValueKey<String>('review-verify-empty'),
        message: localCopy.reviewVerifyEmpty,
        icon: AppIcons.verified,
        tone: SnackTone.info,
      );
    }
    final String name = (verifier ?? '').trim();
    return Wrap(
      spacing: Space.x2,
      runSpacing: Space.x2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        if (field.isNotEmpty && verified)
          AppStatusPill.badge(
            key: const ValueKey<String>('review-verifier'),
            status: RecordStatus.approved,
            label: name.isEmpty
                ? localCopy.reviewVerified
                : localCopy.reviewVerifiedBy(name),
          ),
        if (field.isNotEmpty && !verified)
          AppButton(
            key: const ValueKey<String>('review-verify'),
            label: localCopy.reviewVerify,
            icon: AppIcons.verified,
            variant: AppButtonVariant.secondary,
            onPressed: onVerify,
          ),
        if (confidentCount > 0)
          AppButton(
            key: const ValueKey<String>('review-verify-confident'),
            label: localCopy.reviewVerifyConfident,
            icon: AppIcons.verified,
            variant: AppButtonVariant.secondary,
            onPressed: onVerifyConfident,
          ),
      ],
    );
  }
}
