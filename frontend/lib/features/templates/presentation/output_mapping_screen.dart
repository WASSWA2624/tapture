import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/field_def.dart';
import '../domain/template_def.dart';
import '../templates.dart' show templateRepositoryProvider;
import 'template_list_screen.dart' show templateListProvider;
import 'template_locations.dart';

/// Spreadsheet column or generated header for each field (§18).
class OutputMappingScreen extends ConsumerWidget {
  /// Creates the screen for [templateId].
  const OutputMappingScreen({super.key, required this.templateId});

  /// Template whose output columns this screen edits.
  final String templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TemplateDef?> value = ref
        .watch(templateListProvider)
        .whenData(_pick);
    final _OutputView view = ref.watch(_outputMappingProvider(templateId));
    return AppPage(
      key: const ValueKey<String>('route-template-output'),
      title: Copy.outputMappingTitle,
      scrollable: false,
      footer: value.asData?.value == null
          ? null
          : AppPrimaryAction(
              label: Copy.save,
              onPressed: () => _commit(context, ref),
            ),
      body: AsyncValueView<TemplateDef?>(
        value: value,
        isEmpty: (TemplateDef? row) => row == null || row.fields.isEmpty,
        empty: () => const AppEmptyState(
          icon: AppIcons.columns,
          headline: Copy.outputMappingEmptyHeadline,
          message: Copy.outputMappingEmptyMessage,
        ),
        onRetry: () => ref.invalidate(templateListProvider),
        data: (TemplateDef? row) => _list(ref, row!, view),
      ),
    );
  }

  Widget _list(WidgetRef ref, TemplateDef template, _OutputView view) {
    return ListView(
      padding: const EdgeInsets.only(bottom: Space.x4),
      children: <Widget>[
        AppBanner(
          message: view.imported
              ? Copy.outputMappingImportedHint
              : Copy.outputMappingBuiltHint,
          icon: AppIcons.info,
          tone: SnackTone.info,
        ),
        if (view.saveError != null)
          AppBanner(
            message: view.saveError!,
            icon: AppIcons.error,
            tone: SnackTone.error,
          ),
        for (final FieldDef field in template.fields)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.x4, 0),
            child: _OutputColumnField(
              key: ValueKey<String>('output-${field.fieldKey}'),
              label: field.label,
              value: view.columns[field.fieldKey] ?? '',
              onChanged: (String next) {
                ref
                    .read(_outputMappingProvider(templateId).notifier)
                    .set(field.fieldKey, next);
              },
            ),
          ),
      ],
    );
  }

  TemplateDef? _pick(List<TemplateDef> rows) {
    for (final TemplateDef row in rows) {
      if (row.id == templateId) {
        return row;
      }
    }
    return null;
  }

  Future<void> _commit(BuildContext context, WidgetRef ref) async {
    final bool saved = await ref
        .read(_outputMappingProvider(templateId).notifier)
        .commit();
    if (saved && context.mounted) {
      GoRouter.maybeOf(
        context,
      )?.go(TemplateLocations.detail(context, templateId));
    }
  }
}

/// The first column claimed by two fields, or null when every claim is unique.
String? duplicateOutputColumn(Iterable<String?> columns) {
  final Set<String> seen = <String>{};
  for (final String? raw in columns) {
    final String folded = (raw ?? '').trim().toLowerCase();
    if (folded.isEmpty) {
      continue;
    }
    if (!seen.add(folded)) {
      return raw!.trim();
    }
  }
  return null;
}

typedef _OutputView = ({
  Map<String, String> columns,
  String? saveError,
  bool imported,
  bool dirty,
});

final class _OutputMapping extends Notifier<_OutputView> {
  _OutputMapping(this.templateId);

  final String templateId;

  _OutputView? _held;

  @override
  _OutputView build() {
    ref.onDispose(() => _held = null);
    final List<TemplateDef> rows =
        ref.watch(templateListProvider).asData?.value ?? const <TemplateDef>[];
    final _OutputView? held = _held;
    if (held != null && held.dirty) {
      return held;
    }
    for (final TemplateDef row in rows) {
      if (row.id == templateId) {
        return (
          columns: _columnsOf(row),
          saveError: null,
          imported: row.source == _importedSource,
          dirty: false,
        );
      }
    }
    return (
      columns: <String, String>{},
      saveError: null,
      imported: false,
      dirty: false,
    );
  }

