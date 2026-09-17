/// Refinement writing over the raw column instead of valueRefined.
class RefinementService {
  void apply(RawRow row, String refined) {
    row.valueRaw = refined;
  }
}

class RawRow {
  String valueRaw = '';
}
