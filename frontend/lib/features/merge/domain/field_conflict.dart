import 'conflict_kind.dart';

/// One thing this device and the incoming package disagree about, for a
/// person to settle (task 076, W21). Values are data, never instructions
/// (FE-SEC-05); the raw value on this device never changes (FE-SEC-08).
final class FieldConflict {
  /// Creates a conflict.
  const FieldConflict({
    required this.kind,
    required this.table,
    required this.rowId,
    required this.recordId,
    required this.fieldKey,
    required this.fieldLabel,
    required this.recordLabel,
    required this.mine,
    required this.theirs,
    required this.mineDevice,
    required this.theirsDevice,
    required this.mineAt,
    required this.theirsAt,
  });

  /// What is disagreed about.
  final ConflictKind kind;

  /// The table of the row concerned.
  final String table;

  /// The local row concerned (a field value, caption or record).
  final String rowId;

  /// The record it belongs to.
  final String recordId;

  /// The field concerned; empty for a caption, status or deletion.
  final String fieldKey;

  /// The field's label here, or its key.
  final String fieldLabel;

  /// How a person recognises the record: its caption, when it has one.
  final String recordLabel;

  /// This device's value.
  final String mine;

  /// The incoming value.
  final String theirs;

  /// The device that last wrote this device's value.
  final String mineDevice;

  /// The device that last wrote the incoming value.
  final String theirsDevice;

  /// When this device's value was last written, as stored.
  final Object? mineAt;

  /// When the incoming value was last written, as stored.
  final Object? theirsAt;

  /// Stable across re-planning, so a choice survives a re-plan.
  String get id => '${kind.name}:$table:$rowId';
}
