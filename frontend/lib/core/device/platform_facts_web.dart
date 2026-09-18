import 'dart:js_interop';

/// Every browser build is `web`, whatever the machine underneath.
String platformName() => 'web';

/// The browser's own user agent string.
String userAgent() => _navigator.userAgent;

/// The IANA zone the browser resolves, such as `Africa/Kampala`.
String? ianaTimeZone() {
  try {
    final String? zone = _DateTimeFormat().resolvedOptions().timeZone;
    return zone == null || zone.isEmpty ? null : zone;
  } on Object {
    return null;
  }
}

/// The address in the browser's location bar.
String? pageUrl() => _location.href;

/// Browsers do not expose interface addresses.
Future<List<String>> localAddresses() async => const <String>[];

@JS('navigator')
external _Navigator get _navigator;

extension type _Navigator._(JSObject _) implements JSObject {
  external String get userAgent;
}

@JS('location')
external _Location get _location;

extension type _Location._(JSObject _) implements JSObject {
  external String get href;
}

@JS('Intl.DateTimeFormat')
extension type _DateTimeFormat._(JSObject _) implements JSObject {
  external factory _DateTimeFormat();
  external _ResolvedOptions resolvedOptions();
}

extension type _ResolvedOptions._(JSObject _) implements JSObject {
  external String? get timeZone;
}
