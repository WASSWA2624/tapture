import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';

/// What re-analysis offers a record, field by field, beside what each field
/// holds now (task 016 step 6).
///
/// Each proposal is one row a person ticks to accept. A verified or
/// hand-typed value is marked as offered, not applied: nothing replaces it
/// unless ticked. Apply writes exactly the ticked proposals; Decline all
/// leaves the record exactly as it was.
final class ReanalyseAction extends StatelessWidget {
  /// Creates the diff of [proposals], with [accepted] ticked.
  const ReanalyseAction({
    required this.proposals,
    this.accepted = const <String>{},
    this.failure,
    this.busy = false,
    this.onToggle,
    this.onApply,
    this.onDeclineAll,
    super.key,
  });

  /// The proposals. Empty means re-analysis found nothing new.
  final List<ReanalyseProposal> proposals;

  /// Field keys ticked for acceptance.
  final Set<String> accepted;

  /// Why re-analysis could not run or be read.
  final Failure? failure;

  /// Whether the accepted proposals are being written.
  final bool busy;

  /// Ticks or unticks the proposal for a field key.
  final ValueChanged<String>? onToggle;

  /// Writes only the accepted proposals, by field key.
  final ValueChanged<Map<String, String>>? onApply;

  /// Leaves the record unchanged and closes the diff.
  final VoidCallback? onDeclineAll;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Failure? failed = failure;
    if (failed != null) {
      return AppBanner(
        key: const ValueKey<String>('reanalyse-failure'),
        message: failed.message,
        icon: AppIcons.error,
        tone: SnackTone.error,
        onDismiss: onDeclineAll,
      );
    }
    if (proposals.isEmpty) {
      return AppBanner(
        key: const ValueKey<String>('reanalyse-empty'),
        message: localCopy.reviewReanalyseEmpty,
        icon: AppIcons.processing,
        tone: SnackTone.info,
        onDismiss: onDeclineAll,
      );
    }
    final ValueChanged<String>? toggle = busy ? null : onToggle;
    return Column(
      key: const ValueKey<String>('reanalyse-diff'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(title: localCopy.reviewProposalsTitle),
        for (final ReanalyseProposal proposal in proposals)
          AppListTile(
            key: ValueKey<String>('proposal-${proposal.fieldKey}'),
            title: proposal.label,
            subtitle: localCopy.reviewProposalLine(
              proposal.current,
              proposal.proposed,
            ),
            dense: true,
            selected: accepted.contains(proposal.fieldKey),
            status: proposal.offeredOnly
                ? AppStatusPill.badge(
                    status: RecordStatus.needsReview,
                    label: localCopy.reviewOfferedNotApplied,
                  )
                : null,
            onTap: toggle == null ? null : () => toggle(proposal.fieldKey),
          ),
        ResponsivePair(
          start: AppButton(
            key: const ValueKey<String>('reanalyse-decline'),
            label: localCopy.reviewDeclineAll,
            variant: AppButtonVariant.text,
            expand: true,
            onPressed: busy ? null : onDeclineAll,
          ),
          end: AppButton(
            key: const ValueKey<String>('reanalyse-apply'),
            label: localCopy.reviewApplyAccepted,
            variant: AppButtonVariant.secondary,
            expand: true,
            busy: busy,
            onPressed: accepted.isEmpty
                ? null
                : () => onApply?.call(
                    acceptedProposals(
                      proposals: proposals,
                      acceptedKeys: accepted,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// One proposed replacement: the field, its label, what it shows now, what
/// re-analysis proposes, and whether the current value was verified or
/// typed by a person, so the proposal is offered only.
typedef ReanalyseProposal = ({
  String fieldKey,
  String label,
  String current,
  String proposed,
  bool offeredOnly,
});

/// The proposals a person accepted, by field key. Declined ones are absent,
/// whether offered only or not.
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
