/// Already-localized SDK prompt labels, independent of Flutter and platform code.
final class BiometricPrompt {
  /// The UI supplies labels resolved against the app's current locale.
  const BiometricPrompt({
    required this.title,
    required this.hint,
    required this.cancel,
  });

  /// Android challenge title, using the app's short unlock title.
  final String title;

  /// Android challenge hint, using the app's short biometric action.
  final String hint;

  /// Android and Darwin dismissal label.
  final String cancel;
}
