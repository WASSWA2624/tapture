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

import '../domain/agenda_entry.dart';

/// Agenda entries in the order they will be discussed and exported.
final class AgendaEditor extends StatelessWidget {
  /// Creates the editor. An empty [entries] list is the empty state.
  const AgendaEditor({
    this.entries = const <AgendaEntry>[],
    this.failure,
    this.onChanged,
    this.onAdd,
    super.key,
  });

  /// Discussion sections, first to last.
  final List<AgendaEntry> entries;

  /// Why the agenda could not be read.
  final Failure? failure;

  /// Replaces the list after an edit, move or removal.
  final ValueChanged<List<AgendaEntry>>? onChanged;

  /// Asks the parent for a new entry.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    if (entries.isEmpty) {
      return AppEmptyState(
        icon: AppIcons.fields,
        headline: Copy.meetingAgendaEmpty,
        message: Copy.meetingAgendaEmptyMessage,
        actionLabel: Copy.meetingAddAgenda,
        onAction: onAdd,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorderItem: _move,
          children: <Widget>[
            for (var index = 0; index < entries.length; index++)
              _row(context, entries[index], index),
          ],
        ),
        AppButton(
          key: const ValueKey<String>('agenda-add'),
          label: Copy.meetingAddAgenda,
          variant: AppButtonVariant.secondary,
          onPressed: onAdd,
        ),
      ],
    );
  }

  Widget _row(BuildContext context, AgendaEntry entry, int index) {
    return AppCard(
      key: ValueKey<String>('agenda-${entry.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            key: ValueKey<String>('agenda-title-${entry.id}'),
            label: Copy.meetingAgendaTitle,
            controller: TextEditingController(text: entry.title),
            onChanged: (String text) => _replace(entry.copyWith(title: text)),
          ),
          AppTextField(
            key: ValueKey<String>('agenda-notes-${entry.id}'),
            label: Copy.meetingDiscussion,
            controller: TextEditingController(text: entry.notes),
            onChanged: (String text) => _replace(entry.copyWith(notes: text)),
          ),
          AppButton(
            key: ValueKey<String>('agenda-down-${entry.id}'),
            label: Copy.meetingMoveDown,
            variant: AppButtonVariant.secondary,
            onPressed: index == entries.length - 1
                ? null
                : () => _move(index, index + 1),
          ),
          AppButton(
            key: ValueKey<String>('agenda-remove-${entry.id}'),
            label: Copy.meetingRemove,
            variant: AppButtonVariant.secondary,
            onPressed: () => unawaited(_remove(context, entry.id)),
          ),
        ],
      ),
    );
  }

  void _replace(AgendaEntry next) {
    onChanged?.call(<AgendaEntry>[
      for (final AgendaEntry entry in entries)
        if (entry.id == next.id) next else entry,
    ]);
  }

  void _move(int from, int to) {
    final List<AgendaEntry> next = List<AgendaEntry>.of(entries);
    final AgendaEntry moved = next.removeAt(from);
    next.insert(to, moved);
    onChanged?.call(next);
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
    onChanged?.call(<AgendaEntry>[
      for (final AgendaEntry entry in entries)
        if (entry.id != id) entry,
    ]);
  }
}
