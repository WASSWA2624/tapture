import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/quality/quality.dart' show VerificationPrefill;

/// Spreadsheets only: hold the rows, or verify against them.
final class ImportPurposeStep extends StatelessWidget {
  /// Creates the question.
  const ImportPurposeStep({
    this.rows = const <Map<String, String>>[],
    this.binding = const <String, String>{},
    this.loading = false,
    this.empty = false,
    this.failure,
    this.onRecords,
    this.onRegister,
    super.key,
  });

  /// Spreadsheet rows. A register choice turns these into verification
  /// prefills and creates no records.
  final List<Map<String, String>> rows;

  /// Field key to column name, for [VerificationPrefill.fromRow].
  final Map<String, String> binding;

  /// Whether the sheet is still opening.
  final bool loading;

  /// Whether there is no sheet.
  final bool empty;

  /// Why the sheet could not be read.
  final Failure? failure;

  /// Rows become records.
  final VoidCallback? onRecords;

  /// Rows feed verification and create nothing.
  final ValueChanged<List<VerificationPrefill>>? onRegister;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppPage(
        title: Copy.importPurposeTitle,
        body: AppErrorState(failure: failed),
      );
    }
    if (loading) {
      return const AppPage(
        title: Copy.importPurposeTitle,
        body: SizedBox.shrink(),
      );
    }
    if (empty) {
      return const AppPage(
        title: Copy.importPurposeTitle,
        body: AppEmptyState(
          icon: AppIcons.import,
          headline: Copy.importEmptyHeadline,
          message: Copy.importEmptyMessage,
        ),
      );
    }
    return AppPage(
      title: Copy.importPurposeTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppButton(
            key: const ValueKey<String>('import-purpose-records'),
            label: Copy.importPurposeRecords,
            onPressed: onRecords,
          ),
          AppButton(
            key: const ValueKey<String>('import-purpose-register'),
            label: Copy.importPurposeRegister,
            variant: AppButtonVariant.secondary,
            onPressed: () => onRegister?.call(<VerificationPrefill>[
              for (final Map<String, String> row in rows)
                VerificationPrefill.fromRow(row: row, binding: binding),
            ]),
          ),
        ],
      ),
    );
  }
}
