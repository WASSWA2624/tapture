import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/reference_dataset.dart';
import '../domain/reference_row.dart';
import 'dataset_row_controller.dart';

/// In-place correction of one dataset row (task 010 step 5). A failed
/// save keeps what was typed and says why; records already prefilled from
/// the row keep the values they captured.
class DatasetRowEditScreen extends ConsumerStatefulWidget {
  /// Creates the editor for [rowId] in [datasetId].
  const DatasetRowEditScreen({
    super.key,
    required this.rowId,
    this.datasetId = '',
  });

  /// Row to edit.
  final String rowId;

  /// Dataset the row belongs to; read from the row when empty.
  final String datasetId;

  @override
  ConsumerState<DatasetRowEditScreen> createState() =>
      _DatasetRowEditScreenState();
}

class _DatasetRowEditScreenState extends ConsumerState<DatasetRowEditScreen> {
  final Map<String, TextEditingController> _fields =
      <String, TextEditingController>{};

  /// The row the fields were filled from, so a rebuild never overwrites
  /// what the operator typed.
  String? _bound;

  DatasetRowTarget get _target =>
      (datasetId: widget.datasetId, rowId: widget.rowId);

  @override
  void dispose() {
    for (final TextEditingController field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<DatasetRowView> value = ref.watch(
      datasetRowControllerProvider(_target),
    );
    return AppPage(
      key: const ValueKey<String>('route-dataset-row'),
      title: localCopy.datasetsEditRow,
      scrollable: false,
      body: AsyncValueView<DatasetRowView>(
        value: value,
        isEmpty: (DatasetRowView view) => view.row == null,
        empty: () => SingleChildScrollView(
          child: AppEmptyState(
            icon: AppIcons.datasetRow,
            headline: Copy.of(context).datasetsRowMissingHeadline,
            message: Copy.of(context).datasetsRowMissingMessage,
            actionLabel: Copy.of(context).close,
            onAction: () => Navigator.of(context).maybePop(),
          ),
        ),
        onRetry: () => ref.invalidate(datasetRowControllerProvider(_target)),
        data: _form,
      ),
    );
  }

  Widget _form(DatasetRowView view) {
    final LocalizedCopy localCopy = Copy.of(context);

    final ReferenceRow row = view.row!;
    final ReferenceDataset? dataset = view.dataset;
    _bind(row, dataset);
    final String? saveError = Copy.of(
      context,
    ).stateText(view.localizedSaveError, view.saveError);

    return AppForm(
      guardUnsaved: true,
      errors: <String>[?saveError],
      fields: <Widget>[
        if (row.addedOnDevice)
          AppBanner(
            message: localCopy.datasetsAddedOnDevice,
            icon: AppIcons.info,
            tone: SnackTone.info,
          ),
        for (final MapEntry<String, TextEditingController> field
            in _fields.entries)
          AppTextField(
            key: ValueKey<String>('dataset-row-field-${field.key}'),
            label: field.key,
            controller: field.value,
            requiredness: field.key == dataset?.keyColumn
                ? FieldRequiredness.required
                : FieldRequiredness.optional,
            textInputAction: TextInputAction.next,
          ),
      ],
      submitLabel: localCopy.datasetsSaveRow,
      onSubmit: _save,
    );
  }

  /// Fills one field per column, in dataset order, from [row] once.
  void _bind(ReferenceRow row, ReferenceDataset? dataset) {
    if (_bound == row.id) {
      return;
    }
    for (final TextEditingController field in _fields.values) {
      field.dispose();
    }
    _fields.clear();
    final List<String> columns = <String>[
      ...?dataset?.columns,
      for (final String column in row.values.keys)
        if (!(dataset?.columns.contains(column) ?? false)) column,
    ];
    for (final String column in columns) {
      _fields[column] = TextEditingController(text: row.values[column] ?? '');
    }
    _bound = row.id;
  }

  Future<bool> _save() async {
    final ReferenceRow? saved = await ref
        .read(datasetRowControllerProvider(_target).notifier)
        .save(<String, String>{
          for (final MapEntry<String, TextEditingController> field
              in _fields.entries)
            field.key: field.value.text,
        });
    if (saved == null || !mounted) {
      return false;
    }
    // The form forgets its edits once this returns, so leave on the next
    // frame, when there is nothing left to guard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    });
    return true;
  }
}
