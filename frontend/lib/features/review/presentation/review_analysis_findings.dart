import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/features/processing/processing.dart'
    show processingFindingsProvider;

/// Shows persisted missing, conflicting and uncertain grouping findings.
class ReviewAnalysisFindings extends ConsumerWidget {
  /// Findings belong to the same local record being reviewed.
  const ReviewAnalysisFindings({required this.recordId, super.key});

  /// Durable record identity.
  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      AsyncValueView<List<String>>(
        value: ref.watch(processingFindingsProvider(recordId)),
        loadingCount: 1,
        isEmpty: (List<String> findings) => findings.isEmpty,
        empty: () => const SizedBox.shrink(),
        onRetry: () => ref.invalidate(processingFindingsProvider(recordId)),
        data: (List<String> findings) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppSectionHeader(title: Copy.of(context).processingFindingsTitle),
            for (final String finding in findings)
              AppListTile(leading: const Icon(AppIcons.review), title: finding),
          ],
        ),
      );
}
