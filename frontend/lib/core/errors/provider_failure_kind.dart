part of 'failure.dart';

/// What kind of provider failure a [ProviderFailure] reports, so the retry
/// classifier and the test action can tell them apart without reading the
/// message.
enum ProviderFailureKind {
  /// The key or credentials were refused.
  authentication,

  /// The provider asked the caller to slow down.
  rateLimited,

  /// The provider or the network to it is down.
  unavailable,

  /// The provider cannot read what was sent.
  unsupportedMedia,

  /// The provider answered with something that could not be read.
  malformed,

  /// Not classified.
  unknown,
}
