import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/responsive/content_constraint.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/templates/templates.dart'
    show FieldDef, TemplateDef;

import '../domain/record_entry.dart';
import '../domain/record_history_event.dart';
import 'record_history_providers.dart';
import 'record_providers.dart';

/// The story of one record, read entirely from the local audit table (task
/// 014 step 6, spec §43): captures, processing runs, value edits with their
/// previous and new values, status moves and approvals, photos, captions,
/// template changes, merges and exports, as one chronology grouped by day.
///
/// Each line is one [AppListTile] naming the change, with who wrote it, on
/// which device and when underneath. A tap opens the line whole, so a long
/// value is never lost to the row's single line. Field labels and template
/// names come from the record's templates; they are data, and a template
/// no longer on this device leaves the field key in place of its label.
class RecordHistoryScreen extends ConsumerWidget {
  /// Creates the history page of record [recordId].
  const RecordHistoryScreen({required this.recordId, super.key});

  /// The record whose history is shown.
  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<List<RecordHistoryEvent>> history = ref.watch(
      recordHistoryProvider(recordId),
    );
    final AsyncValue<RecordEntry?> record = ref.watch(
      recordEntryProvider(recordId),
    );
    final RecordEntry? entry = record.value;
    final String subject = entry == null
        ? ''
        : localCopy.recordHistorySubject(
            number: entry.number,
            name: entry.name,
          );
    final List<RecordHistoryEvent>? events = history.value;
    return AppPage(
      key: const ValueKey<String>('route-record-history'),
      title: localCopy.recordHistoryTitle,
      subtitle: subject.isEmpty ? null : subject,
      scrollable: false,
      body: !history.hasError && events != null && events.isNotEmpty
          ? _Chronology(
              slots: _slotsOf(events),
              names: _namesFor(ref, entry, events),
            )
          : _StatePanel(
              child: AsyncValueView<List<RecordHistoryEvent>>(
                value: history,
                onRetry: () {
                  ref.invalidate(recordHistoryProvider(recordId));
                  ref.invalidate(recordEntryProvider(recordId));
                },
                isEmpty: (List<RecordHistoryEvent> loaded) => loaded.isEmpty,
                empty: () => _empty(context, record),
                data: (List<RecordHistoryEvent> _) => const SizedBox.shrink(),
              ),
            ),
    );
  }

  /// The empty panel: a record that is not on this device says so;
  /// otherwise the history is merely empty, and the next step is the record.
  Widget _empty(BuildContext context, AsyncValue<RecordEntry?> record) {
    final LocalizedCopy localCopy = Copy.of(context);

    if (!record.hasError && record.hasValue && record.value == null) {
      return AppEmptyState(
        icon: AppIcons.records,
        headline: localCopy.recordGoneHeadline,
        message: localCopy.recordGoneMessage,
        actionLabel: localCopy.navProjects,
        onAction: () => context.go(RoutePaths.projects),
      );
    }
    final bool canGoBack = ModalRoute.of(context)?.canPop ?? false;
    return AppEmptyState(
      icon: AppIcons.history,
      headline: localCopy.recordHistoryEmptyHeadline,
      message: localCopy.recordHistoryEmptyMessage,
      actionLabel: localCopy.recordHistoryBackToRecord,
      onAction: () {
        if (canGoBack) {
          Navigator.of(context).pop();
        } else {
          final RecordEntry? entry = record.value;
          context.go(
            entry == null
                ? RoutePaths.projects
                : RoutePaths.projectRecord(entry.projectId, recordId),
          );
        }
      },
    );
  }
}

/// The templates [events] name things from, most relevant first: the
/// record's own template, then every template a change moved it to or
/// from, latest change first. A template still loading or not on this
/// device is left out, and its fields show by key.
_HistoryNames _namesFor(
  WidgetRef ref,
  RecordEntry? entry,
  List<RecordHistoryEvent> events,
) {
  final Set<String> ids = <String>{
    if (entry != null && entry.templateId.isNotEmpty) entry.templateId,
    for (final RecordHistoryEvent event in events.reversed)
      if (event.kind == RecordHistoryKind.templateChanged) ...<String>[
        if ((event.next ?? '').isNotEmpty) event.next!,
        if ((event.previous ?? '').isNotEmpty) event.previous!,
      ],
  };
  return _HistoryNames(<TemplateDef>[
    for (final String id in ids)
      ?ref.watch(recordHistoryTemplateProvider(id)).value,
  ]);
}

