import 'package:tapture/core/time/clock.dart';

import 'platform_facts_stub.dart'
    if (dart.library.io) 'platform_facts_io.dart'
    if (dart.library.js_interop) 'platform_facts_web.dart'
    as platform;

/// What the runtime says about itself, for diagnostics the operator exports
/// by hand: the platform, the user agent, the page address in a browser,
/// the time zone and the local network addresses.
///
/// Nothing here is sent anywhere (FE-SEC-10), and no hardware identifier is
/// read (FE-SEC-07).
final class PlatformFacts {
  /// Creates the facts.
  const PlatformFacts({
    required this.platform,
    required this.userAgent,
    required this.timeZone,
    this.pageUrl,
    this.addresses = const <String>[],
  });

  /// A stand-in so tests never read the platform (FE-TEST-03).
  const PlatformFacts.fake({
    this.platform = 'test',
    this.userAgent = 'test-agent',
    this.timeZone = 'UTC',
    this.pageUrl,
    this.addresses = const <String>[],
  });

  /// `web`, `android`, `ios`, `windows`, `macos` or `linux`.
  final String platform;

  /// The browser's user agent, or the Dart runtime's on a device.
  final String userAgent;

  /// The zone name: the IANA name where the platform gives one
  /// (`Africa/Kampala`), otherwise the abbreviation (`EAT`).
  final String timeZone;

  /// The page address in a browser; null on a device.
  final String? pageUrl;

  /// Non-loopback addresses of this device's network interfaces. Empty in a
  /// browser, which does not expose them.
  final List<String> addresses;
}

/// The facts this runtime reports. [clock] names the zone where the platform
/// has no IANA name. Pass [fake] so tests never read the platform.
Future<PlatformFacts> platformFacts({
  required Clock clock,
  PlatformFacts? fake,
}) async {
  if (fake != null) {
    return fake;
  }
  final String zone = clock.nowUtc().toLocal().timeZoneName;
  return PlatformFacts(
    platform: platform.platformName(),
    userAgent: platform.userAgent(),
    timeZone: platform.ianaTimeZone() ?? zone,
    pageUrl: platform.pageUrl(),
    addresses: await platform.localAddresses(),
  );
}
