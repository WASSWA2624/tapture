/// Neither a device nor a browser.
String platformName() => 'unknown';

/// No runtime to describe.
String userAgent() => 'unknown';

/// No zone database to read.
String? ianaTimeZone() => null;

/// No page.
String? pageUrl() => null;

/// No interfaces to list.
Future<List<String>> localAddresses() async => const <String>[];
