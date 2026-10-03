import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

import '../domain/import_duplicates.dart';

/// Asks, on one sheet, what happens to spreadsheet row [row], which matches
/// a record already here (task 020): keep that record, replace it or merge
/// into it, for this row or for every later match. Null when the sheet is
/// dismissed, which decides nothing.
Future<ImportMatchDecision?> showImportMatchSheet(
  BuildContext context, {
  required int row,
}) {
  final LocalizedCopy localCopy = Copy.of(context);

  return showAppSheet<ImportMatchDecision>(
    context,
    title: localCopy.importMatchTitle,
    contentSized: true,
    builder: (BuildContext _) => ImportMatchSheet(row: row),
  );
}

/// The body of [showImportMatchSheet]: the choice, the apply-to-all box and
/// one confirm, which closes the sheet with the decision.
final class ImportMatchSheet extends StatefulWidget {
  /// Creates the sheet for spreadsheet row [row].
  const ImportMatchSheet({required this.row, super.key});

  /// The spreadsheet row that matched.
  final int row;

  @override
  State<ImportMatchSheet> createState() => _ImportMatchSheetState();
}

class _ImportMatchSheetState extends State<ImportMatchSheet> {
  final ValueNotifier<ImportMatchDecision> _draft =
      ValueNotifier<ImportMatchDecision>((
        choice: ImportDuplicateChoice.keepExisting,
        applyToAll: false,
      ));

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Space.x4),
      child: ValueListenableBuilder<ImportMatchDecision>(
        valueListenable: _draft,
        builder: (BuildContext context, ImportMatchDecision draft, Widget? _) {
          final LocalizedCopy localCopy = Copy.of(context);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(localCopy.importMatchMessage(widget.row)),
              const SizedBox(height: Space.x3),
              AppRadioGroup<ImportDuplicateChoice>(
                key: const ValueKey<String>('import-match-choice'),
                label: localCopy.importMatchChoice,
                value: draft.choice,
                options: _options(localCopy),
                onChanged: (ImportDuplicateChoice next) {
                  _draft.value = (choice: next, applyToAll: draft.applyToAll);
                },
              ),
              AppSwitchTile.checkbox(
                key: const ValueKey<String>('import-match-all'),
                title: localCopy.importApplyToAll,
                value: draft.applyToAll,
                onChanged: (bool next) {
                  _draft.value = (choice: draft.choice, applyToAll: next);
                },
              ),
              const SizedBox(height: Space.x3),
              AppButton(
                key: const ValueKey<String>('import-match-confirm'),
                label: localCopy.importMatchConfirm,
                expand: true,
                onPressed: () =>
                    Navigator.of(context).pop<ImportMatchDecision>(draft),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// What a person decided for one matching row: [choice], and whether it
/// settles every later match of the run too.
typedef ImportMatchDecision = ({ImportDuplicateChoice choice, bool applyToAll});

List<Choice<ImportDuplicateChoice>> _options(LocalizedCopy localCopy) =>
    <Choice<ImportDuplicateChoice>>[
      Choice<ImportDuplicateChoice>(
        ImportDuplicateChoice.keepExisting,
        localCopy.importKeepExisting,
      ),
      Choice<ImportDuplicateChoice>(
        ImportDuplicateChoice.replace,
        localCopy.importReplace,
      ),
      Choice<ImportDuplicateChoice>(
        ImportDuplicateChoice.merge,
        localCopy.importMerge,
      ),
    ];
