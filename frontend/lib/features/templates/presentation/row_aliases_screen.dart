import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/template_def.dart';
import '../domain/template_row.dart';
import '../templates.dart'
    show PredefinedRowsImport, templateRepositoryProvider;
import 'template_list_screen.dart' show templateListProvider;

/// Per-row aliases that teach the matcher local names.
class RowAliasesScreen extends ConsumerWidget {
  /// Creates the aliases screen for [templateId].
  const RowAliasesScreen({super.key, required this.templateId, this.sheetRows});

  /// Template whose checklist rows this screen edits.
  final String templateId;

  /// Spreadsheet grid used to import aliases from a column. Tests pass this.
  final List<List<String>>? sheetRows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TemplateDef?> value = ref
        .watch(templateListProvider)
        .whenData(_pick);
    final _AliasesView view = ref.watch(_rowAliasesProvider(templateId));
    return AppPage(
      key: const ValueKey<String>('route-row-aliases'),
      title: Copy.rowAliasesTitle,
      scrollable: false,
      overflow: value.asData?.value == null || sheetRows == null
          ? const <AppOverflowAction>[]
          : <AppOverflowAction>[
              AppOverflowAction(
                label: Copy.rowAliasesImport,
                icon: AppIcons.columns,
                onTap: () {
                  ref
                      .read(_rowAliasesProvider(templateId).notifier)
                      .promptColumn();
                },
              ),
            ],
      footer: value.asData?.value == null
          ? null
          : AppPrimaryAction(
              label: Copy.save,
              onPressed: () {
                unawaited(
                  ref.read(_rowAliasesProvider(templateId).notifier).commit(),
                );
              },
            ),
      body: AsyncValueView<TemplateDef?>(
        value: value,
        isEmpty: (TemplateDef? row) => row == null || row.rows.isEmpty,
        empty: () => const AppEmptyState(
          icon: AppIcons.aliases,
          headline: Copy.rowAliasesEmptyHeadline,
          message: Copy.rowAliasesEmptyMessage,
        ),
        onRetry: () => ref.invalidate(templateListProvider),
        data: (TemplateDef? row) => _list(ref, row!, view),
      ),
    );
  }

  Widget _list(WidgetRef ref, TemplateDef template, _AliasesView view) {
    final _RowAliases controller = ref.read(
      _rowAliasesProvider(templateId).notifier,
    );
    final int leading =
        (view.saveError != null ? 1 : 0) + (view.importColumn ? 1 : 0);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: Space.x4),
      itemCount: template.rows.length + leading,
      itemBuilder: (BuildContext context, int index) {
        if (view.saveError != null) {
          if (index == 0) {
            return AppBanner(
              message: view.saveError!,
              icon: AppIcons.error,
              tone: SnackTone.error,
            );
          }
          index -= 1;
        }
        if (view.importColumn) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.x4,
                Space.x2,
                Space.x4,
                Space.x2,
              ),
              child: _AliasField(
                key: const ValueKey<String>('alias-column'),
                label: Copy.rowAliasesColumn,
                value: view.column,
                onChanged: controller.setColumn,
                onSubmitted: (_) {
                  controller.importColumn(template, sheetRows: sheetRows);
                },
              ),
            );
          }
          index -= 1;
        }
        final TemplateRow row = template.rows[index];
        final List<String> aliases =
            view.aliases[row.identifier] ?? row.aliases;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppListTile(
              key: ValueKey<String>('alias-${row.identifier}'),
              title: row.label,
              subtitle: Copy.rowAliasesList(aliases),
              selected: view.editing == row.identifier,
              onTap: () => controller.edit(row.identifier),
            ),
            if (view.editing == row.identifier)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.x4,
                  Space.x2,
                  Space.x4,
                  Space.x2,
                ),
                child: _AliasField(
                  key: ValueKey<String>('alias-field-${row.identifier}'),
                  value: aliases.join(', '),
                  onChanged: (String next) {
                    controller.set(row.identifier, next);
                  },
                ),
              ),
          ],
        );
      },
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
}

typedef _AliasesView = ({
  Map<String, List<String>> aliases,
  String? editing,
  String? saveError,
  String column,
  bool importColumn,
  bool dirty,
});

final class _RowAliases extends Notifier<_AliasesView> {
  _RowAliases(this.templateId);

  final String templateId;

  _AliasesView? _held;

