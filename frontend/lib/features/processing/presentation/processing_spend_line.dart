import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/async_value_view.dart';

import 'processing_findings_providers.dart';

/// Optional attributed spending metadata alongside the queue's request counts.
class ProcessingSpendLine extends ConsumerWidget {
  /// Project scope matches the queue that contains this line.
  const ProcessingSpendLine({this.projectId, super.key});

  /// Null shows today's totals for all local projects.
  final String? projectId;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) => AsyncValueView<({Map<String, double> reservedCosts, int? totalTokens})>(
    value: ref.watch(queueSpendProvider(projectId)),
    loadingCount: 1,
    isEmpty: (spend) =>
        spend.reservedCosts.isEmpty && spend.totalTokens == null,
    empty: () => const SizedBox.shrink(),
    onRetry: () => ref.invalidate(queueSpendProvider(projectId)),
    data: (spend) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final MapEntry<String, double> cost in spend.reservedCosts.entries)
          Text(
            Copy.of(context).processingReservedCost(
              (NumberFormat.decimalPattern(
                    Localizations.localeOf(context).toLanguageTag(),
                  )..maximumFractionDigits = AppConstants.aiCostFractionDigits)
                  .format(cost.value),
              cost.key,
            ),
          ),
        if (spend.totalTokens case final int count)
          Text(Copy.of(context).processingTokens(count)),
      ],
    ),
  );
}