/// [events], oldest first, with a day heading before the first line of
/// each local day.
List<_Slot> _slotsOf(List<RecordHistoryEvent> events) {
  final List<_Slot> slots = <_Slot>[];
  DateTime? current;
  for (final RecordHistoryEvent event in events) {
    final DateTime local = event.at.toLocal();
    final DateTime day = DateTime(local.year, local.month, local.day);
    if (day != current) {
      slots.add(_DaySlot(day));
      current = day;
    }
    slots.add(_EventSlot(event));
  }
  return slots;
}

/// One row of the chronology: a day heading or a history line.
sealed class _Slot {
  const _Slot();
}

final class _DaySlot extends _Slot {
  const _DaySlot(this.day);

  /// Local midnight of the day the lines below were written.
  final DateTime day;
}

final class _EventSlot extends _Slot {
  const _EventSlot(this.event);

  final RecordHistoryEvent event;
}

/// Field labels and template names from the templates a history names,
/// the first template to declare a field giving its label.
final class _HistoryNames {
  _HistoryNames(List<TemplateDef> templates)
    : _labels = <String, String>{
        for (final TemplateDef template in templates.reversed)
          for (final FieldDef field in template.fields)
            if (field.label.isNotEmpty) field.fieldKey: field.label,
      },
      _templates = <String, String>{
        for (final TemplateDef template in templates)
          if (template.name.isNotEmpty) template.id: template.name,
      },
      _known = <String>{
        for (final TemplateDef template in templates) template.id,
      };

  final Map<String, String> _labels;
  final Map<String, String> _templates;
  final Set<String> _known;

  /// The label of field [key], or the key when no template declares it.
  String field(String key) => _labels[key] ?? key;

  /// The name of template [id]; blank when it is not known here.
  String template(String id) => _templates[id] ?? '';

  /// Template [id] in a line's detail: its name, a stand-in for a
  /// template not on this device, or blank when there was none.
  String templateDetail(String id, {LocalizedCopy? localizedCopy}) {
    if (id.isEmpty) {
      return '';
    }
    final String name = template(id);
    if (name.isNotEmpty) {
      return name;
    }
    return _known.contains(id)
        ? id
        : (localizedCopy ?? Copy.english).recordHistoryTemplateGone;
  }
}

/// How one history line reads: its icon, its sentence and, for a change of
/// a value, a status or a template, what it was and what it became.
final class _HistoryLine {
  const _HistoryLine({
    required this.icon,
    required this.sentence,
    this.values = false,
    this.before = '',
    this.after = '',
    this.reason,
  });

  final IconData icon;
  final String sentence;

  /// Whether the detail shows [before] and [after].
  final bool values;
  final String before;
  final String after;

  /// Why the change was made, when the audit row says so in words.
  final String? reason;