  @override
  _AliasesView build() {
    ref.onDispose(() => _held = null);
    final _AliasesView? held = _held;
    if (held != null && held.dirty) {
      return held;
    }
    return (
      aliases: _aliasesOf(_source()),
      editing: null,
      saveError: null,
      column: '',
      importColumn: false,
      dirty: false,
    );
  }

  void edit(String identifier) {
    _set(
      aliases: state.aliases,
      editing: state.editing == identifier ? null : identifier,
      column: state.column,
      importColumn: state.importColumn,
    );
  }

  void set(String identifier, String raw) {
    _set(
      aliases: <String, List<String>>{
        ...state.aliases,
        identifier: _split(raw),
      },
      editing: state.editing,
      column: state.column,
      importColumn: state.importColumn,
    );
  }

  void promptColumn() {
    _set(
      aliases: state.aliases,
      editing: state.editing,
      column: state.column,
      importColumn: true,
    );
  }

  void setColumn(String column) {
    _set(
      aliases: state.aliases,
      editing: state.editing,
      column: column,
      importColumn: true,
    );
  }

  void importColumn(
    TemplateDef template, {
    required List<List<String>>? sheetRows,
  }) {
    if (sheetRows == null || state.column.trim().isEmpty) {
      return;
    }
    final List<TemplateRow> merged = PredefinedRowsImport.mergeAliases(
      rows: template.rows,
      sheet: sheetRows,
      aliasColumn: state.column,
    );
    _set(
      aliases: <String, List<String>>{
        for (final TemplateRow row in merged)
          row.identifier: List<String>.of(row.aliases),
      },
      editing: state.editing,
      column: state.column,
      importColumn: false,
    );
  }

  Future<bool> commit() async {
    final TemplateDef? source = _source();
    if (source == null) {
      const StorageFailure missing = StorageFailure(
        message: Copy.xlsxMappingMissing,
        recoveryAction: Copy.xlsxMappingMissingRecovery,
      );
      state = (
        aliases: state.aliases,
        editing: state.editing,
        saveError: missing.message,
        column: state.column,
        importColumn: state.importColumn,
        dirty: state.dirty,
      );
      _held = state;
      return false;
    }
    final Result<TemplateDef> result = await PredefinedRowsImport(
      ref.read(templateRepositoryProvider),
    ).apply(template: source, rows: _merged(source));
    switch (result) {
      case Success<TemplateDef>():
        state = (
          aliases: state.aliases,
          editing: state.editing,
          saveError: null,
          column: state.column,
          importColumn: false,
          dirty: false,
        );
        _held = state;
        return true;
      case FailureResult<TemplateDef>(:final Failure failure):
        state = (
          aliases: state.aliases,
          editing: state.editing,
          saveError: failure.message,
          column: state.column,
          importColumn: state.importColumn,
          dirty: true,
        );
        _held = state;
        return false;
    }
  }

  void _set({
    required Map<String, List<String>> aliases,
    required String? editing,
    required String column,
    required bool importColumn,
  }) {
    state = (
      aliases: aliases,
      editing: editing,
      saveError: null,
      column: column,
      importColumn: importColumn,
      dirty: true,
    );
    _held = state;
  }

  List<TemplateRow> _merged(TemplateDef template) {
    return <TemplateRow>[
      for (final TemplateRow row in template.rows)
        row.copyWith(aliases: state.aliases[row.identifier] ?? row.aliases),
    ];
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

final _rowAliasesProvider = NotifierProvider.autoDispose
    .family<_RowAliases, _AliasesView, String>(
      _RowAliases.new,
      retry: (int _, Object _) => null,
    );

class _AliasField extends StatefulWidget {
  const _AliasField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.onSubmitted,
  });

  final String value;
  final String? label;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_AliasField> createState() => _AliasFieldState();
}

class _AliasFieldState extends State<_AliasField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(_AliasField oldWidget) {
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
      label: widget.label ?? Copy.rowAliasesField,
      controller: _controller,
      hint: Copy.rowAliasesHint,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}

Map<String, List<String>> _aliasesOf(TemplateDef? template) {
  if (template == null) {
    return <String, List<String>>{};
  }
  return <String, List<String>>{
    for (final TemplateRow row in template.rows)
      row.identifier: List<String>.of(row.aliases),
  };
}

List<String> _split(String raw) {
  return <String>[
    for (final String part in raw.split(RegExp(r'[,;\n]')))
      if (part.trim().isNotEmpty) part.trim(),
  ];
}
