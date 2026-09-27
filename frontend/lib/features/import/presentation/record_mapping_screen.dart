import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/validation/field_rule.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import '../domain/record_import.dart';

/// Maps workbook columns onto an existing template (task 020).
///
/// Suggestions come from header names. Continuing is blocked while an
/// identity field is unmapped. The first rows are shown as they will be read.
final class RecordMappingScreen extends StatelessWidget {
  /// Creates the mapping. Empty [headers] is the empty state.
  const RecordMappingScreen({
    this.headers = const <String>[],
    this.fields = const <FieldRule>[],
    this.columnToField = const <String, String>{},
    this.preview = const <Map<String, String>>[],
    this.loading = false,
    this.failure,
    this.onContinue,
    super.key,
  });

  /// Workbook headers, from the shared header detector.
  final List<String> headers;

  /// Target template fields.
  final List<FieldRule> fields;

  /// Header to field key. The operator confirms every one.
  final Map<String, String> columnToField;

  /// The first data rows, already interpreted.
  final List<Map<String, String>> preview;

  /// Whether the workbook is still opening.
  final bool loading;

  /// Why the workbook could not be read.
  final Failure? failure;

  /// Continues once every identity field is mapped.
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppPage(
        title: Copy.importMappingTitle,
        body: AppErrorState(failure: failed),
      );
    }
    if (loading) {
      return const AppPage(
        title: Copy.importMappingTitle,
        body: SizedBox.shrink(),
      );
    }
    if (headers.isEmpty) {
      return const AppPage(
        title: Copy.importMappingTitle,
        body: AppEmptyState(
          icon: AppIcons.fields,
          headline: Copy.importEmptyHeadline,
          message: Copy.importEmptyMessage,
        ),
      );
    }
    final List<String> missing = RecordImport.missingIdentity(
      fields: fields,
      columnToField: columnToField,
    );
    return AppPage(
      title: Copy.importMappingTitle,
      footer: AppButton(
        key: const ValueKey<String>('import-mapping-continue'),
        label: Copy.importContinue,
        expand: true,
        onPressed: missing.isEmpty ? onContinue : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final String header in headers)
            AppListTile(
              key: ValueKey<String>('import-map-$header'),
              title: header,
              subtitle: columnToField[header] ?? Copy.importUnmapped,
            ),
          if (missing.isNotEmpty)
            Text(
              Copy.importIdentityMissing(missing.first),
              key: const ValueKey<String>('import-identity-missing'),
            ),
          for (final Map<String, String> row in preview)
            Text(
              row.values.join(' · '),
              key: ValueKey<String>('import-preview-${row.values.join('|')}'),
            ),
        ],
      ),
    );
  }
}
