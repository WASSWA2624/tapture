import 'record_value.dart';

/// What moving a record to another template does to its values, shown before
/// it is applied (task 014 step 5).
///
/// Values are re-mapped by field key and never deleted: a value the target
/// does not declare is kept as retired, and a retired value whose key the
/// target declares again comes back.
final class TemplateChangePlan {
  /// Creates a plan. Prefer [TemplateChangePlan.between] or
  /// [TemplateChangePlan.forValues], which compute the lists.
  const TemplateChangePlan({
    required this.fromTemplateId,
    required this.toTemplateId,
    this.mapped = const <String>[],
    this.retired = const <String>[],
    this.added = const <String>[],
    this.restored = const <String>[],
    this.stillRetired = const <String>[],
  });

  /// The plan for moving values keyed [liveKeys] (and already retired values
  /// keyed [retiredKeys]) onto a template declaring [targetFieldKeys].
  ///
  /// [mapped], [added] and [restored] follow the target's field order;
  /// [retired] and [stillRetired] follow the order the keys were given in.
  factory TemplateChangePlan.between({
    required String fromTemplateId,
    required String toTemplateId,
    required Iterable<String> liveKeys,
    required List<String> targetFieldKeys,
    Iterable<String> retiredKeys = const <String>[],
  }) {
    final Set<String> live = liveKeys.toSet();
    final Set<String> kept = retiredKeys.toSet().difference(live);
    final Set<String> target = targetFieldKeys.toSet();
    return TemplateChangePlan(
      fromTemplateId: fromTemplateId,
      toTemplateId: toTemplateId,
      mapped: _unique(<String>[
        for (final String key in targetFieldKeys)
          if (live.contains(key)) key,
      ]),
      retired: _unique(<String>[
        for (final String key in live)
          if (!target.contains(key)) key,
      ]),
      added: _unique(<String>[
        for (final String key in targetFieldKeys)
          if (!live.contains(key) && !kept.contains(key)) key,
      ]),
      restored: _unique(<String>[
        for (final String key in targetFieldKeys)
          if (kept.contains(key)) key,
      ]),
      stillRetired: _unique(<String>[
        for (final String key in kept)
          if (!target.contains(key)) key,
      ]),
    );
  }

  /// The plan for a record's [values] (retired ones included, as
  /// `RecordEntry.values` holds them) onto [targetFieldKeys].
  factory TemplateChangePlan.forValues({
    required String fromTemplateId,
    required String toTemplateId,
    required List<RecordValue> values,
    required List<String> targetFieldKeys,
  }) {
    return TemplateChangePlan.between(
      fromTemplateId: fromTemplateId,
      toTemplateId: toTemplateId,
      liveKeys: <String>[
        for (final RecordValue value in values)
          if (!value.retired) value.fieldKey,
      ],
      retiredKeys: <String>[
        for (final RecordValue value in values)
          if (value.retired) value.fieldKey,
      ],
      targetFieldKeys: targetFieldKeys,
    );
  }

  /// The template the record is on now.
  final String fromTemplateId;

  /// The template the record moves to.
  final String toTemplateId;

  /// Keys of live values the target declares: they carry over unchanged.
  final List<String> mapped;

  /// Keys of live values the target does not declare: kept as retired.
  final List<String> retired;

  /// Target field keys with no value at all: they start empty.
  final List<String> added;

  /// Keys of retired values the target declares: they become live again.
  final List<String> restored;

  /// Keys of retired values the target does not declare either: they stay
  /// retired, as they were.
  final List<String> stillRetired;

  /// Whether any value changes state (retired or brought back).
  bool get changesValues => retired.isNotEmpty || restored.isNotEmpty;

  /// Returns a copy with the provided fields replaced.
  TemplateChangePlan copyWith({
    String? fromTemplateId,
    String? toTemplateId,
    List<String>? mapped,
    List<String>? retired,
    List<String>? added,
    List<String>? restored,
    List<String>? stillRetired,
  }) {
    return TemplateChangePlan(
      fromTemplateId: fromTemplateId ?? this.fromTemplateId,
      toTemplateId: toTemplateId ?? this.toTemplateId,
      mapped: mapped ?? this.mapped,
      retired: retired ?? this.retired,
      added: added ?? this.added,
      restored: restored ?? this.restored,
      stillRetired: stillRetired ?? this.stillRetired,
    );
  }

  @override
  int get hashCode => Object.hash(
    fromTemplateId,
    toTemplateId,
    Object.hashAll(mapped),
    Object.hashAll(retired),
    Object.hashAll(added),
    Object.hashAll(restored),
    Object.hashAll(stillRetired),
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TemplateChangePlan &&
            other.fromTemplateId == fromTemplateId &&
            other.toTemplateId == toTemplateId &&
            _sameList(other.mapped, mapped) &&
            _sameList(other.retired, retired) &&
            _sameList(other.added, added) &&
            _sameList(other.restored, restored) &&
            _sameList(other.stillRetired, stillRetired));
  }

  @override
  String toString() =>
      'TemplateChangePlan($fromTemplateId -> $toTemplateId, '
      '${mapped.length} mapped, ${retired.length} retired, '
      '${added.length} added, ${restored.length} restored)';
}

List<String> _unique(List<String> keys) => keys.toSet().toList();

bool _sameList(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (int index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
