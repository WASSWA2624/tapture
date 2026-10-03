import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/state_refresh.dart';
import 'package:tapture/features/reference/reference.dart';

import '../context.dart' show contextRepositoryProvider;
import '../domain/context_cascade.dart';
import '../domain/context_repository.dart';
import '../domain/context_state.dart';
import 'context_providers.dart';

/// Opens the picker that sets one level. A change that clears lower levels
/// asks once first, naming each of them (spec §20.2).
Future<void> showContextPickerSheet({
  required BuildContext context,
  required String projectId,
  required ContextLevel level,
  required String currentValue,
}) {
  final LocalizedCopy localCopy = Copy.of(context);

  return showAppSheet<void>(
    context,
    title: localCopy.contextPickerTitle(contextLevelName(level)),
    contentSized: true,
    builder: (BuildContext context) {
      return ContextPickerSheet(
        projectId: projectId,
        fieldKey: level.fieldKey,
        label: contextLevelName(level),
        datasetId: level.datasetId,
        currentValue: currentValue,
      );
    },
  );
}

/// Sets one level or pin: its recent values first, then a search of its
/// reference dataset when it has one, then free text.
///
/// Levels and pins share this one picker; a pin passes [write] (and
/// [clearLabel]), a level leaves both null and gets the cascade.
class ContextPickerSheet extends ConsumerStatefulWidget {
  /// Creates the picker body.
  const ContextPickerSheet({
    super.key,
    required this.projectId,
    required this.fieldKey,
    required this.label,
    required this.currentValue,
    this.datasetId,
    this.write,
    this.clearLabel,
  });

  /// Owning project.
  final String projectId;

  /// Level or pinned field being set.
  final String fieldKey;

  /// Its name, operator data (FE-L10N-07).
  final String label;

  /// Current value; choosing it again changes nothing.
  final String currentValue;

  /// Reference dataset searched for values, if any.
  final String? datasetId;

  /// Writes a pin. Null sets [fieldKey] as a level, with the cascade.
  final ContextPickerWrite? write;

  /// Label of the control that clears a set value. Null offers none.
  final String? clearLabel;

  @override
  ConsumerState<ContextPickerSheet> createState() => _ContextPickerSheetState();
}

