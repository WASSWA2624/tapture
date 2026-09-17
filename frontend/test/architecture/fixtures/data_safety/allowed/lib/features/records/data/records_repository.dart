/// The first write of a raw field, which is the only one allowed (FE-SEC-08).
class RecordsRepository {
  void insertField(RawRow row, String raw) {
    row.valueRaw = raw;
  }

  void remove(String id) {
    writeTombstone(id);
  }
}

void writeTombstone(String id) {
  if (id.isEmpty) {
    return;
  }
}

class RawRow {
  String valueRaw = '';
}
