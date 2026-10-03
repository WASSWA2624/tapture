import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

import '../domain/field_def.dart';

/// The new-template page's field rows: each asks the add sheet's three
/// questions (label, type, required), and Add a field adds another
/// (FE-SIMP-06, FBK0000144).
class TemplateFieldRows extends StatelessWidget {
  /// Creates the rows for [drafts].
  const TemplateFieldRows({
    required this.drafts,
    required this.labelFor,
    required this.onType,
    required this.onRequiredness,
    required this.onRemove,
    required this.onAdd,
    this.onLabelChanged,
    super.key,
  });

  /// Rows in order.
  final List<TemplateFieldDraft> drafts;

  /// The label controller the page holds for a row id.
  final TextEditingController Function(int id) labelFor;

  /// Changes a row's type.
  final void Function(int id, FieldType type) onType;

  /// Changes a row's requiredness.
  final void Function(int id, Requiredness requiredness) onRequiredness;

  /// Removes a row.
  final ValueChanged<int> onRemove;

  /// Adds an empty row at the end.
  final VoidCallback onAdd;

  /// Called as a label is typed.
  final ValueChanged<String>? onLabelChanged;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int index = 0; index < drafts.length; index++) ...<Widget>[
          AppSectionHeader(
            key: ValueKey<String>('template-field-row-${drafts[index].id}'),
            title: localCopy.templateFieldRowTitle(index + 1),
            action: AppIconButton(
              icon: AppIcons.remove,
              tooltip: localCopy.templateFieldRowRemove,
              semanticLabel: localCopy.templateFieldRowRemove,
              outlined: false,
              onPressed: () => onRemove(drafts[index].id),
            ),
          ),
          AppTextField(
            label: localCopy.fieldLabel,
            controller: labelFor(drafts[index].id),
            textInputAction: TextInputAction.next,
            onChanged: onLabelChanged,
          ),
          const SizedBox(height: Space.x3),
          AppChoiceField<FieldType>(
            label: localCopy.fieldType,
            value: drafts[index].type,
            options: <Choice<FieldType>>[
              for (final FieldType type in FieldType.values)
                Choice<FieldType>(type, localCopy.fieldTypeLabel(type.name)),
            ],
            onChanged: (FieldType? type) {
              if (type != null) {
                onType(drafts[index].id, type);
              }
            },
          ),
          const SizedBox(height: Space.x3),
          AppRadioGroup<Requiredness>(
            label: localCopy.fieldRequiredness,
            value: drafts[index].requiredness,
            direction: Axis.horizontal,
            options: <Choice<Requiredness>>[
              Choice<Requiredness>(
                Requiredness.required,
                localCopy.fieldRequired,
              ),
              Choice<Requiredness>(
                Requiredness.recommended,
                localCopy.fieldRecommended,
              ),
              Choice<Requiredness>(
                Requiredness.optional,
                localCopy.fieldOptional,
              ),
            ],
            onChanged: (Requiredness value) =>
                onRequiredness(drafts[index].id, value),
          ),
          const SizedBox(height: Space.x4),
        ],
        AppButton(
          label: localCopy.templatesAddField,
          icon: AppIcons.add,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

/// One field being drafted on the new-template page. [id] only tells rows
/// apart; the stored key comes from the label on Create.
typedef TemplateFieldDraft = ({
  int id,
  FieldType type,
  Requiredness requiredness,
});
