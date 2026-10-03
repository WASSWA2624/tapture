import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/lookup_binding.dart';
import '../domain/reference_row.dart';
import 'dataset_row_controller.dart';

/// Opens the add-row sheet for a lookup that found nothing. Completes with
/// the saved row, flagged added on this device, or null when dismissed.
Future<ReferenceRow?> showDatasetAddRowSheet({
  required BuildContext context,
  required String datasetId,
  required String keyColumn,
  required LookupBinding binding,
}) {
  final LocalizedCopy localCopy = Copy.of(context);

  return showAppSheet<ReferenceRow>(
    context,
    title: localCopy.datasetsAddRow,
    contentSized: true,
    builder: (BuildContext _) {
      return DatasetAddRowSheet(
        datasetId: datasetId,
        keyColumn: keyColumn,
        binding: binding,
      );
    },
  );
}

/// Asks for the key column and the columns the current lookup binding
/// fills, nothing more (task 010 step 5). Leaving with typed values asks
/// first, and a failed save keeps them.
class DatasetAddRowSheet extends ConsumerStatefulWidget {
  /// Creates the sheet body.
  const DatasetAddRowSheet({
    super.key,
    required this.datasetId,
    required this.keyColumn,
    required this.binding,
  });

  /// Dataset that receives the row.
  final String datasetId;

  /// Key column name.
  final String keyColumn;

  /// Binding that failed; only its fill columns are collected.
  final LookupBinding binding;

  @override
  ConsumerState<DatasetAddRowSheet> createState() => _DatasetAddRowSheetState();
}

class _DatasetAddRowSheetState extends ConsumerState<DatasetAddRowSheet> {
  final TextEditingController _key = TextEditingController();
  final Map<String, TextEditingController> _fields =
      <String, TextEditingController>{};

  DatasetRowTarget get _target => (datasetId: widget.datasetId, rowId: '');

  @override
  void initState() {
    super.initState();
    for (final String column in widget.binding.fillMapping.keys) {
      if (column != widget.keyColumn) {
        _fields[column] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _key.dispose();
    for (final TextEditingController field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.datasetId.isEmpty) {
      return _noDataset(context);
    }
    return AsyncValueView<DatasetRowView>(
      value: ref.watch(datasetRowControllerProvider(_target)),
      isEmpty: (DatasetRowView view) => view.dataset == null,
      empty: () => _noDataset(context),
      onRetry: () => ref.invalidate(datasetRowControllerProvider(_target)),
      data: (DatasetRowView view) {
        final LocalizedCopy localCopy = Copy.of(context);

        final String? saveError = Copy.of(
          context,
        ).stateText(view.localizedSaveError, view.saveError);

        return AppForm(
          compact: true,
          guardUnsaved: true,
          errors: <String>[?saveError],
          fields: <Widget>[
            AppTextField(
              key: const ValueKey<String>('dataset-add-key'),
              label: widget.keyColumn,
              controller: _key,
              requiredness: FieldRequiredness.required,
              textInputAction: TextInputAction.next,
            ),
            for (final MapEntry<String, TextEditingController> field
                in _fields.entries)
              AppTextField(
                key: ValueKey<String>('dataset-add-${field.key}'),
                label: field.key,
                controller: field.value,
                textInputAction: TextInputAction.next,
              ),
          ],
          submitLabel: localCopy.datasetsAddRow,
          onSubmit: _save,
        );
      },
    );
  }

  Widget _noDataset(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return AppEmptyState(
      icon: AppIcons.dataset,
      headline: localCopy.datasetsAddRowNoDatasetHeadline,
      message: localCopy.datasetsAddRowNoDatasetMessage,
      actionLabel: localCopy.close,
      onAction: () => Navigator.of(context).maybePop(),
    );
  }

  Future<bool> _save() async {
    final ReferenceRow? saved = await ref
        .read(datasetRowControllerProvider(_target).notifier)
        .save(<String, String>{
          widget.keyColumn: _key.text,
          for (final MapEntry<String, TextEditingController> field
              in _fields.entries)
            field.key: field.value.text,
        });
    if (saved == null || !mounted) {
      return false;
    }
    // The form forgets its edits once this returns, so close on the next
    // frame, when there is nothing left to guard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(saved);
      }
    });
    return true;
  }
}
