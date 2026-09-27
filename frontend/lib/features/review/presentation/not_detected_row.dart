import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// A value the extractor refused to invent (task 016).
///
/// Offers typing and photographing in place. It never shows a made-up value.
final class NotDetectedRow extends StatelessWidget {
  /// Creates the row for [label]. Null [label] is the empty state.
  const NotDetectedRow({
    this.label,
    this.failure,
    this.onType,
    this.onPhotograph,
    super.key,
  });

  /// The field that was not detected.
  final String? label;

  /// Why the row could not be shown.
  final Failure? failure;

  /// Opens the field editor.
  final VoidCallback? onType;

  /// Opens the camera for the label.
  final VoidCallback? onPhotograph;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    final String? name = label;
    if (name == null || name.trim().isEmpty) {
      return const AppEmptyState(
        icon: AppIcons.review,
        headline: Copy.reviewNotDetectedEmpty,
        message: Copy.reviewNotDetectedEmpty,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('${Copy.reviewNotDetected}: $name'),
        AppButton(
          key: const ValueKey<String>('review-type-it'),
          label: Copy.reviewTypeIt,
          icon: AppIcons.edit,
          onPressed: onType,
        ),
        AppButton(
          key: const ValueKey<String>('review-photograph'),
          label: Copy.reviewPhotograph,
          icon: AppIcons.camera,
          variant: AppButtonVariant.secondary,
          onPressed: onPhotograph,
        ),
      ],
    );
  }
}
