import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/lookup_binding.dart';
import '../domain/reference_row.dart';
import '../reference.dart' show referenceRepositoryProvider;

/// Opens the add-row sheet for a failed lookup. Returns the saved row.
Future<ReferenceRow?> showDatasetAddRowSheet({
  required BuildContext context,
  required String datasetId,
  required String keyColumn,
  required LookupBinding binding,
  Failure? failure,
}) {
  return showAppSheet<ReferenceRow>(
    context,
    title: Copy.datasetsAddRow,
    builder: (BuildContext context) {
      return DatasetAddRowSheet(
        datasetId: datasetId,
        keyColumn: keyColumn,
        binding: binding,
        failure: failure,
      );
    },
  );
}

/// Asks for the key column and the columns the current lookup binding fills.
class DatasetAddRowSheet extends ConsumerStatefulWidget {
  /// Creates the sheet body.
  const DatasetAddRowSheet({
    super.key,
    required this.datasetId,
    required this.keyColumn,
    required this.binding,
    this.failure,
  });

  /// Dataset that receives the row.
  final String datasetId;

  /// Key column name.
  final String keyColumn;

  /// Binding that failed — only its fill columns are collected.
  final LookupBinding binding;

  /// Injected failure for widget tests.
  final Failure? failure;

  @override
  ConsumerState<DatasetAddRowSheet> createState() => _DatasetAddRowSheetState();
}

class _DatasetAddRowSheetState extends ConsumerState<DatasetAddRowSheet> {
  late final TextEditingController _key;
  final Map<String, TextEditingController> _fields =
      <String, TextEditingController>{};
  Failure? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _key = TextEditingController();
    for (final String column in widget.binding.fillMapping.keys) {
      _fields[column] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _key.dispose();
    for (final TextEditingController controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Failure? failure = widget.failure ?? _error;
    if (failure != null) {
      return AsyncValueView<void>(
        value: AsyncValue<void>.error(failure, StackTrace.empty),
        data: (_) => const SizedBox.shrink(),
        onRetry: () => setState(() => _error = null),
      );
    }
    if (widget.datasetId.isEmpty) {
      return const AppEmptyState(
        icon: Icons.table_chart_outlined,
        headline: Copy.datasetsEmptyHeadline,
        message: Copy.datasetsEmptyMessage,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppTextField(label: widget.keyColumn, controller: _key),
          for (final MapEntry<String, TextEditingController> entry
              in _fields.entries)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AppTextField(label: entry.key, controller: entry.value),
            ),
          const SizedBox(height: 16),
          AppButton(
            label: Copy.datasetsAddRow,
            busy: _saving,
            onPressed: _saving ? null : () => unawaited(_save()),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final Map<String, String> values = <String, String>{
      widget.keyColumn: _key.text,
      for (final MapEntry<String, TextEditingController> entry
          in _fields.entries)
        entry.key: entry.value.text,
    };
    final Result<ReferenceRow> saved = await ref
        .read(referenceRepositoryProvider)
        .saveRow(
          ReferenceRow(
            id: '',
            datasetId: widget.datasetId,
            key: _key.text.trim(),
            values: values,
            addedOnDevice: true,
          ),
        );
    if (!mounted) {
      return;
    }
    switch (saved) {
      case FailureResult<ReferenceRow>(:final Failure failure):
        setState(() {
          _saving = false;
          _error = failure;
        });
      case Success<ReferenceRow>(:final ReferenceRow value):
        Navigator.of(context).pop(value);
    }
  }
}
