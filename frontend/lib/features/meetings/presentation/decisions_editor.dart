import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_card.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

import '../domain/decision.dart';

/// Decisions, whether refined or typed. Removing one leaves the raw material.
final class DecisionsEditor extends StatelessWidget {
  /// Creates the editor. An empty [decisions] list is the empty state.
  const DecisionsEditor({
    this.decisions = const <Decision>[],
    this.failure,
    this.onChanged,
    this.onAdd,
    super.key,
  });

  /// Decisions in list order.
  final List<Decision> decisions;

  /// Why the register could not be read.
  final Failure? failure;

  /// Replaces the list after an edit or removal.
  final ValueChanged<List<Decision>>? onChanged;

  /// Asks the parent for a new decision.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    if (decisions.isEmpty) {
      return AppEmptyState(
        icon: AppIcons.checklist,
        headline: Copy.meetingDecisionsEmpty,
        message: Copy.meetingDecisionsEmptyMessage,
        actionLabel: Copy.meetingAddDecision,
        onAction: onAdd,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final Decision decision in decisions) _row(context, decision),
        AppButton(
          key: const ValueKey<String>('decision-add'),
          label: Copy.meetingAddDecision,
          variant: AppButtonVariant.secondary,
          onPressed: onAdd,
        ),
      ],
    );
  }

  Widget _row(BuildContext context, Decision decision) {
    return AppCard(
      key: ValueKey<String>('decision-${decision.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            key: ValueKey<String>('decision-text-${decision.id}'),
            label: Copy.meetingDecisionText,
            controller: TextEditingController(text: decision.text),
            onChanged: (String text) =>
                onChanged?.call(_replaced(decision.copyWith(text: text))),
          ),
          if (decision.source.isNotEmpty)
            Text(
              decision.source,
              key: ValueKey<String>('decision-source-${decision.id}'),
            ),
          AppButton(
            key: ValueKey<String>('decision-remove-${decision.id}'),
            label: Copy.meetingRemove,
            variant: AppButtonVariant.secondary,
            onPressed: () => unawaited(_remove(context, decision.id)),
          ),
        ],
      ),
    );
  }

  List<Decision> _replaced(Decision next) {
    return <Decision>[
      for (final Decision decision in decisions)
        if (decision.id == next.id) next else decision,
    ];
  }

  Future<void> _remove(BuildContext context, String id) async {
    final bool confirmed = await showAppConfirm(
      context,
      title: Copy.meetingRemoveTitle,
      message: Copy.meetingRemoveMessage,
      confirmLabel: Copy.meetingRemoveConfirm,
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    onChanged?.call(<Decision>[
      for (final Decision decision in decisions)
        if (decision.id != id) decision,
    ]);
  }
}
