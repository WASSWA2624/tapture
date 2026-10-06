/// Attributable provider usage, with missing token reports retained as absent.
abstract interface class ProcessingUsageRepository {
  /// Today's conservative reserved cost grouped by server budget units.
  Stream<({Map<String, double> reservedCosts, int? totalTokens})> watchSpend({
    String? projectId,
  });
}