  /// Describes [event] with [names], and status labels and icons from the
  /// shared status style (FE-CONS-07).
  static _HistoryLine of(
    RecordHistoryEvent event,
    _HistoryNames names,
    AppColors colors, {
    LocalizedCopy? localizedCopy,
  }) {
    final String previous = event.previous ?? '';
    final String next = event.next ?? '';
    final String key = event.fieldKey ?? '';
    switch (event.kind) {
      case RecordHistoryKind.created:
        final bool byHand = RecordStatus.fromStored(next) == RecordStatus.draft;
        return _HistoryLine(
          icon: byHand ? AppIcons.draft : AppIcons.captured,
          sentence: byHand
              ? (localizedCopy ?? Copy.english).recordHistoryCreatedByHand
              : (localizedCopy ?? Copy.english).recordHistoryCaptured,
        );
      case RecordHistoryKind.valueChanged:
        return _HistoryLine(
          icon: AppIcons.edit,
          sentence: (localizedCopy ?? Copy.english).recordHistoryValue(
            names.field(key),
            previous: previous,
            next: next,
          ),
          values: true,
          before: previous,
          after: next,
          reason: _wordsOf(event.reason),
        );
      case RecordHistoryKind.statusChanged:
        final RecordStatus? from = RecordStatus.fromStored(previous);
        final RecordStatus? to = RecordStatus.fromStored(next);
        final String fromLabel = from == null
            ? previous
            : StatusStyle.of(from, colors).$3;
        final String toLabel = to == null
            ? next
            : StatusStyle.of(to, colors).$3;
        return _HistoryLine(
          icon: to == null ? AppIcons.review : StatusStyle.of(to, colors).$2,
          sentence: (localizedCopy ?? Copy.english).recordHistoryStatus(
            previous: fromLabel,
            next: toLabel,
          ),
          values: true,
          before: fromLabel,
          after: toLabel,
          reason: _wordsOf(event.reason),
        );
      case RecordHistoryKind.photoAdded:
        return _HistoryLine(
          icon: AppIcons.addPhoto,
          sentence: (localizedCopy ?? Copy.english).recordHistoryPhotoAdded,
        );
      case RecordHistoryKind.photoRemoved:
        return _HistoryLine(
          icon: AppIcons.remove,
          sentence: (localizedCopy ?? Copy.english).recordHistoryPhotoRemoved,
        );
      case RecordHistoryKind.captionChanged:
        return _HistoryLine(
          icon: AppIcons.caption,
          sentence: (localizedCopy ?? Copy.english).recordHistoryValue(
            (localizedCopy ?? Copy.english).recordHistoryCaption,
            previous: previous,
            next: next,
          ),
          values: true,
          before: previous,
          after: next,
        );
      case RecordHistoryKind.templateChanged:
        return _HistoryLine(
          icon: AppIcons.template,
          sentence: (localizedCopy ?? Copy.english).recordHistoryTemplate(
            previous: names.template(previous),
            next: names.template(next),
          ),
          values: true,
          before: names.templateDetail(previous, localizedCopy: localizedCopy),
          after: names.templateDetail(next, localizedCopy: localizedCopy),
        );
      case RecordHistoryKind.processed:
        final Map<String, Object?> run = _jsonOf(event.reason);
        if (next == _failed) {
          final Object? attempts = run['attempts'];
          return _HistoryLine(
            icon: AppIcons.error,
            sentence: (localizedCopy ?? Copy.english)
                .recordHistoryProcessingFailed(attempts is int ? attempts : 0),
          );
        }
        return _HistoryLine(
          icon: AppIcons.processing,
          sentence: (localizedCopy ?? Copy.english).recordHistoryProcessed(
            provider: _textOf(run['provider']),
            model: _textOf(run['model']),
          ),
        );
      case RecordHistoryKind.merged:
        final String package = event.reason ?? '';
        return _HistoryLine(
          icon: AppIcons.merge,
          sentence: next == _inserted
              ? (localizedCopy ?? Copy.english).recordHistoryImported(package)
              : (localizedCopy ?? Copy.english).recordHistoryMerged(package),
        );
      case RecordHistoryKind.exported:
        return _HistoryLine(
          icon: AppIcons.export,
          sentence: (localizedCopy ?? Copy.english).recordHistoryExported(next),
        );
      case RecordHistoryKind.evidenceRemoved:
        final String label = names.field(key);
        return next == _no
            ? _HistoryLine(
                icon: AppIcons.photoLibrary,
                sentence: (localizedCopy ?? Copy.english)
                    .recordHistoryEvidenceRestored(label),
              )
            : _HistoryLine(
                icon: AppIcons.brokenFile,
                sentence: (localizedCopy ?? Copy.english)
                    .recordHistoryEvidenceRemoved(label),
              );
      case RecordHistoryKind.retired:
        final String label = names.field(key);
        return next == _no
            ? _HistoryLine(
                icon: AppIcons.unarchive,
                sentence: (localizedCopy ?? Copy.english)
                    .recordHistoryMappedAgain(label),
              )
            : _HistoryLine(
                icon: AppIcons.archive,
                sentence: (localizedCopy ?? Copy.english).recordHistoryRetired(
                  label,
                ),
              );
      case RecordHistoryKind.other:
        return switch (key) {
          _templateRowKey => _HistoryLine(
            icon: AppIcons.checklist,
            sentence: (localizedCopy ?? Copy.english).recordHistoryRowMatched,
          ),
          _evidenceMissingKey => _HistoryLine(
            icon: AppIcons.brokenFile,
            sentence: (localizedCopy ?? Copy.english).recordHistoryFileMissing,
          ),
          _ => _HistoryLine(
            icon: AppIcons.history,
            sentence: (localizedCopy ?? Copy.english).recordHistoryOther,
          ),
        };
    }
  }
}

/// [reason] when it is written in words; null when it is blank or a
/// machine-readable JSON note, which the line already reads for itself.
String? _wordsOf(String? reason) {
  final String words = reason?.trim() ?? '';
  return words.isEmpty || words.startsWith('{') ? null : words;
}

/// The JSON object a processing row keeps in its reason, or empty.
Map<String, Object?> _jsonOf(String? reason) {
  final String text = reason?.trim() ?? '';
  if (!text.startsWith('{')) {
    return const <String, Object?>{};
  }
  try {
    final Object? decoded = jsonDecode(text);
    return decoded is Map<String, Object?>
        ? decoded
        : const <String, Object?>{};
  } on FormatException {
    return const <String, Object?>{};
  }
}

/// [value] when it is text, else blank.
String _textOf(Object? value) => value is String ? value.trim() : '';

/// The virtualised chronology: day headings and history lines in one
/// lazily built list, so a long history never builds rows it does not
/// show (FE-PERF-03).
class _Chronology extends StatelessWidget {
  const _Chronology({required this.slots, required this.names});

