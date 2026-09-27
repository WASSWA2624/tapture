/// The automatic rules that settle a differing value without a person,
/// applied in this order (specification §47). Anything else is a conflict.
enum SettlementRule {
  /// A verified value beats an unverified one.
  verifiedBeatsUnverified,

  /// A barcode, reference or lookup value beats one read or inferred.
  scannedBeatsInferred,

  /// A value beats an empty one nobody ever edited.
  valueBeatsUntouchedEmpty,

  /// No rule decided. A person has to.
  none,
}
