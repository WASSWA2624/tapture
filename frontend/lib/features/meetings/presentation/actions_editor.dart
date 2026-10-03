import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_card.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/fields/app_date_field.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

import '../domain/action_entry.dart';

/// The action register. Owner, due date and status stay editable.
final class ActionsEditor extends StatelessWidget {
  /// Creates the editor. An empty [actions] list is the empty state.
  const ActionsEditor({
    this.actions = const <ActionEntry>[],
    this.attendeeOwners = const <({String id, String name})>[],
    this.staffOwners = const <({String id, String name})>[],
    this.failure,
    this.clock = const SystemClock(),
    this.onChanged,
    this.onAdd,
    super.key,
  });

  /// Actions in list order.
  final List<ActionEntry> actions;

  /// Owners taken from the attendee list.
  final List<({String id, String name})> attendeeOwners;

  /// Owners taken from the Staff dataset.
  final List<({String id, String name})> staffOwners;

  /// Why the register could not be read.
  final Failure? failure;

  /// Clock for the due-date field.
  final Clock clock;

  /// Replaces the list after an edit or removal.
  final ValueChanged<List<ActionEntry>>? onChanged;

  /// Asks the parent for a new action.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    if (actions.isEmpty) {
      return AppEmptyState(
        icon: AppIcons.checklist,
        headline: localCopy.meetingActionsEmpty,
        message: localCopy.meetingActionsEmptyMessage,
        actionLabel: localCopy.meetingAddAction,
        onAction: onAdd,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final ActionEntry action in actions) _row(context, action),
        AppButton(
          key: const ValueKey<String>('action-add'),
          label: localCopy.meetingAddAction,
          variant: AppButtonVariant.secondary,
          onPressed: onAdd,
        ),
      ],
    );
  }

  Widget _row(BuildContext context, ActionEntry action) {
    final LocalizedCopy localCopy = Copy.of(context);

    return AppCard(
      key: ValueKey<String>('action-${action.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            key: ValueKey<String>('action-text-${action.id}'),
            label: localCopy.meetingActionText,
            controller: TextEditingController(text: action.text),
            onChanged: (String text) => _replace(action.copyWith(text: text)),
          ),
          if (action.source.isNotEmpty)
            Text(
              action.source,
              key: ValueKey<String>('action-source-${action.id}'),
            ),
          Text(
            action.ownerName,
            key: ValueKey<String>('action-owner-${action.id}'),
          ),
          for (final ({String id, String name}) owner in attendeeOwners)
            AppButton(
              key: ValueKey<String>('action-attendee-${action.id}-${owner.id}'),
              label: localCopy.meetingOwnerAttendee,
              variant: AppButtonVariant.secondary,
              onPressed: () => _replace(
                action.copyWith(ownerId: owner.id, ownerName: owner.name),
              ),
            ),
          for (final ({String id, String name}) owner in staffOwners)
            AppButton(
              key: ValueKey<String>('action-staff-${action.id}-${owner.id}'),
              label: localCopy.meetingOwnerStaff,
              variant: AppButtonVariant.secondary,
              onPressed: () => _replace(
                action.copyWith(ownerId: owner.id, ownerName: owner.name),
              ),
            ),
          AppDateField(
            key: ValueKey<String>('action-due-${action.id}'),
            label: localCopy.meetingDue,
            value: action.due,
            clock: clock,
            onChanged: (DateTime? due) => _replace(
              due == null
                  ? action.copyWith(clearDue: true)
                  : action.copyWith(due: due),
            ),
          ),
          AppButton(
            key: ValueKey<String>('action-status-${action.id}'),
            label: '${localCopy.meetingStatus} ${action.status.name}',
            variant: AppButtonVariant.secondary,
            onPressed: () =>
                _replace(action.copyWith(status: _next(action.status))),
          ),
          AppButton(
            key: ValueKey<String>('action-remove-${action.id}'),
            label: localCopy.meetingRemove,
            variant: AppButtonVariant.secondary,
            onPressed: () => unawaited(_remove(context, action.id)),
          ),
        ],
      ),
    );
  }

  void _replace(ActionEntry next) {
    onChanged?.call(<ActionEntry>[
      for (final ActionEntry action in actions)
        if (action.id == next.id) next else action,
    ]);
  }

  ActionStatus _next(ActionStatus status) {
    return switch (status) {
      ActionStatus.open => ActionStatus.inProgress,
      ActionStatus.inProgress => ActionStatus.done,
      ActionStatus.done => ActionStatus.open,
    };
  }

  Future<void> _remove(BuildContext context, String id) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.meetingRemoveTitle,
      message: localCopy.meetingRemoveMessage,
      confirmLabel: localCopy.meetingRemoveConfirm,
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    onChanged?.call(<ActionEntry>[
      for (final ActionEntry action in actions)
        if (action.id != id) action,
    ]);
  }
}