  void set(String fieldKey, String column) {
    state = (
      columns: <String, String>{...state.columns, fieldKey: column},
      saveError: null,
      imported: state.imported,
      dirty: true,
    );
    _held = state;
  }

  Future<bool> commit() async {
    final TemplateDef? source = _source();
    if (source == null) {
      const StorageFailure missing = StorageFailure(
        message: 'That template is no longer on this device.',
        recoveryAction: 'Open the template list and try again.',
      );
      state = (
        columns: state.columns,
        saveError: missing.message,
        imported: state.imported,
        dirty: state.dirty,
      );
      _held = state;
      return false;
    }
    if (duplicateOutputColumn(state.columns.values) != null) {
      state = (
        columns: state.columns,
        saveError: Copy.outputMappingDuplicate,
        imported: state.imported,
        dirty: true,
      );
      _held = state;
      return false;
    }
    final Result<TemplateDef> result = await ref
        .read(templateRepositoryProvider)
        .save(_write(source, state.columns));
    switch (result) {
      case Success<TemplateDef>():
        _held = null;
        state = (
          columns: _columnsOf(result.value),
          saveError: null,
          imported: result.value.source == _importedSource,
          dirty: false,
        );
        return true;
      case FailureResult<TemplateDef>(:final Failure failure):
        state = (
          columns: state.columns,
          saveError: failure.message,
          imported: state.imported,
          dirty: true,
        );
        _held = state;
        return false;
    }
  }

  TemplateDef? _source() {
    final List<TemplateDef> rows =
        ref.read(templateListProvider).asData?.value ?? const <TemplateDef>[];
    for (final TemplateDef row in rows) {
      if (row.id == templateId) {
        return row;
      }
    }
    return null;
  }
}

final _outputMappingProvider = NotifierProvider.autoDispose
    .family<_OutputMapping, _OutputView, String>(
      _OutputMapping.new,
      retry: (int _, Object _) => null,
    );

class _OutputColumnField extends StatefulWidget {
  const _OutputColumnField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_OutputColumnField> createState() => _OutputColumnFieldState();
}

class _OutputColumnFieldState extends State<_OutputColumnField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(_OutputColumnField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.value = TextEditingValue(text: widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      controller: _controller,
      onChanged: widget.onChanged,
    );
  }
}

Map<String, String> _columnsOf(TemplateDef template) {
  final Map<String, String> claimed = <String, String>{
    for (final FieldDef field in template.fields)
      if (_filled(field.outputColumn))
        field.fieldKey: field.outputColumn!.trim(),
  };
  if (template.source == _importedSource) {
    return <String, String>{
      for (final FieldDef field in template.fields)
        field.fieldKey: claimed[field.fieldKey] ?? '',
    };
  }
  final Set<String> taken = <String>{
    for (final String column in claimed.values) column.toLowerCase(),
  };
  return <String, String>{
    for (final FieldDef field in template.fields)
      field.fieldKey: claimed[field.fieldKey] ?? _headerFor(field, taken),
  };
}

String _headerFor(FieldDef field, Set<String> taken) {
  final String base = field.label.trim().isEmpty
      ? field.fieldKey
      : field.label.trim();
  final String chosen = _unique(base, field.fieldKey, taken);
  taken.add(chosen.toLowerCase());
  return chosen;
}

String _unique(String base, String fallback, Set<String> taken) {
  if (!taken.contains(base.toLowerCase())) {
    return base;
  }
  if (!taken.contains(fallback.toLowerCase())) {
    return fallback;
  }
  int index = 2;
  while (taken.contains('$base $index'.toLowerCase())) {
    index += 1;
  }
  return '$base $index';
}

bool _filled(String? column) {
  return column != null && column.trim().isNotEmpty;
}

TemplateDef _write(TemplateDef template, Map<String, String> columns) {
  return template.copyWith(
    fields: <FieldDef>[
      for (final FieldDef field in template.fields)
        field.copyWith(outputColumn: (columns[field.fieldKey] ?? '').trim()),
    ],
  );
}

const String _importedSource = 'imported';
