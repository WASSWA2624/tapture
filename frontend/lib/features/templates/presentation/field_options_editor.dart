import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// Choice list: add, reorder, rename and retire. Rename never changes the code.
class FieldOptionsEditor extends StatefulWidget {
  /// Creates the editor over [options] (`String` or `{code, label}`).
  const FieldOptionsEditor({
    super.key,
    required this.options,
    required this.onChanged,
    this.failure,
  });

  /// Stored options. Retired rows stay so historical codes still resolve.
  final List<Object> options;

  /// Called with the rewritten list after any edit.
  final ValueChanged<List<Object>> onChanged;

  /// Optional failure the parent already knows, for the empty/failure tests.
  final Failure? failure;

  /// Updates [option]'s label only. The stored code is unchanged.
  static Object rename(Object option, String label) {
    final ({String code, String label, bool retired}) parsed = decode(option);
    return encode((code: parsed.code, label: label, retired: parsed.retired));
  }

  /// Marks [option] retired without dropping its code.
  static Object retire(Object option) {
    final ({String code, String label, bool retired}) parsed = decode(option);
    return encode((code: parsed.code, label: parsed.label, retired: true));
  }

  /// Reads a stored option as code, label and retired flag.
  static ({String code, String label, bool retired}) decode(Object option) {
    if (option is String) {
      final String trimmed = option.trim();
      return (code: trimmed, label: trimmed, retired: false);
    }
    if (option is Map) {
      final String? code = option[_code]?.toString();
      final String? label = option[_label]?.toString();
      final bool retired = option[_retired] == true;
      final String resolved = (code ?? label ?? '').trim();
      return (
        code: resolved,
        label: (label ?? code ?? '').trim(),
        retired: retired,
      );
    }
    return (code: '', label: '', retired: false);
  }

  /// Writes a stored option. Retired rows keep an explicit flag.
  static Object encode(({String code, String label, bool retired}) option) {
    return <String, Object?>{
      _code: option.code,
      _label: option.label,
      if (option.retired) _retired: true,
    };
  }

  /// Stable snake_case code from [label], unique against [taken].
  static String codeFrom(String label, Iterable<String> taken) {
    String slug = label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (slug.isEmpty || !RegExp(r'^[a-z]').hasMatch(slug)) {
      slug = slug.isEmpty ? 'choice' : 'choice_$slug';
    }
    if (!taken.contains(slug)) {
      return slug;
    }
    int suffix = 2;
    while (taken.contains('${slug}_$suffix')) {
      suffix += 1;
    }
    return '${slug}_$suffix';
  }

  @override
  State<FieldOptionsEditor> createState() => _FieldOptionsEditorState();
}

class _FieldOptionsEditorState extends State<FieldOptionsEditor> {
  final TextEditingController _label = TextEditingController();
  final Map<String, TextEditingController> _renames =
      <String, TextEditingController>{};

  @override
  void dispose() {
    _label.dispose();
    for (final TextEditingController controller in _renames.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<({String code, String label, bool retired})> rows = widget
        .options
        .map(FieldOptionsEditor.decode)
        .where(
          (({String code, String label, bool retired}) row) =>
              row.code.isNotEmpty,
        )
        .toList();
    final Failure? failure = widget.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppSectionHeader(title: Copy.fieldOptionsTitle, dense: true),
        if (rows.isEmpty)
          const AppEmptyState(
            icon: AppIcons.fields,
            headline: Copy.fieldOptionsEmptyHeadline,
            message: Copy.fieldOptionsEmptyMessage,
          ),
        if (failure != null) AppErrorState(failure: failure),
        for (int index = 0; index < rows.length; index++) _row(rows, index),
        AppTextField(
          label: Copy.fieldOptionLabel,
          controller: _label,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _add(rows),
        ),
        AppButton(
          label: Copy.fieldOptionAdd,
          variant: AppButtonVariant.secondary,
          onPressed: () => _add(rows),
        ),
      ],
    );
  }

  Widget _row(
    List<({String code, String label, bool retired})> rows,
    int index,
  ) {
    final ({String code, String label, bool retired}) row = rows[index];
    final TextEditingController rename = _renames.putIfAbsent(
      row.code,
      () => TextEditingController(text: row.label),
    );
    return Column(
      children: <Widget>[
        AppListTile(
          title: row.label,
          subtitle: row.code,
          dense: true,
          status: row.retired
              ? const AppStatusPill.badge(
                  status: RecordStatus.archived,
                  label: Copy.fieldOptionRetired,
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppIconButton(
                icon: AppIcons.moveUp,
                semanticLabel: Copy.fieldMoveUp(row.label),
                tooltip: Copy.fieldMoveUp(row.label),
                outlined: false,
                onPressed: index == 0
                    ? null
                    : () => _move(rows, index, index - 1),
              ),
              AppIconButton(
                icon: AppIcons.moveDown,
                semanticLabel: Copy.fieldMoveDown(row.label),
                tooltip: Copy.fieldMoveDown(row.label),
                outlined: false,
                onPressed: index == rows.length - 1
                    ? null
                    : () => _move(rows, index, index + 1),
              ),
              if (!row.retired)
                AppIconButton(
                  icon: AppIcons.hideOption,
                  semanticLabel: Copy.fieldOptionRetire,
                  tooltip: Copy.fieldOptionRetire,
                  outlined: false,
                  onPressed: () => _emit(<Object>[
                    for (int i = 0; i < rows.length; i++)
                      i == index
                          ? FieldOptionsEditor.retire(widget.options[i])
                          : widget.options[i],
                  ]),
                ),
            ],
          ),
        ),
        AppTextField(
          label: Copy.fieldOptionLabel,
          controller: rename,
          onChanged: (String label) {
            _emit(<Object>[
              for (int i = 0; i < rows.length; i++)
                i == index
                    ? FieldOptionsEditor.rename(widget.options[i], label)
                    : widget.options[i],
            ]);
          },
        ),
      ],
    );
  }

  void _add(List<({String code, String label, bool retired})> rows) {
    final String label = _label.text.trim();
    if (label.isEmpty) {
      return;
    }
    final String code = FieldOptionsEditor.codeFrom(
      label,
      rows.map((({String code, String label, bool retired}) row) => row.code),
    );
    _label.clear();
    _emit(<Object>[
      ...widget.options,
      FieldOptionsEditor.encode((code: code, label: label, retired: false)),
    ]);
  }

  void _move(
    List<({String code, String label, bool retired})> rows,
    int from,
    int to,
  ) {
    final List<Object> next = List<Object>.of(widget.options);
    final Object option = next.removeAt(from);
    next.insert(to, option);
    _emit(next);
  }

  void _emit(List<Object> options) {
    widget.onChanged(options);
  }
}

const String _code = 'code';
const String _label = 'label';
const String _retired = 'retired';