  final List<_Slot> slots;
  final _HistoryNames names;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const ValueKey<String>('record-history-list'),
      padding: const EdgeInsets.only(bottom: Space.x4),
      itemCount: slots.length,
      itemBuilder: (BuildContext context, int index) {
        final LocalizedCopy localCopy = Copy.of(context);

        return ContentConstraint(
          child: switch (slots[index]) {
            _DaySlot(:final DateTime day) => AppSectionHeader(
              key: ValueKey<String>('record-history-day-${_dayKey(day)}'),
              title: localCopy.recordHistoryDay(day),
              dense: true,
            ),
            _EventSlot(:final RecordHistoryEvent event) => _HistoryRow(
              event: event,
              names: names,
            ),
          },
        );
      },
    );
  }
}

/// `yyyy-mm-dd` of [day], for the heading's key.
String _dayKey(DateTime day) {
  final String month = '${day.month}'.padLeft(2, '0');
  final String date = '${day.day}'.padLeft(2, '0');
  return '${day.year}-$month-$date';
}

/// One history line: the change, then when, by whom and on which device.
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.event, required this.names});

  final RecordHistoryEvent event;
  final _HistoryNames names;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AppColors colors = context.colors;
    final _HistoryLine line = _HistoryLine.of(
      event,
      names,
      colors,
      localizedCopy: Copy.of(context),
    );
    return AppListTile(
      key: ValueKey<String>('record-history-${event.id}'),
      leading: Icon(line.icon, color: colors.onSurface),
      title: line.sentence,
      subtitle: localCopy.recordHistoryByline(
        at: event.at.toLocal(),
        operator: event.operator,
        device: event.device,
      ),
      onTap: () => unawaited(
        showAppSheet<void>(
          context,
          title: Copy.of(context).recordHistoryLineTitle,
          contentSized: true,
          builder: (BuildContext _) => _HistoryDetail(event: event, line: line),
        ),
      ),
    );
  }
}

/// One history line whole: the sentence without truncation, the values
/// before and after, and when, by whom, on which device and why.
class _HistoryDetail extends StatelessWidget {
  const _HistoryDetail({required this.event, required this.line});

  final RecordHistoryEvent event;
  final _HistoryLine line;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AppColors colors = context.colors;
    final String? reason = line.reason;
    return SingleChildScrollView(
      key: const ValueKey<String>('record-history-detail'),
      padding: const EdgeInsets.fromLTRB(
        Space.x4,
        Space.x0,
        Space.x4,
        Space.x4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            line.sentence,
            style: AppText.bodyStrong.copyWith(color: colors.onSurface),
          ),
          if (line.values) ...<Widget>[
            _DetailLine(
              label: localCopy.recordHistoryBefore,
              value: line.before.isEmpty
                  ? localCopy.recordHistoryEmptyValue
                  : line.before,
            ),
            _DetailLine(
              label: localCopy.recordHistoryAfter,
              value: line.after.isEmpty
                  ? localCopy.recordHistoryEmptyValue
                  : line.after,
            ),
          ],
          _DetailLine(
            label: localCopy.recordHistoryWhen,
            value: localCopy.recordHistoryAt(event.at.toLocal()),
          ),
          _DetailLine(
            label: localCopy.recordHistoryOperator,
            value: event.operator.isEmpty
                ? localCopy.recordHistoryNotRecorded
                : event.operator,
          ),
          _DetailLine(
            label: localCopy.recordHistoryDevice,
            value: event.device.isEmpty
                ? localCopy.recordHistoryNotRecorded
                : event.device,
          ),
          if (reason != null)
            _DetailLine(label: localCopy.recordHistoryReason, value: reason),
        ],
      ),
    );
  }
}

/// A labelled line of the detail, read out as one phrase.
class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: Space.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: AppText.caption.copyWith(color: colors.onSurface),
            ),
            Text(value, style: AppText.body.copyWith(color: colors.onSurface)),
          ],
        ),
      ),
    );
  }
}

/// A state panel that scrolls in the page's readable column, so 200
/// percent text in landscape never clips it (FE-A11Y-03).
class _StatePanel extends StatelessWidget {
  const _StatePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppPage.gutter(context),
        vertical: Space.x2,
      ),
      child: ContentConstraint(child: child),
    );
  }
}

/// A processing row's new value when the run stopped for good.
const String _failed = 'failed';

/// A merge row's new value when the record arrived in the package.
const String _inserted = 'inserted';

/// A flag row's new value when the flag was lifted.
const String _no = 'false';

/// The marker of a checklist-row match (processing's normalise stage).
const String _templateRowKey = 'templateRowId';

/// The marker of a photo file found missing (the orphan scanner).
const String _evidenceMissingKey = 'evidenceMissing';
