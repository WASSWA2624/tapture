import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/reference_row.dart';

/// Opens the multi-match picker. Returns the chosen row.
Future<ReferenceRow?> showLookupPickerSheet({
  required BuildContext context,
  required List<ReferenceRow> matches,
  required List<String> distinguishColumns,
  Failure? failure,
}) {
  return showAppSheet<ReferenceRow>(
    context,
    title: Copy.datasetsPickMatch,
    builder: (BuildContext context) {
      return LookupPickerSheet(
        matches: matches,
        distinguishColumns: distinguishColumns,
        failure: failure,
      );
    },
  );
}

/// Shows the columns that distinguish matching rows rather than just the name.
class LookupPickerSheet extends StatelessWidget {
  /// Creates the picker body.
  const LookupPickerSheet({
    super.key,
    required this.matches,
    required this.distinguishColumns,
    this.failure,
  });

  /// Candidate rows.
  final List<ReferenceRow> matches;

  /// Columns that differ across [matches].
  final List<String> distinguishColumns;

  /// Injected failure for widget tests.
  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    if (failure != null) {
      return AsyncValueView<void>(
        value: AsyncValue<void>.error(failure!, StackTrace.empty),
        data: (_) => const SizedBox.shrink(),
      );
    }
    if (matches.isEmpty) {
      return const AppEmptyState(
        icon: Icons.search_off_outlined,
        headline: Copy.datasetsBrowserEmptyHeadline,
        message: Copy.datasetsBrowserEmptyMessage,
      );
    }
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        for (final ReferenceRow row in matches)
          AppListTile(
            title: row.key,
            subtitle: <String>[
              for (final String column in distinguishColumns)
                '$column: ${row.values[column] ?? ''}',
            ].join(' · '),
            onTap: () => Navigator.of(context).pop(row),
          ),
      ],
    );
  }
}
