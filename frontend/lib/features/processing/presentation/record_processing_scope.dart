import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/features/templates/templates.dart'
    show FieldDef, FieldInputPolicy;

import 'processing_field_selection.dart';

/// Offers all, selected or a single template field using shared controls.
final class RecordProcessingScope extends ConsumerWidget {
  /// An empty returned scope means all eligible fields; dismissing means cancel.
  const RecordProcessingScope({
    required this.recordId,
    required this.fields,
    required this.onSelected,
    super.key,
  });

  /// The record whose next processing job owns this scope.
  final String recordId;

  /// The authoritative captured template's fields.
  final List<FieldDef> fields;

  /// Returns the selected stable field keys.
  final ValueChanged<List<String>> onSelected;

  /// Opens the shared scrollable sheet; field values are never changed here.
  static Future<List<String>?> show(
    BuildContext context, {
    required String recordId,
    required List<FieldDef> fields,
  }) => showAppSheet<List<String>>(
    context,
    title: Copy.of(context).reviewReanalyse,
    contentSized: true,
    builder: (BuildContext sheetContext) => RecordProcessingScope(
      recordId: recordId,
      fields: fields,
      onSelected: (List<String> keys) => Navigator.of(sheetContext).pop(keys),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy copy = Copy.of(context);
    final Set<String> selected = ref.watch(
      processingFieldSelectionProvider(recordId),
    );
    final List<FieldDef> eligible = fields
        .where(FieldInputPolicy.canExtract)
        .toList();
    final List<String> keys = <String>[
      for (final FieldDef field in eligible)
        if (selected.contains(field.fieldKey)) field.fieldKey,
    ];
    return Padding(
      padding: const EdgeInsets.all(Space.x3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(copy.processingScopeHelp),
          const SizedBox(height: Space.x3),
          AppButton(
            key: const ValueKey<String>('processing-all-fields'),
            label: copy.processingAllFields,
            expand: true,
            onPressed: () => onSelected(const <String>[]),
          ),
          const SizedBox(height: Space.x2),
          for (final FieldDef field in eligible)
            AppSwitchTile.checkbox(
              key: ValueKey<String>('processing-scope-${field.fieldKey}'),
              title: field.label,
              value: selected.contains(field.fieldKey),
              controlFirst: true,
              onChanged: (_) => ref
                  .read(processingFieldSelectionProvider(recordId).notifier)
                  .toggle(field.fieldKey),
            ),
          const SizedBox(height: Space.x3),
          AppButton(
            key: const ValueKey<String>('processing-selected-fields'),
            label: copy.processingSelectedFields,
            expand: true,
            variant: AppButtonVariant.secondary,
            onPressed: keys.isEmpty ? null : () => onSelected(keys),
          ),
        ],
      ),
    );
  }
}
