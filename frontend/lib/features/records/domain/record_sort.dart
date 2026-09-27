import 'record_sort_key.dart';

export 'record_sort_key.dart';

/// How a records list is ordered: a [key] and a direction (task 014, D15).
///
/// Applied in the query, never to a materialised list, always with the record
/// id as a tiebreak in the same direction. The default is newest first.
final class RecordSort {
  /// Creates a sort. The defaults give [newestFirst].
  const RecordSort({this.key = RecordSortKey.number, this.ascending = false});

  /// Reads a sort written by [toJson], falling back to [newestFirst] for any
  /// part that is missing or unknown.
  factory RecordSort.fromJson(Map<String, Object?> json) {
    final Object? key = json[_keyField];
    final Object? ascending = json[_ascendingField];
    return RecordSort(
      key:
          (key is String ? RecordSortKey.fromStored(key) : null) ??
          newestFirst.key,
      ascending: ascending is bool ? ascending : newestFirst.ascending,
    );
  }

  /// Highest record number first: the most recently captured on top.
  static const RecordSort newestFirst = RecordSort();

  /// What the list is ordered by.
  final RecordSortKey key;

  /// Whether the smallest number, earliest date or first name comes first.
  final bool ascending;

  /// The same key in the other direction.
  RecordSort reversed() => RecordSort(key: key, ascending: !ascending);

  /// Returns a copy with the provided fields replaced.
  RecordSort copyWith({RecordSortKey? key, bool? ascending}) {
    return RecordSort(
      key: key ?? this.key,
      ascending: ascending ?? this.ascending,
    );
  }

  /// The JSON object [RecordSort.fromJson] reads back.
  Map<String, Object?> toJson() {
    return <String, Object?>{_keyField: key.stored, _ascendingField: ascending};
  }

  @override
  int get hashCode => Object.hash(key, ascending);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RecordSort &&
            other.key == key &&
            other.ascending == ascending);
  }

  @override
  String toString() => 'RecordSort(${key.stored}, ascending: $ascending)';
}

const String _keyField = 'key';
const String _ascendingField = 'ascending';
