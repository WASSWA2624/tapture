import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/normalise/search_text.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/state_refresh.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/templates/templates.dart';

import '../domain/auto_fields.dart';
import 'inline_fields_section.dart';

/// Sheet-owned search and pending edits for one pinned Capture shape.
final class CaptureManualForm extends StatefulWidget {
  /// Creates a form. The owner keys it by session, template and pinned version.
  const CaptureManualForm({
    required this.fields,
    required this.values,
    required this.onChanged,
    this.onLookup,
    this.onScan,
    this.linkedFields = const <String>{},
    this.automaticValues = const <String, Object?>{},
    this.valueSources = const <String, String>{},
    super.key,
  });

  /// Fields in their original template order.
  final List<FieldDef> fields;

  /// Latest durable values, including inherited context.
  final Map<String, Object?> values;

  /// First-save previews, separate from durable values and acknowledgments.
  final Map<String, Object?> automaticValues;

  /// Actual durable provenance; an explicit clear retains its typed source.
  final Map<String, String> valueSources;

  /// Persists an edit before returning success.
  final Future<Result<void>> Function(String fieldKey, Object? value) onChanged;

  /// Existing reference lookup action.
  final ValueChanged<FieldDef>? onLookup;

  /// Existing barcode intake action.
  final ValueChanged<FieldDef>? onScan;

  /// Fields with retained lookup provenance.
  final Set<String> linkedFields;

  @override
  State<CaptureManualForm> createState() => _CaptureManualFormState();
}

final class _CaptureManualFormState extends State<CaptureManualForm>
    with StateRefresh {
  final Map<String, _PendingEdit> _pending = <String, _PendingEdit>{};
  final Set<String> _correcting = <String>{};
  final ScrollController _scroll = ScrollController();
  Future<void> _writes = Future<void>.value();
  String _query = '';
  bool _moreOpen = false;
  int _revision = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CaptureManualForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pending.removeWhere(
      (String key, _PendingEdit edit) =>
          edit.committed &&
          widget.values.containsKey(key) &&
          _matches(key, widget.values[key], edit.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);
    final List<FieldDef> visible = widget.fields
        .where((FieldDef field) => !field.hidden)
        .toList();
    final String query = foldSearchText(_query.trim());
    final List<FieldDef> matching = query.isEmpty
        ? visible
        : visible
              .where(
                (FieldDef field) =>
                    foldSearchText(field.label).contains(query) ||
                    foldSearchText(field.fieldKey).contains(query),
              )
              .toList();
    final List<FieldDef> primary = matching
        .where((FieldDef field) => query.isNotEmpty || _primary(field))
        .toList();
    final List<FieldDef> optional = query.isNotEmpty
        ? const <FieldDef>[]
        : visible.where((FieldDef field) => !_primary(field)).toList();
    return CustomScrollView(
      key: const ValueKey<String>('capture-manual-form-scroll'),
      controller: _scroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.all(Space.x3),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: <Widget>[
                AppSearchField(
                  key: const ValueKey<String>('capture-field-search'),
                  hint: localCopy.captureSearchFields,
                  text: _query,
                  resultCount: query.isEmpty ? null : matching.length,
                  onChanged: _search,
                ),
                if (query.isNotEmpty)
                  Semantics(
                    liveRegion: true,
                    label: localCopy.fieldsCount(matching.length),
                    child: const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        ),
        if (query.isNotEmpty && matching.isEmpty)
          SliverToBoxAdapter(
            child: AppEmptyState(
              icon: AppIcons.searchEmpty,
              headline: localCopy.fieldsNoMatch,
              message: localCopy.searchNoMatchMessage,
            ),
          ),
        _rows(primary),
        if (optional.isNotEmpty) ...<Widget>[
          SliverToBoxAdapter(
            child: TextButton(
              onPressed: () => refresh(() => _moreOpen = !_moreOpen),
              child: Text(localCopy.captureMoreFields),
            ),
          ),
          if (_moreOpen) _rows(optional),
        ],
      ],
    );
  }

  Widget _rows(List<FieldDef> fields) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: Space.x3),
    sliver: SliverList.builder(
      itemCount: fields.length,
      itemBuilder: (BuildContext context, int index) {
        final FieldDef field = fields[index];
        final _PendingEdit? pending = _pending[field.fieldKey];
        final bool durable = widget.values.containsKey(field.fieldKey);
        final bool preview = pending == null && !durable;
        return Column(
          key: ValueKey<String>('manual-row-${field.fieldKey}'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            InlineFieldsSection(
              fields: <FieldDef>[field],
              showAll: true,
              values: <String, Object?>{
                field.fieldKey: pending == null
                    ? durable
                          ? widget.values[field.fieldKey]
                          : widget.automaticValues[field.fieldKey]
                    : pending.value,
              },
              valueSources: <String, String>{
                if (pending != null || durable)
                  field.fieldKey: pending != null
                      ? 'TYPED'
                      : widget.valueSources[field.fieldKey] ?? 'TYPED',
                if (preview &&
                    widget.automaticValues.containsKey(field.fieldKey))
                  field.fieldKey:
                      AutoFields.effectiveSource(field) == AutoFill.context
                      ? 'CONTEXT'
                      : 'AUTO',
              },
              previewKeys: preview
                  ? <String>{field.fieldKey}
                  : const <String>{},
              correctingKeys: _correcting,
              onCorrect: (String key) => refresh(() => _correcting.add(key)),
              onChanged: _edit,
              onLookup: widget.onLookup,
              onScan: widget.onScan,
              linkedFields: widget.linkedFields,
            ),
            if (pending?.failure case final Failure failure)
              AppErrorState(
                failure: failure,
                onRetry: () => _edit(field.fieldKey, pending!.value),
              ),
          ],
        );
      },
    ),
  );

  void _search(String value) {
    refresh(() => _query = value);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _edit(String fieldKey, Object? value) {
    final int revision = ++_revision;
    refresh(() => _pending[fieldKey] = _PendingEdit(value, revision));
    // The controller rebases writes when they complete. Serializing keeps a
    // slower earlier edit from overwriting the latest typed value.
    _writes = _writes.then((_) => _write(fieldKey, value, revision));
    unawaited(_writes);
  }

  Future<void> _write(String fieldKey, Object? value, int revision) async {
    if (!mounted) return;
    final Result<void> result = await widget.onChanged(fieldKey, value);
    if (!mounted || _pending[fieldKey]?.revision != revision) return;
    refresh(() {
      switch (result) {
        case FailureResult<void>(:final Failure failure):
          _pending[fieldKey] = _PendingEdit(value, revision, failure: failure);
        case Success<void>():
          if (widget.values.containsKey(fieldKey) &&
              _matches(fieldKey, widget.values[fieldKey], value)) {
            _pending.remove(fieldKey);
          } else {
            _pending[fieldKey] = _PendingEdit(value, revision, committed: true);
          }
      }
    });
  }

  static bool _primary(FieldDef field) =>
      field.identity || field.requiredness == Requiredness.required;

  bool _matches(String key, Object? durable, Object? pending) {
    final FieldDef? field = widget.fields
        .where((FieldDef field) => field.fieldKey == key)
        .firstOrNull;
    return field == null
        ? durable == pending
        : storedTextOf(field.type, durable) ==
              storedTextOf(field.type, pending);
  }
}

final class _PendingEdit {
  const _PendingEdit(
    this.value,
    this.revision, {
    this.failure,
    this.committed = false,
  });

  final Object? value;
  final int revision;
  final Failure? failure;
  final bool committed;
}
