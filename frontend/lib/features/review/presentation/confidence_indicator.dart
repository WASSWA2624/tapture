import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/processing/processing.dart'
    show ConfidenceBand;

/// The confidence band as colour, icon and number together (task 016).
///
/// The number is part of the pill's label, and the pill always draws an icon,
/// so the band is never colour alone.
final class ConfidenceIndicator extends StatelessWidget {
  /// Creates the indicator for [band] and [score] (0 to 1).
  const ConfidenceIndicator({this.band, this.score, this.failure, super.key});

  /// The stored band. Null with no [score] is the empty state.
  final ConfidenceBand? band;

  /// The score, shown as a percent. Null hides the number.
  final double? score;

  /// Why the band could not be read.
  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    final ConfidenceBand? shown = band;
    if (shown == null && score == null) {
      return const AppEmptyState(
        icon: AppIcons.review,
        headline: Copy.reviewNoConfidence,
        message: Copy.reviewNoConfidenceMessage,
      );
    }
    final ConfidenceBand resolved = shown ?? ConfidenceBand.reviewRequired;
    final String number = score == null ? '' : ' ${(score! * 100).round()}%';
    final String word = switch (resolved) {
      ConfidenceBand.high => 'High',
      ConfidenceBand.medium => 'Medium',
      ConfidenceBand.reviewRequired => 'Review',
    };
    return AppStatusPill(
      key: ValueKey<String>('confidence-${resolved.name}'),
      status: switch (resolved) {
        ConfidenceBand.high => RecordStatus.approved,
        ConfidenceBand.medium => RecordStatus.queued,
        ConfidenceBand.reviewRequired => RecordStatus.needsReview,
      },
      label: '$word$number',
    );
  }
}
