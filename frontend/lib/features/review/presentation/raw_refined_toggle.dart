import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// Which stored side is authoritative. Both sides stay stored.
enum ValueSide {
  /// The captured value.
  raw,

  /// The refined value.
  refined,
}

/// Chooses whether the raw or the refined value is final (task 016).
///
/// Neither side is deleted. The latest choice is the project's default for
/// the next field.
final class RawRefinedToggle extends StatelessWidget {
  /// Creates the toggle.
  const RawRefinedToggle({
    required this.side,
    this.raw,
    this.refined,
    this.failure,
    this.onChanged,
    super.key,
  });

  /// The side that is final now.
  final ValueSide side;

  /// The captured value. Null when there is none.
  final String? raw;

  /// The refined value. Null when there is none.
  final String? refined;

  /// Why the sides could not be read.
  final Failure? failure;

  /// Records the new side. The parent remembers it for later fields.
  final ValueChanged<ValueSide>? onChanged;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    final bool rawEmpty = raw == null || raw!.trim().isEmpty;
    final bool refinedEmpty = refined == null || refined!.trim().isEmpty;
    if (rawEmpty && refinedEmpty) {
      return const AppEmptyState(
        icon: AppIcons.edit,
        headline: Copy.reviewNoSidesHeadline,
        message: Copy.reviewNoSidesMessage,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppButton(
          key: const ValueKey<String>('review-use-raw'),
          label: Copy.reviewUseRaw,
          variant: side == ValueSide.raw
              ? AppButtonVariant.primary
              : AppButtonVariant.secondary,
          onPressed: rawEmpty ? null : () => onChanged?.call(ValueSide.raw),
        ),
        AppButton(
          key: const ValueKey<String>('review-use-refined'),
          label: Copy.reviewUseRefined,
          variant: side == ValueSide.refined
              ? AppButtonVariant.primary
              : AppButtonVariant.secondary,
          onPressed: refinedEmpty
              ? null
              : () => onChanged?.call(ValueSide.refined),
        ),
        Text(side == ValueSide.raw ? (raw ?? '') : (refined ?? '')),
      ],
    );
  }
}
