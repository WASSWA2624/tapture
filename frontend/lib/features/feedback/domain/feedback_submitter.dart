/// Who wrote a feedback entry, as far as this device knows.
enum FeedbackSubmitter {
  /// An operator enrolled with the organisation's backend.
  signedInUser('signedIn', 'Signed-in user'),

  /// The named local operator of a device that has not signed in.
  localOperator('localOperator', 'Local operator'),

  /// No operator name was set.
  anonymous('anonymous', 'Anonymous');

  const FeedbackSubmitter(this.wireName, this.exportLabel);

  /// Stored name. Never renamed.
  final String wireName;

  /// Name in an exported workbook.
  final String exportLabel;

  /// Signed in when there is an [accountId], local when there is a [name],
  /// anonymous otherwise.
  static FeedbackSubmitter resolve({String? name, String? accountId}) {
    if (accountId != null && accountId.trim().isNotEmpty) {
      return signedInUser;
    }
    if (name != null && name.trim().isNotEmpty) {
      return localOperator;
    }
    return anonymous;
  }

  /// The submitter stored as [name], or [anonymous] for one this build does
  /// not know.
  static FeedbackSubmitter fromWire(Object? name) {
    for (final FeedbackSubmitter submitter in values) {
      if (submitter.wireName == name) {
        return submitter;
      }
    }
    return anonymous;
  }
}
