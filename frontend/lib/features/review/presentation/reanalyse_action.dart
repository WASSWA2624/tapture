import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// One proposed replacement. Verified and typed values are offered only.
typedef ReanalyseProposal = ({
  String fieldKey,
  String label,
  String current,
  String proposed,
  bool offeredOnly,
});

/// The values a person accepted. Declined keys are absent.
///
/// A key that is only offered is included only when [acceptedKeys] names it.
Map<String, String> acceptedProposals({
  required List<ReanalyseProposal> proposals,
  required Set<String> acceptedKeys,
}) {
  return <String, String>{
    for (final ReanalyseProposal proposal in proposals)
      if (acceptedKeys.contains(proposal.fieldKey))
        proposal.fieldKey: proposal.proposed,
  };
}

final _reanalyseSelectionProvider =
    NotifierProvider.autoDispose<_ReanalyseSelection, Set<String>>(
      _ReanalyseSelection.new,
    );

class _ReanalyseSelection extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void toggle(String fieldKey) {
    final Set<String> next = Set<String>.of(state);
    if (!next.add(fieldKey)) {
      next.remove(fieldKey);
    }
    state = next;
  }

  void clear() {
    state = <String>{};
  }
}

/// Shows each new value beside the current one (task 016).
///
/// A verified or manually typed field stays offered until a person accepts
/// it. Decline leaves the record unchanged.
final class ReanalyseAction extends ConsumerWidget {
  /// Creates the diff.
  const ReanalyseAction({
    required this.proposals,
    this.failure,
    this.onApply,
    this.onDeclineAll,
    super.key,
  });

  /// Proposals. Empty is the empty state.
  final List<ReanalyseProposal> proposals;

  /// Why re-analysis could not run.
  final Failure? failure;

  /// Writes only the accepted proposals.
  final ValueChanged<Map<String, String>>? onApply;

  /// Leaves the record unchanged.
  final VoidCallback? onDeclineAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    if (proposals.isEmpty) {
      return const AppEmptyState(
        icon: AppIcons.processing,
        headline: Copy.reviewReanalyseEmpty,
        message: Copy.reviewReanalyseEmpty,
      );
    }
    final Set<String> accepted = ref.watch(_reanalyseSelectionProvider);
    final _ReanalyseSelection selection = ref.read(
      _reanalyseSelectionProvider.notifier,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final ReanalyseProposal proposal in proposals)
          AppListTile(
            key: ValueKey<String>('proposal-${proposal.fieldKey}'),
            title: proposal.label,
            subtitle: proposal.offeredOnly
                ? '${proposal.current} · ${proposal.proposed} · ${Copy.reviewOfferedNotApplied}'
                : '${proposal.current} · ${proposal.proposed}',
            selected: accepted.contains(proposal.fieldKey),
            onTap: () => selection.toggle(proposal.fieldKey),
          ),
        AppButton(
          key: const ValueKey<String>('reanalyse-apply'),
          label: Copy.reviewApplyAccepted,
          onPressed: () => onApply?.call(
            acceptedProposals(proposals: proposals, acceptedKeys: accepted),
          ),
        ),
        AppButton(
          key: const ValueKey<String>('reanalyse-decline'),
          label: Copy.reviewDeclineAll,
          variant: AppButtonVariant.secondary,
          onPressed: () {
            selection.clear();
            onDeclineAll?.call();
          },
        ),
      ],
    );
  }
}
