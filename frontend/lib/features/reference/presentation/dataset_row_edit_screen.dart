import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/reference_row.dart';
import '../reference.dart' show referenceRepositoryProvider;

/// In-place correction of one dataset row. Does not rewrite prefilled records.
class DatasetRowEditScreen extends ConsumerStatefulWidget {
  /// Creates the editor for [rowId].
  const DatasetRowEditScreen({super.key, required this.rowId, this.failure});

  /// Row to edit.
  final String rowId;

  /// Injected failure for widget tests.
  final Failure? failure;

  @override
  ConsumerState<DatasetRowEditScreen> createState() =>
      _DatasetRowEditScreenState();
}

class _DatasetRowEditScreenState extends ConsumerState<DatasetRowEditScreen> {
  ReferenceRow? _row;
  Map<String, String> _previous = const <String, String>{};
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};
  Failure? _error;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Failure? failure = widget.failure ?? _error;
    if (failure != null) {
      return AppPage(
        title: Copy.datasetsEditRow,
        showAppBar: false,
        body: AsyncValueView<void>(
          value: AsyncValue<void>.error(failure, StackTrace.empty),
          data: (_) => const SizedBox.shrink(),
          onRetry: () => unawaited(_load()),
        ),
      );
    }
    if (_loading || _row == null) {
      if (!_loading && _row == null) {
        return const AppPage(
          title: Copy.datasetsEditRow,
          showAppBar: false,
          body: AppEmptyState(
            icon: Icons.edit_off_outlined,
            headline: Copy.datasetsBrowserEmptyHeadline,
            message: Copy.datasetsBrowserEmptyMessage,
          ),
        );
      }
      return AppPage(
        title: Copy.datasetsEditRow,
        showAppBar: false,
        body: AsyncValueView<void>(
          value: const AsyncValue<void>.loading(),
          data: (_) => const SizedBox.shrink(),
        ),
      );
    }
    final ReferenceRow row = _row!;
    return AppPage(
      title: Copy.datasetsEditRow,
      showAppBar: false,
      scrollable: false,
      footer: AppPrimaryAction(
        label: Copy.datasetsSaveRow,
        onPressed: _saving ? null : () => unawaited(_save()),
      ),
      body: ListView(
        children: <Widget>[
          for (final MapEntry<String, TextEditingController> entry
              in _controllers.entries)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AppTextField(label: entry.key, controller: entry.value),
            ),
          if (row.addedOnDevice)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(Copy.datasetsAddedOnDevice),
            ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final Result<ReferenceRow?> result = await ref
        .read(referenceRepositoryProvider)
        .rowById(widget.rowId);
    if (!mounted) {
      return;
    }
    switch (result) {
      case FailureResult<ReferenceRow?>(:final Failure failure):
        setState(() {
          _loading = false;
          _error = failure;
        });
      case Success<ReferenceRow?>(:final ReferenceRow? value):
        if (value == null) {
          setState(() {
            _loading = false;
            _row = null;
          });
          return;
        }
        for (final TextEditingController controller in _controllers.values) {
          controller.dispose();
        }
        _controllers
          ..clear()
          ..addEntries(<MapEntry<String, TextEditingController>>[
            for (final MapEntry<String, String> entry in value.values.entries)
              MapEntry<String, TextEditingController>(
                entry.key,
                TextEditingController(text: entry.value),
              ),
          ]);
        setState(() {
          _row = value;
          _previous = Map<String, String>.of(value.values);
          _loading = false;
        });
    }
  }

  Future<void> _save() async {
    final ReferenceRow? row = _row;
    if (row == null) {
      return;
    }
    setState(() => _saving = true);
    final Map<String, String> values = <String, String>{
      for (final MapEntry<String, TextEditingController> entry
          in _controllers.entries)
        entry.key: entry.value.text,
    };
    final Result<ReferenceRow> saved = await ref
        .read(referenceRepositoryProvider)
        .saveRow(
          row.copyWith(
            key: values[row.values.keys.first] ?? row.key,
            values: values,
          ),
          previousValues: _previous,
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
      case Success<ReferenceRow>():
        context.pop();
    }
  }
}
