import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';

import '../domain/field_def.dart';
import '../domain/template_def.dart';
import '../domain/template_row.dart';
import '../templates.dart' show templateRepositoryProvider;

/// Copies fields, predefined rows and row aliases onto a new template.
///
/// Records stay on the original; the copy starts with none.
class TemplateDuplicateAction extends ConsumerWidget {
  /// Creates the action for [template].
  const TemplateDuplicateAction({super.key, required this.template});

  /// Template whose shape is copied.
  final TemplateDef template;

  /// Writes a new row from [source] and returns it, or null on failure.
  static Future<TemplateDef?> apply(WidgetRef ref, TemplateDef source) async {
    final Result<TemplateDef> result = await ref
        .read(templateRepositoryProvider)
        .save(draftFrom(source));
    return switch (result) {
      Success<TemplateDef>(:final TemplateDef value) => value,
      FailureResult<TemplateDef>() => null,
    };
  }

  /// A new unsaved template that reuses [source]'s fields, rows and aliases.
  static TemplateDef draftFrom(TemplateDef source) {
    return TemplateDef(
      id: '',
      templateKey: source.templateKey,
      name: Copy.templateCopyName(source.name),
      version: 1,
      fields: List<FieldDef>.of(source.fields),
      identityFieldKeys: List<String>.of(source.identityFieldKeys),
      rows: <TemplateRow>[
        for (final TemplateRow row in source.rows)
          row.copyWith(aliases: List<String>.of(row.aliases)),
      ],
      projectId: source.projectId,
      kind: source.kind,
      source: source.source,
      sourceFilePath: source.sourceFilePath,
      sheetName: source.sheetName,
      headerRow: source.headerRow,
      detection: Map<String, Object?>.of(source.detection),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppButton(
      label: Copy.projectsDuplicate,
      variant: AppButtonVariant.secondary,
      onPressed: () => apply(ref, template),
    );
  }
}
