import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';

import '../domain/confidence.dart';

/// A value's confidence band as colour, icon and number together, on the
/// shared status pill (tasks 013 and 016).
///
/// The band's tone and words come from [ConfidenceBand] itself, so the
/// record page, the review screen and every other reader draw one band one
/// way. The pill always draws an icon beside its words, so a band is never
/// told by colour alone (FE-A11Y-05). A score with no stored band shows as
/// its percentage in the neutral extracted tone.
final class ConfidenceIndicator extends StatelessWidget {
  /// Creates the indicator for [band] and [score] (0 to 1). [compact] draws
  /// the badge that fits a list row.
  const ConfidenceIndicator({
    this.band,
    this.score,
    this.failure,
    this.compact = false,
    super.key,
  });

  /// The stored band, or null when none was written.
  final ConfidenceBand? band;

  /// The score behind the band, 0 to 1, shown as a percentage. Null hides
  /// the number.
  final double? score;

  /// Why the band could not be read.
  final Failure? failure;

  /// Whether to draw the compact row badge.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (RecordStatus tone, String label) = _look(context);
    return compact
        ? AppStatusPill.badge(
            key: ValueKey<String>('confidence-${tone.name}'),
            status: tone,
            label: label,
          )
        : AppStatusPill(
            key: ValueKey<String>('confidence-${tone.name}'),
            status: tone,
            label: label,
          );
  }

  (RecordStatus, String) _look(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return (RecordStatus.failed, failed.message);
    }
    final ConfidenceBand? shown = band;
    final double? number = score;
    if (shown == null) {
      return number == null
          ? (RecordStatus.draft, Copy.of(context).reviewNoConfidence)
          : (RecordStatus.extracted, Copy.of(context).recordBandScore(number));
    }
    return (
      shown.tone,
      number == null
          ? shown.label
          : Copy.of(context).recordBandWithScore(shown.label, number),
    );
  }
}
