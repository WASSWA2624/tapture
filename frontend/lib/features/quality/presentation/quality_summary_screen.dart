import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// The counts that still block a clean export (task 015).
typedef QualityCounts = ({
  int invalid,
  int duplicates,
  int conflicts,
  int unreviewed,
});

/// What still blocks a clean export, each count opening the screen that
/// clears it.
final class QualitySummaryScreen extends StatelessWidget {
  /// Creates the summary.
  const QualitySummaryScreen({
    required this.counts,
    this.failure,
    this.onInvalid,
    this.onDuplicates,
    this.onConflicts,
    this.onUnreviewed,
    this.onRetry,
    super.key,
  });

  /// The four counts. A clean project is all zeros.
  final QualityCounts? counts;

  /// Why the counts could not be read.
  final Failure? failure;

  /// Opens the records that fail validation.
  final VoidCallback? onInvalid;

  /// Opens the duplicates screen.
  final VoidCallback? onDuplicates;

  /// Opens the variance screen, where conflicts are cleared.
  final VoidCallback? onConflicts;

  /// Opens the review queue.
  final VoidCallback? onUnreviewed;

  /// Reads the counts again.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    final QualityCounts? loaded = counts;
    final bool clean =
        loaded != null &&
        loaded.invalid == 0 &&
        loaded.duplicates == 0 &&
        loaded.conflicts == 0 &&
        loaded.unreviewed == 0;
    return AppPage(
      key: const ValueKey<String>('route-quality'),
      title: Copy.qualitySummaryTitle,
      body: failed != null
          ? AppErrorState(failure: failed, onRetry: onRetry)
          : loaded == null
          ? const SizedBox.shrink()
          : clean
          ? const AppEmptyState(
              icon: AppIcons.verified,
              headline: Copy.qualityCleanHeadline,
              message: Copy.qualityCleanMessage,
            )
          : Column(
              children: <Widget>[
                _Count(
                  keyName: 'quality-invalid',
                  title: Copy.qualityInvalid,
                  count: loaded.invalid,
                  onTap: onInvalid,
                ),
                _Count(
                  keyName: 'quality-duplicates',
                  title: Copy.qualityDuplicates,
                  count: loaded.duplicates,
                  onTap: onDuplicates,
                ),
                _Count(
                  keyName: 'quality-conflicts',
                  title: Copy.qualityConflicts,
                  count: loaded.conflicts,
                  onTap: onConflicts,
                ),
                _Count(
                  keyName: 'quality-unreviewed',
                  title: Copy.qualityUnreviewed,
                  count: loaded.unreviewed,
                  onTap: onUnreviewed,
                ),
              ],
            ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({
    required this.keyName,
    required this.title,
    required this.count,
    required this.onTap,
  });

  final String keyName;
  final String title;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const SizedBox.shrink();
    }
    return AppListTile(
      key: ValueKey<String>(keyName),
      title: title,
      subtitle: '$count',
      onTap: onTap,
    );
  }
}
