import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_multi_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

import '../domain/shipped_template_entry.dart';

/// Area of a starter template in the area facet. Catalogue areas use their
/// supergroup code, which is never empty.
const String starterArea = '';

/// Tier a starter template counts under: the §13.4 library is the
/// foundation every project starts from.
const String starterTier = 'p0';

/// The shipped library's facets: area, record type and tier.
final class ShippedLibraryFilter extends Notifier<ShippedLibraryFilterState> {
  @override
  ShippedLibraryFilterState build() => _none;

  /// Lists only templates in [areas].
  void setAreas(Set<String> areas) {
    state = (
      areas: Set<String>.unmodifiable(areas),
      recordTypes: state.recordTypes,
      tiers: state.tiers,
    );
  }

  /// Lists only templates of [recordTypes].
  void setRecordTypes(Set<String> recordTypes) {
    state = (
      areas: state.areas,
      recordTypes: Set<String>.unmodifiable(recordTypes),
      tiers: state.tiers,
    );
  }

  /// Lists only templates in [tiers].
  void setTiers(Set<String> tiers) {
    state = (
      areas: state.areas,
      recordTypes: state.recordTypes,
      tiers: Set<String>.unmodifiable(tiers),
    );
  }

  /// Lists every template again.
  void clear() => state = _none;

  /// How many facets narrow the list, for the filter button's badge.
  static int activeCount(ShippedLibraryFilterState filter) {
    return <Set<String>>[
      filter.areas,
      filter.recordTypes,
      filter.tiers,
    ].where((Set<String> facet) => facet.isNotEmpty).length;
  }

  /// Whether [entry] is listed under [filter]. A starter template has no
  /// record type, so any record-type choice leaves it out.
  static bool matches(
    ShippedTemplateEntry entry,
    ShippedLibraryFilterState filter,
  ) {
    return (filter.areas.isEmpty || filter.areas.contains(areaOf(entry))) &&
        (filter.recordTypes.isEmpty ||
            filter.recordTypes.contains(entry.recordType?.code)) &&
        (filter.tiers.isEmpty || filter.tiers.contains(tierOf(entry)));
  }

  /// The area facet value of [entry].
  static String areaOf(ShippedTemplateEntry entry) {
    return entry.category?.supergroupCode ?? starterArea;
  }

  /// The tier facet value of [entry].
  static String tierOf(ShippedTemplateEntry entry) {
    return entry.isStarter ? starterTier : entry.rollout;
  }
}

/// What the shipped library is narrowed to. An empty set lists every value
/// of that facet. Ephemeral, like the library's query (FE-STATE-02).
typedef ShippedLibraryFilterState = ({
  Set<String> areas,
  Set<String> recordTypes,
  Set<String> tiers,
});

const ShippedLibraryFilterState _none = (
  areas: <String>{},
  recordTypes: <String>{},
  tiers: <String>{},
);

/// The chosen facets (FE-STATE-02).
final NotifierProvider<ShippedLibraryFilter, ShippedLibraryFilterState>
shippedLibraryFilterProvider =
    NotifierProvider<ShippedLibraryFilter, ShippedLibraryFilterState>(
      ShippedLibraryFilter.new,
      retry: (int _, Object _) => null,
    );

/// Opens the shipped library's filters over the values [entries] carry.
Future<void> showShippedLibraryFilters(
  BuildContext context,
  WidgetRef ref,
  List<ShippedTemplateEntry> entries,
) {
  final Map<String, String> areas = <String, String>{};
  final Map<String, String> recordTypes = <String, String>{};
  final Set<String> tiers = <String>{};
  for (final ShippedTemplateEntry entry in entries) {
    final ShippedCatalogueCategory? category = entry.category;
    areas[ShippedLibraryFilter.areaOf(entry)] = category == null
        ? Copy.shippedStarterArea
        : Copy.shippedAreaTitle(
            category.supergroupCode,
            category.supergroupTitle,
          );
    final ShippedRecordType? recordType = entry.recordType;
    if (recordType != null) {
      recordTypes[recordType.code] = recordType.title;
    }
    tiers.add(ShippedLibraryFilter.tierOf(entry));
  }
  final List<String> typeCodes = recordTypes.keys.toList()
    ..sort((String a, String b) => recordTypes[a]!.compareTo(recordTypes[b]!));
  return showAppFilterSheet(
    context,
    title: Copy.shippedFiltersTitle,
    onClear: ref.read(shippedLibraryFilterProvider.notifier).clear,
    facets: (BuildContext _) => _Facets(
      areas: areas,
      recordTypes: <String, String>{
        for (final String code in typeCodes) code: recordTypes[code]!,
      },
      tiers: tiers.toList()..sort(),
    ),
  );
}

class _Facets extends ConsumerWidget {
  const _Facets({
    required this.areas,
    required this.recordTypes,
    required this.tiers,
  });

  final Map<String, String> areas;
  final Map<String, String> recordTypes;
  final List<String> tiers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShippedLibraryFilterState filter = ref.watch(
      shippedLibraryFilterProvider,
    );
    final ShippedLibraryFilter notifier = ref.read(
      shippedLibraryFilterProvider.notifier,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppMultiChoiceField<String>(
          key: const ValueKey<String>('shipped-area-filter'),
          label: Copy.shippedAreaFilter,
          // Area names are catalogue data and are shown as stored
          // (FE-L10N-07).
          options: <Choice<String>>[
            for (final MapEntry<String, String> area in areas.entries)
              Choice<String>(area.key, area.value),
          ],
          value: filter.areas,
          onChanged: notifier.setAreas,
        ),
        if (recordTypes.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.x3),
          AppMultiChoiceField<String>(
            key: const ValueKey<String>('shipped-record-type-filter'),
            label: Copy.shippedRecordTypeFilter,
            options: <Choice<String>>[
              for (final MapEntry<String, String> type in recordTypes.entries)
                Choice<String>(type.key, type.value),
            ],
            value: filter.recordTypes,
            onChanged: notifier.setRecordTypes,
          ),
        ],
        const SizedBox(height: Space.x3),
        AppMultiChoiceField<String>(
          key: const ValueKey<String>('shipped-tier-filter'),
          label: Copy.shippedTierFilter,
          options: <Choice<String>>[
            for (final String tier in tiers)
              Choice<String>(tier, Copy.shippedTierLabel(tier)),
          ],
          value: filter.tiers,
          onChanged: notifier.setTiers,
        ),
      ],
    );
  }
}
