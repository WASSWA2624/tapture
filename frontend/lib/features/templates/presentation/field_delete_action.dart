import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import '../domain/template_repository.dart';

/// Removes a field from a template and retires captured values.
///
/// The field leaves the list. Values stay on their records and export
/// with `retired` set, so a delete never destroys evidence (§18).
final class FieldDeleteAction {
  /// Warns with the value count, then writes [retire] when confirmed.
  static Future<Result<TemplateDef>?> confirmAndApply({
    required BuildContext context,
    required TemplateRepository templates,
    required TemplateDef template,
    required FieldDef field,
    required int valueCount,
  }) async {
    final bool confirmed = await showAppConfirm(
      context,
      title: Copy.templatesDeleteFieldTitle(field.label),
      message: Copy.templatesDeleteFieldMessage(values: valueCount),
      confirmLabel: Copy.templatesDeleteField,
      destructive: true,
    );
    if (!confirmed) {
      return null;
    }
    return apply(
      templates: templates,
      template: template,
      fieldKey: field.fieldKey,
    );
  }

  /// Drops [fieldKey] and bumps the version. Stored values are untouched.
  static Future<Result<TemplateDef>> apply({
    required TemplateRepository templates,
    required TemplateDef template,
    required String fieldKey,
  }) {
    return templates.save(
      retire(template, fieldKey).copyWith(version: template.version + 1),
    );
  }

  /// Template without [fieldKey], identity key included.
  static TemplateDef retire(TemplateDef template, String fieldKey) {
    return template.copyWith(
      fields: <FieldDef>[
        for (final FieldDef field in template.fields)
          if (field.fieldKey != fieldKey) field,
      ],
      identityFieldKeys: <String>[
        for (final String key in template.identityFieldKeys)
          if (key != fieldKey) key,
      ],
    );
  }

  /// JSON rows for export. Values whose key is not live are marked retired.
  static List<Map<String, Object?>> exportValues({
    required Iterable<String> liveFieldKeys,
    required Iterable<({String fieldKey, String? value})> values,
  }) {
    final Set<String> live = liveFieldKeys.toSet();
    return <Map<String, Object?>>[
      for (final ({String fieldKey, String? value}) row in values)
        <String, Object?>{
          _fieldKey: row.fieldKey,
          _value: row.value,
          if (!live.contains(row.fieldKey)) _retired: true,
        },
    ];
  }
}

const String _fieldKey = 'field_key';
const String _value = 'value';
const String _retired = 'retired';
