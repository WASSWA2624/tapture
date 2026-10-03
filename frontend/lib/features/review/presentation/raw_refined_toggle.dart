import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/features/records/records.dart' show RecordValue;

/// Chooses whether the captured or the refined value is final (task 016).
///
/// One shared choice field, not a new control. Choosing changes only which
/// side is final: neither side is deleted, so choosing again reverses it.
/// The parent remembers the latest choice as the project's starting side
/// for the next field.
final class RawRefinedToggle extends StatelessWidget {
  /// Creates the toggle between [raw] and [refined], starting on [side].
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

  /// Why the choice could not be saved or read.
  final Failure? failure;

  /// Records the new side. Null leaves the choice read-only.
  final ValueChanged<ValueSide>? onChanged;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool rawEmpty = (raw ?? '').trim().isEmpty;
    final bool refinedEmpty = (refined ?? '').trim().isEmpty;
    if (rawEmpty && refinedEmpty) {
      return AppBanner(
        key: const ValueKey<String>('review-no-sides'),
        message: localCopy.reviewNoSidesMessage,
        icon: AppIcons.info,
        tone: SnackTone.info,
      );
    }
    final ValueChanged<ValueSide>? changed = onChanged;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppChoiceField<ValueSide>(
          key: const ValueKey<String>('review-side'),
          label: localCopy.reviewFinalSide,
          options: <Choice<ValueSide>>[
            if (!rawEmpty)
              Choice<ValueSide>(ValueSide.raw, localCopy.reviewUseRaw),
            if (!refinedEmpty)
              Choice<ValueSide>(ValueSide.refined, localCopy.reviewUseRefined),
          ],
          value: side,
          enabled: changed != null,
          onChanged: (ValueSide? next) {
            if (next != null && next != side) {
              changed?.call(next);
            }
          },
        ),
        if (failure case final Failure failed)
          AppBanner(
            key: const ValueKey<String>('review-side-failure'),
            message: failed.message,
            icon: AppIcons.error,
            tone: SnackTone.error,
          ),
      ],
    );
  }
}

/// Which stored side of a value is final. Both sides stay stored.
enum ValueSide {
  /// The captured value.
  raw,

  /// The refined value.
  refined;

  /// The side a stored setting names; [refined] when it names none.
  static ValueSide fromStored(String stored) {
    return stored == raw.name ? raw : refined;
  }
}

/// Whether [value] holds a captured side and a different refined side, so
/// a person can choose which is final.
bool isTwoSided(RecordValue value) {
  final String refined = value.refined ?? '';
  return value.raw.isNotEmpty && refined.isNotEmpty && refined != value.raw;
}

/// The side [value] is final on: the side its chosen final value matches,
/// else [remembered], the side the project starts two-sided values on.
ValueSide finalSideOf(RecordValue value, ValueSide remembered) {
  final String chosen = value.approved ?? '';
  if (chosen.isEmpty) {
    return remembered;
  }
  return chosen == value.raw && chosen != value.refined
      ? ValueSide.raw
      : ValueSide.refined;
}
