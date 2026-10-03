import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';

/// The next step for a value the extractor refused to invent (task 016).
///
/// Sits under the field's row, whose line already reads Not detected, and
/// offers typing the value and photographing the label in place. It never
/// shows a made-up value.
final class NotDetectedRow extends StatelessWidget {
  /// Creates the row for the field named [label]. A null or blank [label]
  /// means nothing is missing.
  const NotDetectedRow({
    this.label,
    this.failure,
    this.onType,
    this.onPhotograph,
    super.key,
  });

  /// The field that was not detected.
  final String? label;

  /// Why the field could not be read.
  final Failure? failure;

  /// Opens the shared value editor for the field.
  final VoidCallback? onType;

  /// Opens the camera on the record, to photograph the label.
  final VoidCallback? onPhotograph;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Failure? failed = failure;
    if (failed != null) {
      return AppBanner(
        key: const ValueKey<String>('review-not-detected-failure'),
        message: failed.message,
        icon: AppIcons.error,
        tone: SnackTone.error,
      );
    }
    final String name = (label ?? '').trim();
    if (name.isEmpty) {
      return AppBanner(
        key: const ValueKey<String>('review-not-detected-empty'),
        message: localCopy.reviewNotDetectedEmpty,
        icon: AppIcons.info,
        tone: SnackTone.info,
      );
    }
    return ResponsivePair(
      start: AppButton(
        key: const ValueKey<String>('review-type-it'),
        label: localCopy.reviewTypeIt,
        icon: AppIcons.edit,
        variant: AppButtonVariant.secondary,
        expand: true,
        onPressed: onType,
      ),
      end: AppButton(
        key: const ValueKey<String>('review-photograph'),
        label: localCopy.reviewPhotograph,
        icon: AppIcons.addPhoto,
        variant: AppButtonVariant.secondary,
        expand: true,
        onPressed: onPhotograph,
      ),
    );
  }
}
