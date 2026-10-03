import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_card.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/decision.dart';
import 'meeting_row_menu.dart';
import 'meeting_text_field.dart';

/// The decisions register, whether refined or typed. Editing or removing a
/// decision leaves the notes and transcript it came from as they were.
final class DecisionsEditor extends StatelessWidget {
  /// Creates the editor. An empty [decisions] list is the empty state.
  const DecisionsEditor({
    required this.decisions,
    required this.onChanged,
    required this.onAdd,
    this.failure,
    super.key,
  });

  /// Decisions in list order.
  final List<Decision> decisions;

  /// Replaces the list after an edit or a removal.
  final ValueChanged<List<Decision>> onChanged;

  /// Adds a new, empty decision.
  final VoidCallback onAdd;

  /// Why the last change was not saved. The list stays editable.
  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Failure? failed = failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (failed != null)
          AppBanner(
            message: failed.message,
            icon: AppIcons.error,
            tone: SnackTone.error,
          ),
        if (decisions.isEmpty)
          AppEmptyState(
            icon: AppIcons.checklist,
            headline: localCopy.meetingDecisionsEmpty,
            message: localCopy.meetingDecisionsEmptyMessage,
            actionLabel: localCopy.meetingAddDecision,
            onAction: onAdd,
          )
        else ...<Widget>[
          for (final Decision decision in decisions) _row(context, decision),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton(
              key: const ValueKey<String>('decision-add'),
              label: localCopy.meetingAddDecision,
              icon: AppIcons.add,
              variant: AppButtonVariant.secondary,
              onPressed: onAdd,
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, Decision decision) {
    return Padding(
      key: ValueKey<String>('decision-${decision.id}'),
      padding: const EdgeInsets.only(bottom: Space.x3),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  MeetingTextField(
                    key: ValueKey<String>('decision-text-${decision.id}'),
                    label: Copy.of(context).meetingDecisionText,
                    value: decision.text,
                    maxLines: null,
                    onChanged: (String text) =>
                        _replace(decision.copyWith(text: text)),
                  ),
                  if (decision.source.isNotEmpty) ...<Widget>[
                    const SizedBox(height: Space.x2),
                    Text(
                      Copy.of(context).meetingSourceLine(decision.source),
                      key: ValueKey<String>('decision-source-${decision.id}'),
                      style: AppText.caption,
                    ),
                  ],
                ],
              ),
            ),
            MeetingRowMenu(
              key: ValueKey<String>('decision-menu-${decision.id}'),
              onRemove: () => onChanged(<Decision>[
                for (final Decision other in decisions)
                  if (other.id != decision.id) other,
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _replace(Decision next) {
    onChanged(<Decision>[
      for (final Decision decision in decisions)
        if (decision.id == next.id) next else decision,
    ]);
  }
}
