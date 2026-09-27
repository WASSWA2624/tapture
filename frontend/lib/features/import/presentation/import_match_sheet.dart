import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';

import '../domain/import_duplicates.dart';

/// Asks how one matched row is settled, through the shared confirm dialog.
///
/// The choice can apply to this row only or to every later match.
final class ImportMatchSheet extends StatelessWidget {
  /// Creates the sheet.
  const ImportMatchSheet({required this.onChoice, super.key});

  /// Reports the choice and whether it covers the rest of the run.
  final void Function(ImportDuplicateChoice choice, bool applyToAll) onChoice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppButton(
          key: const ValueKey<String>('import-match-keep'),
          label: Copy.importKeepExisting,
          onPressed: () =>
              unawaited(_choose(context, ImportDuplicateChoice.keepExisting)),
        ),
        AppButton(
          key: const ValueKey<String>('import-match-replace'),
          label: Copy.importReplace,
          variant: AppButtonVariant.secondary,
          onPressed: () =>
              unawaited(_choose(context, ImportDuplicateChoice.replace)),
        ),
        AppButton(
          key: const ValueKey<String>('import-match-merge'),
          label: Copy.importMerge,
          variant: AppButtonVariant.secondary,
          onPressed: () =>
              unawaited(_choose(context, ImportDuplicateChoice.merge)),
        ),
      ],
    );
  }

  Future<void> _choose(
    BuildContext context,
    ImportDuplicateChoice choice,
  ) async {
    final bool applyToAll = await showAppConfirm(
      context,
      title: Copy.importApplyToAllTitle,
      message: Copy.importApplyToAllMessage,
      confirmLabel: Copy.importApplyToAllConfirm,
      alternativeLabel: Copy.importApplyToThis,
    );
    if (!context.mounted) {
      return;
    }
    onChoice(choice, applyToAll);
  }
}
