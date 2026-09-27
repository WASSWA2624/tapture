import 'record_history_kind.dart';

export 'record_history_kind.dart';

/// One line of a record's history, read from the local audit table
/// (task 014 step 6, spec §43).
///
/// Status moves carry the stored status names in [previous] and [next];
/// value edits carry the value before and after; a flag carries `'false'`
/// and `'true'`.
final class RecordHistoryEvent {
  /// Creates a history line.
  const RecordHistoryEvent({
    required this.id,
    required this.at,
    required this.kind,
    required this.operator,
    required this.device,
    this.fieldKey,
    this.previous,
    this.next,
    this.reason,
  });

  /// Merge id of the audit row, stable across reads.
  final String id;

  /// When the change was written.
  final DateTime at;

  /// What the change was about.
  final RecordHistoryKind kind;

  /// The field or marker that changed, when the row names one.
  final String? fieldKey;

  /// What it was before, when known.
  final String? previous;

  /// What it became, when known.
  final String? next;

  /// Operator name copied from the device profile at write time.
  final String operator;

  /// Device that wrote the change.
  final String device;

  /// Why the change was made, when known.
  final String? reason;

  /// Returns a copy with the provided fields replaced.
  RecordHistoryEvent copyWith({
    String? id,
    DateTime? at,
    RecordHistoryKind? kind,
    String? fieldKey,
    String? previous,
    String? next,
    String? operator,
    String? device,
    String? reason,
  }) {
    return RecordHistoryEvent(
      id: id ?? this.id,
      at: at ?? this.at,
      kind: kind ?? this.kind,
      fieldKey: fieldKey ?? this.fieldKey,
      previous: previous ?? this.previous,
      next: next ?? this.next,
      operator: operator ?? this.operator,
      device: device ?? this.device,
      reason: reason ?? this.reason,
    );
  }

  @override
  int get hashCode => Object.hash(
    id,
    at,
    kind,
    fieldKey,
    previous,
    next,
    operator,
    device,
    reason,
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RecordHistoryEvent &&
            other.id == id &&
            other.at == at &&
            other.kind == kind &&
            other.fieldKey == fieldKey &&
            other.previous == previous &&
            other.next == next &&
            other.operator == operator &&
            other.device == device &&
            other.reason == reason);
  }

  /// Names the row only: a value never reaches a log (FE-CODE-08).
  @override
  String toString() => 'RecordHistoryEvent($id, ${kind.name})';
}
