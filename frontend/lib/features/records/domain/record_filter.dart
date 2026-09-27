import 'package:tapture/core/widgets/record_status.dart';

import 'record_flag.dart';

/// What narrows a records list (task 014 step 2, D15).
///
/// Every dimension is applied in the query and the dimensions are AND-ed.
/// Inside a dimension the chosen values are alternatives, except [flags],
/// where every chosen flag must hold. An empty dimension narrows nothing.
/// [search] is matched against the record's search index; it is not
/// persisted with the rest (D11), so callers store [withoutSearch].
final class RecordFilter {
  /// Creates a filter. Every dimension defaults to "any".
  const RecordFilter({
    this.statuses = const <RecordStatus>{},
    this.templateIds = const <String>{},
    this.context = const <String, Set<String>>{},
    this.capturedFrom,
    this.capturedTo,
    this.operators = const <String>{},
    this.conditions = const <String>{},
    this.flags = const <RecordFlag>{},
    this.search = '',
  });

  /// Only records in [status]: what `?filter=needsReview` opens on.
  factory RecordFilter.forStatus(RecordStatus status) {
    return RecordFilter(statuses: <RecordStatus>{status});
  }

  /// Reads a filter written by [toJson]. Unknown keys, unknown statuses or
  /// flags and values of the wrong type are dropped, never thrown.
  factory RecordFilter.fromJson(Map<String, Object?> json) {
    final Object? context = json[_contextField];
    final Object? search = json[_searchField];
    return RecordFilter(
      statuses: <RecordStatus>{
        for (final String raw in _strings(json[_statusesField]))
          ?RecordStatus.fromStored(raw),
      },
      templateIds: _strings(json[_templatesField]).toSet(),
      context: <String, Set<String>>{
        if (context is Map<String, Object?>)
          for (final MapEntry<String, Object?> level in context.entries)
            if (_strings(level.value).isNotEmpty)
              level.key: _strings(level.value).toSet(),
      },
      capturedFrom: _date(json[_fromField]),
      capturedTo: _date(json[_toField]),
      operators: _strings(json[_operatorsField]).toSet(),
      conditions: _strings(json[_conditionsField]).toSet(),
      flags: <RecordFlag>{
        for (final String raw in _strings(json[_flagsField]))
          ?RecordFlag.fromStored(raw),
      },
      search: search is String ? search : '',
    );
  }

  /// A filter that narrows nothing.
  static const RecordFilter none = RecordFilter();

  /// Field keys whose values the [conditions] dimension matches.
  static const Set<String> conditionFieldKeys = <String>{
    'condition',
    'condition_grade',
  };

  /// Statuses to list. Empty lists every status but archived and deleted.
  final Set<RecordStatus> statuses;

  /// Templates to list, by id.
  final Set<String> templateIds;

  /// Context level key to the values accepted at that level.
  final Map<String, Set<String>> context;

  /// Earliest capture instant listed, inclusive.
  final DateTime? capturedFrom;

  /// Latest capture instant listed, inclusive.
  final DateTime? capturedTo;

  /// Who captured the record (`records.captured_by`).
  final Set<String> operators;

  /// Condition codes, matched on the fields in [conditionFieldKeys].
  final Set<String> conditions;

  /// Quality flags a listed record must all carry.
  final Set<RecordFlag> flags;

  /// Free text matched against values, captions, transcripts and OCR text.
  final String search;

  /// The statuses the list actually shows. Deleted records are never listed
  /// (the recycle bin lists them), whatever [statuses] holds.
  Set<RecordStatus> get listedStatuses {
    return <RecordStatus>{
      for (final RecordStatus status in RecordStatus.values)
        if (status != RecordStatus.deleted &&
            (statuses.isEmpty
                ? status != RecordStatus.archived
                : statuses.contains(status)))
          status,
    };
  }

  /// Whether a capture date bound is set.
  bool get hasCapturedRange => capturedFrom != null || capturedTo != null;

  /// How many removable chips the filter shows: one per chosen value, and
  /// one for the date range. [search] is not counted; its field shows it.
  int get activeCount {
    int count =
        statuses.length +
        templateIds.length +
        operators.length +
        conditions.length +
        flags.length;
    for (final Set<String> values in context.values) {
      count += values.length;
    }
    return hasCapturedRange ? count + 1 : count;
  }

  /// Whether the filter narrows nothing at all, search included.
  bool get isEmpty => activeCount == 0 && search.trim().isEmpty;

  /// Returns a copy with the provided fields replaced. [clearCapturedFrom]
  /// and [clearCapturedTo] remove the matching bound.
  RecordFilter copyWith({
    Set<RecordStatus>? statuses,
    Set<String>? templateIds,
    Map<String, Set<String>>? context,
    DateTime? capturedFrom,
    DateTime? capturedTo,
    Set<String>? operators,
    Set<String>? conditions,
    Set<RecordFlag>? flags,
    String? search,
    bool clearCapturedFrom = false,
    bool clearCapturedTo = false,
  }) {
    return RecordFilter(
      statuses: statuses ?? this.statuses,
      templateIds: templateIds ?? this.templateIds,
      context: context ?? this.context,
      capturedFrom: clearCapturedFrom
          ? null
          : (capturedFrom ?? this.capturedFrom),
      capturedTo: clearCapturedTo ? null : (capturedTo ?? this.capturedTo),
      operators: operators ?? this.operators,
      conditions: conditions ?? this.conditions,
      flags: flags ?? this.flags,
      search: search ?? this.search,
    );
  }

