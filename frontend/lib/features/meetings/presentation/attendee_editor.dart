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

import '../domain/attendee.dart';

/// Names, roles and apologies. An apology is never counted as present.
final class AttendeeEditor extends StatelessWidget {
  /// Creates the editor. An empty [people] list is the empty state.
  const AttendeeEditor({
    this.people = const <Attendee>[],
    this.failure,
    this.onChanged,
    this.onAdd,
    super.key,
  });

  /// Present people and apologies.
  final List<Attendee> people;

  /// Why the list could not be read.
  final Failure? failure;

  /// Replaces the list after an edit or removal.
  final ValueChanged<List<Attendee>>? onChanged;

  /// Asks the parent for a new person.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    if (people.isEmpty) {
      return AppEmptyState(
        icon: AppIcons.identity,
        headline: Copy.meetingAttendeesEmpty,
        message: Copy.meetingAttendeesEmptyMessage,
        actionLabel: Copy.meetingAddAttendee,
        onAction: onAdd,
      );
    }
    final int present = people
        .where((Attendee person) => person.countsAsAttendance)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          Copy.meetingAttendanceCount(present),
          key: const ValueKey<String>('attendee-count'),
        ),
        for (final Attendee person in people) _row(context, person),
        AppButton(
          key: const ValueKey<String>('attendee-add'),
          label: Copy.meetingAddAttendee,
          variant: AppButtonVariant.secondary,
          onPressed: onAdd,
        ),
      ],
    );
  }

  Widget _row(BuildContext context, Attendee person) {
    final bool linked = person.staffId != null;
    final bool offered =
        !linked && (person.suggestedStaffId?.isNotEmpty ?? false);
    return AppCard(
      key: ValueKey<String>('attendee-${person.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            key: ValueKey<String>('attendee-name-${person.id}'),
            label: Copy.meetingAttendeeName,
            controller: TextEditingController(text: person.name),
            onChanged: (String text) => _replace(person.copyWith(name: text)),
          ),
          AppTextField(
            label: Copy.meetingAttendeeRole,
            controller: TextEditingController(text: person.title),
            onChanged: (String text) => _replace(person.copyWith(title: text)),
          ),
          AppTextField(
            label: Copy.meetingOrganisation,
            controller: TextEditingController(text: person.organisation),
            onChanged: (String text) =>
                _replace(person.copyWith(organisation: text)),
          ),
          AppTextField(
            label: Copy.meetingContact,
            controller: TextEditingController(text: person.contact),
            onChanged: (String text) =>
                _replace(person.copyWith(contact: text)),
          ),
          AppButton(
            key: ValueKey<String>('attendee-present-${person.id}'),
            label: Copy.meetingPresent,
            variant: person.status == AttendanceStatus.present
                ? AppButtonVariant.primary
                : AppButtonVariant.secondary,
            onPressed: () =>
                _replace(person.copyWith(status: AttendanceStatus.present)),
          ),
          AppButton(
            key: ValueKey<String>('attendee-apology-${person.id}'),
            label: Copy.meetingApology,
            variant: person.status == AttendanceStatus.apology
                ? AppButtonVariant.primary
                : AppButtonVariant.secondary,
            onPressed: () =>
                _replace(person.copyWith(status: AttendanceStatus.apology)),
          ),
          if (offered)
            AppButton(
              key: ValueKey<String>('attendee-link-${person.id}'),
              label: Copy.meetingAcceptStaff,
              onPressed: () => _replace(
                person.copyWith(
                  staffId: person.suggestedStaffId,
                  clearSuggestion: true,
                ),
              ),
            ),
          if (linked)
            Text(
              person.staffId!,
              key: ValueKey<String>('attendee-staff-${person.id}'),
            ),
          AppButton(
            label: Copy.meetingRemove,
            variant: AppButtonVariant.secondary,
            onPressed: () => unawaited(_remove(context, person.id)),
          ),
        ],
      ),
    );
  }

  void _replace(Attendee next) {
    onChanged?.call(<Attendee>[
      for (final Attendee person in people)
        if (person.id == next.id) next else person,
    ]);
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
    onChanged?.call(<Attendee>[
      for (final Attendee person in people)
        if (person.id != id) person,
    ]);
  }
}
