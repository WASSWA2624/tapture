/// Relabels incoming record numbers that this project already uses.
///
/// Local records are never renumbered. The number a record arrived with is
/// kept beside the new one. The next number continues the project's sequence.
final class MergeNumbering {
  /// Creates a numbering pass.
  const MergeNumbering();

  /// New numbers keyed by record id. Absent ids were not relabelled.
  Map<String, RelabelledNumber> relabel({
    required Iterable<IncomingNumber> incoming,
    required Set<String> takenNumbers,
  }) {
    final Set<String> taken = <String>{...takenNumbers};
    var next = _highest(taken) + 1;
    final Map<String, RelabelledNumber> moved = <String, RelabelledNumber>{};
    for (final IncomingNumber record in incoming) {
      if (record.local) {
        continue;
      }
      if (!taken.contains(record.number)) {
        taken.add(record.number);
        continue;
      }
      while (taken.contains('$next')) {
        next += 1;
      }
      final String assigned = '$next';
      taken.add(assigned);
      moved[record.id] = (number: assigned, arrivedAs: record.number);
      next += 1;
    }
    return moved;
  }

  int _highest(Set<String> taken) {
    var highest = 0;
    for (final String number in taken) {
      final int? parsed = int.tryParse(number);
      if (parsed != null && parsed > highest) {
        highest = parsed;
      }
    }
    return highest;
  }
}

/// An incoming or local record number.
typedef IncomingNumber = ({String id, String number, bool local});

/// The new number and the one the record arrived with.
typedef RelabelledNumber = ({String number, String arrivedAs});
