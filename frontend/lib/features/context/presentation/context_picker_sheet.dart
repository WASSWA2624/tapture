import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/reference/domain/lookup_matcher.dart';
import 'package:tapture/features/reference/domain/reference_row.dart';
import 'package:tapture/features/reference/reference.dart'
    show referenceRepositoryProvider;

import '../context.dart' show contextRepositoryProvider;
import '../domain/context_cascade.dart';
import '../domain/context_state.dart';
import 'context_providers.dart';

/// Opens the level picker sheet.
Future<void> showContextPickerSheet({
  required BuildContext context,
  required String projectId,
  required ContextLevel level,
  required String currentValue,
  Failure? failure,
}) {
  return showAppSheet<void>(
    context,
    title: Copy.contextPickerTitle(
      level.label.isEmpty ? level.fieldKey : level.label,
    ),
    builder: (BuildContext context) {
      return ContextPickerSheet(
        projectId: projectId,
        level: level,
        currentValue: currentValue,
        failure: failure,
      );
    },
  );
}

/// Sets one level from recents, dataset search, or free text.
class ContextPickerSheet extends ConsumerStatefulWidget {
  /// Creates the picker body.
  const ContextPickerSheet({
    super.key,
    required this.projectId,
    required this.level,
    required this.currentValue,
    this.failure,
  });

  /// Owning project.
  final String projectId;

  /// Level being set.
  final ContextLevel level;

  /// Current value.
  final String currentValue;

  /// Injected failure for tests.
  final Failure? failure;

  @override
  ConsumerState<ContextPickerSheet> createState() => _ContextPickerSheetState();
}

class _ContextPickerSheetState extends ConsumerState<ContextPickerSheet> {
  late final TextEditingController _text;
  List<String> _recents = const <String>[];
  List<ReferenceRow> _matches = const <ReferenceRow>[];
  Failure? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.currentValue);
    unawaited(_loadRecents());
  }

  @override
  void dispose() {
    _text.dispose();
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_recents.isEmpty &&
              (widget.level.datasetId == null ||
                  widget.level.datasetId!.isEmpty))
            const AppEmptyState(
              icon: Icons.history,
              headline: Copy.contextRecents,
              message: Copy.contextHierarchyEmptyMessage,
            ),
          if (_recents.isNotEmpty) ...<Widget>[
            const Text(Copy.contextRecents),
            for (final String recent in _recents)
              AppListTile(
                title: recent,
                onTap: () => unawaited(_choose(recent)),
              ),
          ],
          if (widget.level.datasetId != null &&
              widget.level.datasetId!.isNotEmpty) ...<Widget>[
            const Text(Copy.contextDatasetSearch),
            AppSearchField(
              hint: Copy.contextDatasetSearch,
              onChanged: (String query) => unawaited(_search(query)),
            ),
            for (final ReferenceRow row in _matches)
              AppListTile(
                title: row.key,
                onTap: () => unawaited(_choose(row.key)),
              ),
          ],
          AppTextField(label: Copy.contextUseValue, controller: _text),
          const SizedBox(height: 8),
          AppButton(
            label: Copy.contextUseValue,
            busy: _busy,
            onPressed: _busy
                ? null
                : () => unawaited(_choose(_text.text.trim())),
          ),
        ],
      ),
    );
  }

  Future<void> _loadRecents() async {
    final Result<List<String>> result = await ref
        .read(contextRepositoryProvider)
        .recentValues(
          projectId: widget.projectId,
          fieldKey: widget.level.fieldKey,
        );
    if (!mounted) {
      return;
    }
    switch (result) {
      case Success<List<String>>(:final List<String> value):
        setState(() => _recents = value);
      case FailureResult<List<String>>():
        break;
    }
  }

  Future<void> _search(String query) async {
    final String? datasetId = widget.level.datasetId;
    if (datasetId == null || datasetId.isEmpty || query.trim().isEmpty) {
      setState(() => _matches = const <ReferenceRow>[]);
      return;
    }
    final Result<List<ReferenceRow>> page = await ref
        .read(referenceRepositoryProvider)
        .pageRows(datasetId: datasetId, offset: 0, limit: 20, query: query);
    if (!mounted) {
      return;
    }
    switch (page) {
      case Success<List<ReferenceRow>>(:final List<ReferenceRow> value):
        final List<ReferenceRow> soft = LookupMatcher.match(
          rows: value,
          query: query,
          matchColumns: <String>[widget.level.fieldKey, 'name', ''],
        );
        setState(() => _matches = soft.isEmpty ? value : soft);
      case FailureResult<List<ReferenceRow>>(:final Failure failure):
        setState(() => _error = failure);
    }
  }

  Future<void> _choose(String value) async {
    if (value.isEmpty) {
      return;
    }
    final ContextState? state = ref
        .read(projectContextProvider(widget.projectId))
        .asData
        ?.value;
    if (state == null) {
      return;
    }
    final List<({ContextLevel level, String value})> below =
        ContextCascade.affected(
          state: state,
          changedFieldKey: widget.level.fieldKey,
        );
    final List<({ContextLevel level, String value})> named =
        <({ContextLevel level, String value})>[
          for (final ({ContextLevel level, String value}) item in below)
            if (item.value.isNotEmpty) item,
        ];
    if (named.isNotEmpty) {
      final bool ok = await showAppConfirm(
        context,
        title: Copy.contextCascadeTitle,
        message: Copy.contextCascadeMessage(<String>[
          for (final ({ContextLevel level, String value}) item in named)
            '${item.level.label.isEmpty ? item.level.fieldKey : item.level.label}: ${item.value}',
        ]),
        confirmLabel: Copy.contextCascadeConfirm,
      );
      if (!ok) {
        return;
      }
    }
    setState(() => _busy = true);
    final Result<ContextState> result = await ref
        .read(contextRepositoryProvider)
        .setLevelValue(
          projectId: widget.projectId,
          fieldKey: widget.level.fieldKey,
          value: value,
          clearBelow: true,
        );
    if (!mounted) {
      return;
    }
    switch (result) {
      case FailureResult<ContextState>(:final Failure failure):
        setState(() {
          _busy = false;
          _error = failure;
        });
      case Success<ContextState>():
        Navigator.of(context).pop();
    }
  }
}
