import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_multi_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

import '../domain/template_def.dart';

/// The template kinds the template list is narrowed to. Empty lists every
/// kind. Ephemeral, like the list's query (FE-STATE-02).
final class TemplateListFilter extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  /// Lists only templates of [kinds].
  void set(Set<String> kinds) => state = Set<String>.unmodifiable(kinds);

  /// Lists every kind again.
  void clear() => state = const <String>{};

  /// Whether [template] is listed under [kinds]. A template without a kind
  /// is listed under the empty kind.
  static bool matches(TemplateDef template, Set<String> kinds) {
    return kinds.isEmpty || kinds.contains(template.kind.trim());
  }
}

/// The chosen template kinds (FE-STATE-02).
final NotifierProvider<TemplateListFilter, Set<String>>
templateListFilterProvider = NotifierProvider<TemplateListFilter, Set<String>>(
  TemplateListFilter.new,
  retry: (int _, Object _) => null,
);

/// Opens the template list's filters over the kinds [templates] carry.
Future<void> showTemplateListFilters(
  BuildContext context,
  WidgetRef ref,
  List<TemplateDef> templates,
) {
  final List<String> kinds = <String>{
    for (final TemplateDef template in templates) template.kind.trim(),
  }.toList()..sort();
  return showAppFilterSheet(
    context,
    title: Copy.templateFiltersTitle,
    onClear: ref.read(templateListFilterProvider.notifier).clear,
    facets: (BuildContext _) => _KindFacet(kinds: kinds),
  );
}

class _KindFacet extends ConsumerWidget {
  const _KindFacet({required this.kinds});

  final List<String> kinds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppMultiChoiceField<String>(
      key: const ValueKey<String>('template-kind-filter'),
      label: Copy.templateKindFilter,
      // Kinds are template content and are shown as stored (FE-L10N-07).
      options: <Choice<String>>[
        for (final String kind in kinds)
          Choice<String>(kind, kind.isEmpty ? Copy.templateKindNone : kind),
      ],
      value: ref.watch(templateListFilterProvider),
      onChanged: ref.read(templateListFilterProvider.notifier).set,
    );
  }
}