class _ContextPickerSheetState extends ConsumerState<ContextPickerSheet>
    with StateRefresh {
  late final TextEditingController _text;
  List<String> _recents = const <String>[];
  List<ReferenceRow> _matches = const <ReferenceRow>[];
  Failure? _error;
  bool _busy = false;

  bool get _hasDataset => (widget.datasetId ?? '').isNotEmpty;

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
    final LocalizedCopy localCopy = Copy.of(context);

    final Failure? error = _error;
    final String? clearLabel = widget.clearLabel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.x3,
        Space.x0,
        Space.x3,
        Space.x3,
      ),
      child: AppForm(
        compact: true,
        submitLabel: localCopy.contextUseValue,
        errors: <String>[if (error != null) error.message],
        onSubmit: () => _choose(_text.text),
        fields: <Widget>[
          if (_recents.isNotEmpty) ...<Widget>[
            AppSectionHeader(title: localCopy.contextRecents, dense: true),
            for (final String recent in _recents)
              AppListTile(
                title: recent,
                dense: true,
                current: recent == widget.currentValue,
                onTap: () => unawaited(_choose(recent)),
              ),
          ],
          if (_hasDataset) ...<Widget>[
            AppSectionHeader(
              title: localCopy.contextDatasetSearch,
              dense: true,
            ),
            AppSearchField(
              hint: localCopy.contextDatasetSearch,
              onChanged: (String query) => unawaited(_search(query)),
            ),
            for (final ReferenceRow row in _matches)
              AppListTile(
                title: row.key,
                dense: true,
                current: row.key == widget.currentValue,
                onTap: () => unawaited(_choose(row.key)),
              ),
          ],
          AppTextField(
            label: localCopy.contextTypeValue,
            controller: _text,
            textInputAction: TextInputAction.done,
            onSubmitted: (String value) => unawaited(_choose(value)),
          ),
          if (clearLabel != null && widget.currentValue.isNotEmpty)
            AppButton(
              label: clearLabel,
              variant: AppButtonVariant.text,
              onPressed: _busy ? null : () => unawaited(_commit('')),
            ),
        ],
      ),
    );
  }

  Future<void> _loadRecents() async {
    final Result<List<String>> result = await ref
        .read(contextRepositoryProvider)
        .recentValues(projectId: widget.projectId, fieldKey: widget.fieldKey);
    if (!mounted) {
      return;
    }
    switch (result) {
      case Success<List<String>>(:final List<String> value):
        refresh(() => _recents = value);
      case FailureResult<List<String>>():
        break;
    }
  }

  Future<void> _search(String query) async {
    final String? datasetId = widget.datasetId;
    if (datasetId == null || datasetId.isEmpty || query.trim().isEmpty) {
      refresh(() => _matches = const <ReferenceRow>[]);
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
          matchColumns: <String>[widget.fieldKey, 'name', ''],
        );
        refresh(() {
          _error = null;
          _matches = soft.isEmpty ? value : soft;
        });
      case FailureResult<List<ReferenceRow>>(:final Failure failure):
        refresh(() => _error = failure);
    }
  }

  /// Sets [value]. The current value again is a no-op, so a return visit
  /// is the chip and the recent value: two taps, with no confirmation.
  Future<bool> _choose(String value) async {
    final String trimmed = value.trim();
    if (trimmed.isEmpty || _busy) {
      return false;
    }
    if (trimmed == widget.currentValue) {
      unawaited(Navigator.of(context).maybePop());
      return true;
    }
    return _commit(trimmed);
  }

  Future<bool> _commit(String value) async {
    refresh(() {
      _busy = true;
      _error = null;
    });
    final ContextRepository repo = ref.read(contextRepositoryProvider);
    final ContextPickerWrite? write = widget.write;
    final Result<ContextState>? result = write == null
        ? await _setLevel(repo, value)
        : await write(repo, value);
    if (!mounted) {
      return false;
    }
    switch (result) {
      case null:
        refresh(() => _busy = false);
        return false;
      case FailureResult<ContextState>(:final Failure failure):
        refresh(() {
          _busy = false;
          _error = failure;
        });
        return false;
      case Success<ContextState>():
        unawaited(Navigator.of(context).maybePop());
        return true;
    }
  }

  /// Sets the level, confirming once when filled lower levels would clear.
  /// Null means the operator declined: nothing was written.
  Future<Result<ContextState>?> _setLevel(
    ContextRepository repo,
    String value,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final Result<ContextState> loaded = await repo.load(widget.projectId);
    final ContextState state;
    switch (loaded) {
      case FailureResult<ContextState>():
        return loaded;
      case Success<ContextState>(:final ContextState value):
        state = value;
    }
    final List<String> named = ContextCascade.named(
      ContextCascade.affected(state: state, changedFieldKey: widget.fieldKey),
    );
    if (named.isNotEmpty) {
      if (!mounted) {
        return null;
      }
      final bool ok = await showAppConfirm(
        context,
        title: localCopy.contextCascadeTitle,
        message: localCopy.contextCascadeMessage(
          levelLabel: widget.label,
          newValue: value,
          named: named,
        ),
        confirmLabel: localCopy.contextCascadeConfirm,
      );
      if (!ok) {
        return null;
      }
    }
    return repo.setLevelValue(
      projectId: widget.projectId,
      fieldKey: widget.fieldKey,
      value: value,
    );
  }
}

/// Writes a value the picker chose. An empty value clears it.
typedef ContextPickerWrite =
    Future<Result<ContextState>> Function(ContextRepository repo, String value);
