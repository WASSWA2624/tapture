import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_card.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/agenda_entry.dart';
import 'meeting_row_menu.dart';
import 'meeting_text_field.dart';

/// Agenda points in the order they are discussed and exported. A point is
/// reordered by its drag handle, or by Move up and Move down in its menu.
final class AgendaEditor extends StatelessWidget {
  /// Creates the editor. An empty [entries] list is the empty state.
  const AgendaEditor({
    required this.entries,
    required this.onChanged,
    required this.onAdd,
    this.failure,
    super.key,
  });

  /// Discussion sections, first to last.
  final List<AgendaEntry> entries;

  /// Replaces the list after an edit, a move or a removal.
  final ValueChanged<List<AgendaEntry>> onChanged;

  /// Adds a new, empty point.
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
        if (entries.isEmpty)
          AppEmptyState(
            icon: AppIcons.fields,
            headline: localCopy.meetingAgendaEmpty,
            message: localCopy.meetingAgendaEmptyMessage,
            actionLabel: localCopy.meetingAddAgenda,
            onAction: onAdd,
          )
        else ...<Widget>[
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: _move,
            children: <Widget>[
              for (int index = 0; index < entries.length; index++)
                _row(context, entries[index], index),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton(
              key: const ValueKey<String>('agenda-add'),
              label: localCopy.meetingAddAgenda,
              icon: AppIcons.add,
              variant: AppButtonVariant.secondary,
              onPressed: onAdd,
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, AgendaEntry entry, int index) {
    return Padding(
      key: ValueKey<String>('agenda-${entry.id}'),
      padding: const EdgeInsets.only(bottom: Space.x3),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ReorderableDragStartListener(
              index: index,
              child: SizedBox.square(
                dimension: Sizes.minTapTarget,
                child: Icon(
                  AppIcons.reorder,
                  semanticLabel: Copy.of(context).meetingDrag(entry.title),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  MeetingTextField(
                    key: ValueKey<String>('agenda-title-${entry.id}'),
                    label: Copy.of(context).meetingAgendaTitle,
                    value: entry.title,
                    onChanged: (String text) =>
                        _replace(entry.copyWith(title: text)),
                  ),
                  const SizedBox(height: Space.x2),
                  MeetingTextField(
                    key: ValueKey<String>('agenda-notes-${entry.id}'),
                    label: Copy.of(context).meetingDiscussion,
                    value: entry.notes,
                    maxLines: null,
                    minLines: 2,
                    onChanged: (String text) =>
                        _replace(entry.copyWith(notes: text)),
                  ),
                ],
              ),
            ),
            MeetingRowMenu(
              key: ValueKey<String>('agenda-menu-${entry.id}'),
              onMoveUp: index == 0 ? null : () => _move(index, index - 1),
              onMoveDown: index == entries.length - 1
                  ? null
                  : () => _move(index, index + 1),
              onRemove: () => onChanged(<AgendaEntry>[
                for (final AgendaEntry other in entries)
                  if (other.id != entry.id) other,
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _replace(AgendaEntry next) {
    onChanged(<AgendaEntry>[
      for (final AgendaEntry entry in entries)
        if (entry.id == next.id) next else entry,
    ]);
  }

  /// Moves the point at [from] to [to], counted after it is lifted out.
  void _move(int from, int to) {
    final List<AgendaEntry> next = List<AgendaEntry>.of(entries);
    final AgendaEntry moved = next.removeAt(from);
    next.insert(to.clamp(0, next.length), moved);
    onChanged(next);
  }
}
