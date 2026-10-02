import 'cloud_destination.dart';

/// Validates explicit desktop callback configuration and runtime redirects.
final class CloudOauthRedirect {
  const CloudOauthRedirect._();

  /// Parses supported loopback configuration without DNS or invented defaults.
  static Uri? parse(DestinationKind kind, String? value) {
    final Uri? uri = Uri.tryParse(value ?? '');
    if (uri == null ||
        // Registration uses an exact callback; reject silently normalized input.
        uri.toString() != value ||
        !isLoopback(uri) ||
        (uri.port == 0 && kind != DestinationKind.googleDrive) ||
        (uri.host == '::1' && kind != DestinationKind.googleDrive)) {
      return null;
    }
    return uri;
  }

  /// Only numeric loopback addresses, absolute paths and no query/fragment.
  static bool isLoopback(Uri uri) =>
      uri.scheme == 'http' &&
      (uri.host == '127.0.0.1' || uri.host == '::1') &&
      uri.hasPort &&
      uri.port >= 0 &&
      uri.port <= 65535 &&
      uri.userInfo.isEmpty &&
      !uri.hasQuery &&
      !uri.hasFragment &&
      (uri.path.isEmpty || uri.path.startsWith('/')) &&
      uri.normalizePath().path == uri.path;

  /// The receiver may replace only a configured ephemeral port.
  static bool matches(Uri configured, Uri actual) =>
      configured.scheme == actual.scheme &&
      configured.host == actual.host &&
      configured.userInfo == actual.userInfo &&
      configured.path == actual.path &&
      !actual.hasQuery &&
      !actual.hasFragment &&
      ((configured.hasPort == actual.hasPort &&
              configured.port == actual.port) ||
          (isLoopback(configured) &&
              isLoopback(actual) &&
              configured.port == 0 &&
              actual.port > 0));

  /// Validates a callback's origin/path and returns the exact exchange redirect.
  static Uri? fromCallback(Uri configured, Uri callback) {
    if (callback.hasFragment) {
      return null;
    }
    final Uri actual = configured.scheme == 'http' && configured.port == 0
        ? configured.replace(port: callback.port)
        : configured;
    final Uri origin = Uri(
      scheme: callback.scheme,
      userInfo: callback.userInfo,
      host: callback.host,
      port: callback.hasPort ? callback.port : null,
      path: callback.path,
    );
    return matches(configured, actual) && matches(actual, origin)
        ? actual
        : null;
  }
}
