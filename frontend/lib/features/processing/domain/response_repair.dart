/// The single follow-up after a response will not parse.
///
/// The parse error is sent as data. It is not written into an instruction.
final class ResponseRepair {
  /// How many repair calls are allowed. One, then the job fails for good.
  static const int maxAttempts = 1;

  /// Whether another call is still allowed after [repairsUsed] failures.
  static bool mayRetry({required int repairsUsed}) {
    return repairsUsed < maxAttempts;
  }

  /// Data to attach to the follow-up request. [parseError] is quoted as data.
  static Map<String, Object?> followUp({required String parseError}) {
    return <String, Object?>{'parse_error': parseError};
  }
}
