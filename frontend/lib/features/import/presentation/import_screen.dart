import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/files/file_validation.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// One entry for every file the app can import (task 020).
///
/// The kind comes from the file gate, not from the extension alone. The
/// screen explains each destination and opens the one that matches.
final class ImportScreen extends StatelessWidget {
  /// Creates the entry. Null [kind] with no [failure] is the empty state.
  const ImportScreen({
    this.kind,
    this.loading = false,
    this.failure,
    this.onOpen,
    super.key,
  });

  /// Kind the gate reported.
  final ImportKind? kind;

  /// Whether the file is still being checked.
  final bool loading;

  /// Why the file was refused.
  final Failure? failure;

  /// Opens the flow for the detected kind.
  final ValueChanged<ImportFlow>? onOpen;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppPage(
        title: Copy.importTitle,
        body: AppErrorState(failure: failed),
      );
    }
    if (loading) {
      return const AppPage(title: Copy.importTitle, body: SizedBox.shrink());
    }
    final ImportKind? detected = kind;
    if (detected == null) {
      return const AppPage(
        title: Copy.importTitle,
        body: AppEmptyState(
          icon: AppIcons.import,
          headline: Copy.importEmptyHeadline,
          message: Copy.importEmptyMessage,
        ),
      );
    }
    final ImportFlow flow = _flow(detected);
    return AppPage(
      key: const ValueKey<String>('route-import'),
      title: Copy.importTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            Copy.importBundleLine,
            key: ValueKey<String>('import-line-bundle'),
          ),
          const Text(
            Copy.importDatasetLine,
            key: ValueKey<String>('import-line-dataset'),
          ),
          const Text(
            Copy.importTemplateLine,
            key: ValueKey<String>('import-line-template'),
          ),
          const Text(
            Copy.importSheetLine,
            key: ValueKey<String>('import-line-sheet'),
          ),
          AppButton(
            key: ValueKey<String>('import-open-${flow.name}'),
            label: _label(flow),
            onPressed: flow == ImportFlow.refused
                ? null
                : () => onOpen?.call(flow),
          ),
        ],
      ),
    );
  }

  static ImportFlow _flow(ImportKind kind) {
    return switch (kind) {
      ImportKind.bundle => ImportFlow.bundle,
      ImportKind.spreadsheet => ImportFlow.spreadsheet,
      ImportKind.document => ImportFlow.template,
      ImportKind.image || ImportKind.audio => ImportFlow.refused,
    };
  }

  static String _label(ImportFlow flow) {
    return switch (flow) {
      ImportFlow.bundle => Copy.importOpenBundle,
      ImportFlow.dataset => Copy.importOpenDataset,
      ImportFlow.template => Copy.importOpenTemplate,
      ImportFlow.spreadsheet => Copy.importOpenSheet,
      ImportFlow.refused => Copy.importRefused,
    };
  }
}

/// Where a validated file goes. The screen applies this; it does not ask.
enum ImportFlow {
  /// The merge flow.
  bundle,

  /// A reference dataset.
  dataset,

  /// A template workbook.
  template,

  /// Rows, which still need a purpose.
  spreadsheet,

  /// A kind this screen does not import.
  refused,
}