  /// Without [status]: what dismissing its chip does.
  RecordFilter withoutStatus(RecordStatus status) =>
      copyWith(statuses: _minus(statuses, status));

  /// Without the template [id].
  RecordFilter withoutTemplate(String id) =>
      copyWith(templateIds: _minus(templateIds, id));

  /// Without [value] at context level [key]; a level left empty is dropped.
  RecordFilter withoutContextValue(String key, String value) {
    return copyWith(
      context: <String, Set<String>>{
        for (final MapEntry<String, Set<String>> level in context.entries)
          if (level.key != key)
            level.key: level.value
          else if (_minus(level.value, value).isNotEmpty)
            level.key: _minus(level.value, value),
      },
    );
  }

  /// Without the capture date range.
  RecordFilter withoutCapturedRange() =>
      copyWith(clearCapturedFrom: true, clearCapturedTo: true);

  /// Without the operator [id].
  RecordFilter withoutOperator(String id) =>
      copyWith(operators: _minus(operators, id));

  /// Without the condition [code].
  RecordFilter withoutCondition(String code) =>
      copyWith(conditions: _minus(conditions, code));

  /// Without [flag].
  RecordFilter withoutFlag(RecordFlag flag) =>
      copyWith(flags: _minus(flags, flag));

  /// Without any status, template, context, operator, condition, flag or
  /// date: the one-tap clear. [search] stays, since its field owns it.
  RecordFilter withoutCriteria() => RecordFilter(search: search);

  /// Without [search]: the form that is persisted per project.
  RecordFilter withoutSearch() => copyWith(search: '');

  /// The JSON object [RecordFilter.fromJson] reads back. Empty dimensions
  /// are left out, so [none] writes `{}`.
  Map<String, Object?> toJson() {
    final DateTime? from = capturedFrom;
    final DateTime? to = capturedTo;
    return <String, Object?>{
      if (statuses.isNotEmpty)
        _statusesField: <String>[
          for (final RecordStatus status in RecordStatus.values)
            if (statuses.contains(status)) status.stored,
        ],
      if (templateIds.isNotEmpty) _templatesField: _sorted(templateIds),
      if (context.isNotEmpty)
        _contextField: <String, Object?>{
          for (final String key in _sorted(context.keys))
            key: _sorted(context[key]!),
        },
      if (from != null) _fromField: from.toUtc().toIso8601String(),
      if (to != null) _toField: to.toUtc().toIso8601String(),
      if (operators.isNotEmpty) _operatorsField: _sorted(operators),
      if (conditions.isNotEmpty) _conditionsField: _sorted(conditions),
      if (flags.isNotEmpty)
        _flagsField: <String>[
          for (final RecordFlag flag in RecordFlag.values)
            if (flags.contains(flag)) flag.stored,
        ],
      if (search.isNotEmpty) _searchField: search,
    };
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(statuses),
    Object.hashAllUnordered(templateIds),
    Object.hashAllUnordered(<Object>[
      for (final MapEntry<String, Set<String>> level in context.entries)
        Object.hash(level.key, Object.hashAllUnordered(level.value)),
    ]),
    capturedFrom?.microsecondsSinceEpoch,
    capturedTo?.microsecondsSinceEpoch,
    Object.hashAllUnordered(operators),
    Object.hashAllUnordered(conditions),
    Object.hashAllUnordered(flags),
    search,
  );

  /// Equal when every dimension holds the same values; the bounds compare as
  /// instants, so a local and a UTC spelling of one moment are equal.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RecordFilter &&
            _sameSet(other.statuses, statuses) &&
            _sameSet(other.templateIds, templateIds) &&
            other.context.length == context.length &&
            context.entries.every(
              (MapEntry<String, Set<String>> level) =>
                  _sameSet(other.context[level.key] ?? <String>{}, level.value),
            ) &&
            other.capturedFrom?.microsecondsSinceEpoch ==
                capturedFrom?.microsecondsSinceEpoch &&
            other.capturedTo?.microsecondsSinceEpoch ==
                capturedTo?.microsecondsSinceEpoch &&
            _sameSet(other.operators, operators) &&
            _sameSet(other.conditions, conditions) &&
            _sameSet(other.flags, flags) &&
            other.search == search);
  }

  /// Counts only: a filter value never reaches a log (FE-CODE-08).
  @override
  String toString() => 'RecordFilter($activeCount active)';
}

const String _statusesField = 'statuses';
const String _templatesField = 'templateIds';
const String _contextField = 'context';
const String _fromField = 'capturedFrom';
const String _toField = 'capturedTo';
const String _operatorsField = 'operators';
const String _conditionsField = 'conditions';
const String _flagsField = 'flags';
const String _searchField = 'search';

Set<T> _minus<T>(Set<T> values, T value) => <T>{...values}..remove(value);

bool _sameSet<T>(Set<T> left, Set<T> right) =>
    left.length == right.length && left.containsAll(right);

List<String> _sorted(Iterable<String> values) => values.toList()..sort();

List<String> _strings(Object? raw) => <String>[
  if (raw is List<Object?>)
    for (final Object? value in raw)
      if (value is String && value.isNotEmpty) value,
];

DateTime? _date(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toUtc() : null;
