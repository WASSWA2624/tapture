import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_multi_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

import '../domain/field_def.dart';

/// The requiredness values and field types a template's field list is
/// narrowed to. An empty set leaves that facet open. Ephemeral, like the
/// list's query (FE-STATE-02).
final class FieldListFilter extends Notifier<FieldListFacets> {
  @override
  FieldListFacets build() => _open;

  /// Lists only fields of [values].
  void setRequiredness(Set<Requiredness> values) {
    state = (
      requiredness: Set<Requiredness>.unmodifiable(values),
      types: state.types,
    );
  }

  /// Lists only fields of [types].
  void setTypes(Set<FieldType> types) {
    state = (
      requiredness: state.requiredness,
      types: Set<FieldType>.unmodifiable(types),
    );
  }

  /// Lists every field again.
  void clear() => state = _open;

  /// How many values are chosen across both facets.
  static int activeCount(FieldListFacets facets) {
    return facets.requiredness.length + facets.types.length;
  }

  /// Whether [field] is listed under [facets]: each facet with a choice
  /// must hold the field's value.
  static bool matches(FieldDef field, FieldListFacets facets) {
    return (facets.requiredness.isEmpty ||
            facets.requiredness.contains(field.requiredness)) &&
        (facets.types.isEmpty || facets.types.contains(field.type));
  }
}

/// The field list's chosen requiredness values and types.
typedef FieldListFacets = ({
  Set<Requiredness> requiredness,
  Set<FieldType> types,
});

const FieldListFacets _open = (
  requiredness: <Requiredness>{},
  types: <FieldType>{},
);

/// The chosen facets (FE-STATE-02).
final NotifierProvider<FieldListFilter, FieldListFacets>
fieldListFilterProvider = NotifierProvider<FieldListFilter, FieldListFacets>(
  FieldListFilter.new,
  retry: (int _, Object _) => null,
);

/// Opens the field list's filters: requiredness, then the types [fields]
/// use.
Future<void> showFieldListFilters(
  BuildContext context,
  WidgetRef ref,
  List<FieldDef> fields,
) {
  final Set<FieldType> present = <FieldType>{
    for (final FieldDef field in fields) field.type,
  };
  final List<FieldType> types = <FieldType>[
    for (final FieldType type in FieldType.values)
      if (present.contains(type)) type,
  ];
  return showAppFilterSheet(
    context,
    title: Copy.fieldFiltersTitle,
    onClear: ref.read(fieldListFilterProvider.notifier).clear,
    facets: (BuildContext _) => _FieldFacets(types: types),
  );
}

class _FieldFacets extends ConsumerWidget {
  const _FieldFacets({required this.types});

  final List<FieldType> types;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FieldListFacets facets = ref.watch(fieldListFilterProvider);
    final FieldListFilter filter = ref.read(fieldListFilterProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppMultiChoiceField<Requiredness>(
          key: const ValueKey<String>('field-requiredness-filter'),
          label: Copy.fieldRequirednessFilter,
          options: const <Choice<Requiredness>>[
            Choice<Requiredness>(Requiredness.required, Copy.fieldRequired),
            Choice<Requiredness>(
              Requiredness.recommended,
              Copy.fieldRecommended,
            ),
            Choice<Requiredness>(Requiredness.optional, Copy.fieldOptional),
          ],
          value: facets.requiredness,
          onChanged: filter.setRequiredness,
        ),
        const SizedBox(height: Space.x3),
        AppMultiChoiceField<FieldType>(
          key: const ValueKey<String>('field-type-filter'),
          label: Copy.fieldType,
          options: <Choice<FieldType>>[
            for (final FieldType type in types)
              Choice<FieldType>(type, Copy.fieldTypeLabel(type.name)),
          ],
          value: facets.types,
          onChanged: filter.setTypes,
        ),
      ],
    );
  }
}
