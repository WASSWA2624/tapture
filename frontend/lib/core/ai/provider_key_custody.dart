/// Where credentials for a provider are held.
enum ProviderKeyCustody {
  /// Organisation backend holds the credential.
  backend,

  /// The credential is held in this device's secure storage.
  device,
}
