import 'dart:io';

/// The operating system, as `dart:io` names it.
String platformName() => Platform.operatingSystem;

/// The Dart runtime, in the shape its HTTP client announces itself:
/// `Dart/3.12 (dart:io)`.
String userAgent() {
  final List<String> parts = Platform.version.split(' ').first.split('.');
  final String version = parts.length < 2
      ? parts.first
      : '${parts[0]}.${parts[1]}';
  return 'Dart/$version (dart:io)';
}

/// `dart:io` exposes no zone database; the clock's abbreviation is used.
String? ianaTimeZone() => null;

/// A device has no page address.
String? pageUrl() => null;

/// Non-loopback interface addresses, IPv4 first. Listing is local; nothing
/// is sent (FE-SEC-03).
Future<List<String>> localAddresses() async {
  try {
    final List<NetworkInterface> interfaces = await NetworkInterface.list();
    final List<InternetAddress> found = <InternetAddress>[
      for (final NetworkInterface interface in interfaces)
        ...interface.addresses.where(
          (InternetAddress address) =>
              !address.isLoopback && !address.isLinkLocal,
        ),
    ];
    found.sort(
      (InternetAddress a, InternetAddress b) => _rank(a).compareTo(_rank(b)),
    );
    return <String>[for (final InternetAddress a in found) a.address];
  } on Object {
    return const <String>[];
  }
}

int _rank(InternetAddress address) {
  return address.type == InternetAddressType.IPv4 ? 0 : 1;
}
