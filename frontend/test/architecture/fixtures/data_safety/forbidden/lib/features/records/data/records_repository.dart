/// A repository that hard-deletes a row instead of writing a tombstone.
class RecordsRepository {
  final _Rows _records = _Rows();

  void remove() {
    _records.delete();
  }
}

class _Rows {
  void delete() {}
}
