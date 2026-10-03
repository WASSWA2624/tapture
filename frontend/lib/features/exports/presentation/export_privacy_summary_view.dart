import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../exports.dart';

/// Names consent omissions and per-photo face counts beside the saved output.
final class ExportPrivacySummaryView extends ConsumerWidget {
  const ExportPrivacySummaryView({
    required this.exportId,
    this.package = false,
    super.key,
  });
  final String exportId;
  final bool package;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<ExportPrivacySummary?> summary = ref.watch(
      _summary((id: exportId, package: package)),
    );
    final ExportPrivacySummary? value = summary.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (value != null && value.omittedRecordIds.isNotEmpty)
          Text(localCopy.exportConsentOmitted(value.omittedRecordIds)),
        if (value != null && value.photoFaceCounts.isNotEmpty)
          Text(localCopy.exportFaceCounts(value.photoFaceCounts)),
        if (summary.hasError) Text(Failure.from(summary.error!).message),
      ],
    );
  }
}

final _summary = FutureProvider.autoDispose
    .family<ExportPrivacySummary?, ({String id, bool package})>((
      Ref ref,
      ({String id, bool package}) key,
    ) async {
      final Object? repository = key.package
          ? ref.watch(exportRepositoryProvider)
          : ref.watch(deliverableRepositoryProvider);
      if (repository case final ExportSharingPolicy policy) {
        return switch (await policy.privacySummary(key.id)) {
          Success<ExportPrivacySummary>(:final ExportPrivacySummary value) =>
            value,
          FailureResult<ExportPrivacySummary>(:final Failure failure) =>
            throw failure,
        };
      }
      return null;
    }, retry: (int _, Object _) => null);
