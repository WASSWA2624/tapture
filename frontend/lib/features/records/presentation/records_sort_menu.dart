import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

import '../domain/record_sort.dart';
import 'records_list_controller.dart';

/// The records list's sort control (task 014 step 2): a button naming the
/// current order that opens the six orders — number, capture date and name,
/// each both ways — with the current one checked. Choosing one applies it in
/// the query through the list's controller and closes the choice; the
/// project remembers it (D11).
final class RecordsSortMenu extends ConsumerWidget {
  /// Creates the sort control of [projectId]'s records list.
  const RecordsSortMenu({required this.projectId, super.key});

  /// The project whose records list is ordered.
  final String projectId;

  /// Every order the list offers, in the order they are shown.
  static const List<RecordSort> orders = <RecordSort>[
    RecordSort(key: RecordSortKey.number, ascending: false),
    RecordSort(key: RecordSortKey.number, ascending: true),
    RecordSort(key: RecordSortKey.capturedAt, ascending: false),
    RecordSort(key: RecordSortKey.capturedAt, ascending: true),
    RecordSort(key: RecordSortKey.name, ascending: true),
    RecordSort(key: RecordSortKey.name, ascending: false),
  ];

  /// What [sort] is called in the choice and on the control.
  static String labelOf(RecordSort sort, {LocalizedCopy? localizedCopy}) {
    return switch ((sort.key, sort.ascending)) {
      (RecordSortKey.number, false) =>
        (localizedCopy ?? Copy.english).recordsSortNumberDescending,
      (RecordSortKey.number, true) =>
        (localizedCopy ?? Copy.english).recordsSortNumberAscending,
      (RecordSortKey.capturedAt, false) =>
        (localizedCopy ?? Copy.english).recordsSortCapturedDescending,
      (RecordSortKey.capturedAt, true) =>
        (localizedCopy ?? Copy.english).recordsSortCapturedAscending,
      (RecordSortKey.name, true) =>
        (localizedCopy ?? Copy.english).recordsSortNameAscending,
      (RecordSortKey.name, false) =>
        (localizedCopy ?? Copy.english).recordsSortNameDescending,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final RecordSort sort = ref.watch(
      recordsListControllerProvider(
        projectId,
      ).select((RecordsListCriteria criteria) => criteria.sort),
    );
    final String label = localCopy.recordsSortLabel(
      labelOf(sort, localizedCopy: localCopy),
    );
    return AppIconButton(
      key: const ValueKey<String>('records-sort'),
      icon: AppIcons.sort,
      tooltip: label,
      semanticLabel: label,
      outlined: false,
      onPressed: () => unawaited(_open(context)),
    );
  }

  Future<void> _open(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return showAppSheet<void>(
      context,
      title: localCopy.recordsSortTitle,
      contentSized: true,
      builder: (BuildContext sheetContext) {
        return _SortChoice(projectId: projectId);
      },
    );
  }
}

class _SortChoice extends ConsumerWidget {
  const _SortChoice({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final RecordSort sort = ref.watch(
      recordsListControllerProvider(
        projectId,
      ).select((RecordsListCriteria criteria) => criteria.sort),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Space.x3,
        Space.x0,
        Space.x3,
        Space.x3,
      ),
      child: AppRadioGroup<RecordSort>(
        key: const ValueKey<String>('records-sort-choice'),
        label: localCopy.recordsSortTitle,
        showLabel: false,
        options: <Choice<RecordSort>>[
          for (final RecordSort order in RecordsSortMenu.orders)
            Choice<RecordSort>(
              order,
              RecordsSortMenu.labelOf(order, localizedCopy: localCopy),
            ),
        ],
        value: sort,
        onChanged: (RecordSort chosen) {
          ref
              .read(recordsListControllerProvider(projectId).notifier)
              .applySort(chosen);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
