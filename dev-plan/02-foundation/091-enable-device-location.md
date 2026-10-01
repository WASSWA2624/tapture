# 091 — Enable device location through the shared service

**Implementation step:** 02.02

**Phase** 02 · Foundation services  |  **Depends on** [001](../01-orchestration/001-project-setup.md), [002](002-foundation-services.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

**Implementation started:** Yes

Replace the unavailable location stub behind task 002's `LocationService` with the maintained `geolocator` package,
pinned to 14.0.2 (MIT, Baseflow) and recorded in the allowlist against this task. Features keep reading
`locationServiceProvider`; only `core/location/` imports the plug-in (FE-STR-11). `main.dart` binds the platform
service with a `gpsEnabled` callback that reads the open project's GPS setting and falls back to the device setting,
so GPS stays off by default and is enabled per project (§21, §60.3).

`currentFix` asks nothing of the platform while GPS is off (FE-SEC-07). With GPS on it checks that location services
are enabled, requests permission only while the permission is still undecided, and reads one high-accuracy fix
bounded by `AppConstants.locationTimeout`. It re-reads the GPS setting after every wait, so switching GPS off while a
prompt or a fix is pending discards the result. A disabled service, a refusal, a timeout or an unsupported platform
leaves the record without coordinates: capture never waits past the time box or fails because of location (STANDARD
rule 3). A fix carries latitude, longitude, accuracy in metres and a UTC timestamp.

Every platform build declares its location use. The macOS sandbox entitlement and usage string are new here; the iOS
usage string and the Android fine-location permission already exist and are checked, not changed. Capture (task 012)
and context maintenance (task 011) consume the service through its provider and are not changed by this task.

Work so far: the geolocator adapter, the `main.dart` binding, the macOS keys and a unit test over a fake platform are
written. No acceptance item below has been verified yet.

Verification 2026-09-30: all 13 fake-platform tests passed, covering GPS off, disabled services, denied/restricted/permanent denial, GPS disabled during pending permission/fix, UTC metadata and unsupported/insecure platforms. The entire operation now has one time box, including permission/service waits, and late results are discarded. Capture's slow-fix save regression also passed. Real browser and sandboxed macOS checks remain open; declarations alone do not verify those platforms.

## Files

- `frontend/pubspec.yaml` and `frontend/pubspec.lock` (changed — `geolocator` 14.0.2)
- `frontend/tool/allowlist.yaml` (changed)
- `frontend/lib/core/location/location_service.dart` (changed — the platform adapter replaces the stub)
- `frontend/lib/core/location/geo_fix.dart` (existing `GeoFix` value)
- `frontend/lib/core/location/location_reader.dart` (pure capture port; platform adapter implements it)
- `frontend/lib/core/location/location.dart` (existing barrel)
- `frontend/lib/main.dart` (changed — binds the service to the project and device GPS settings)
- `frontend/macos/Runner/DebugProfile.entitlements` and `frontend/macos/Runner/Release.entitlements` (changed —
  `com.apple.security.personal-information.location`)
- `frontend/macos/Runner/Info.plist` (changed — `NSLocationUsageDescription`)
- `frontend/macos/Flutter/GeneratedPluginRegistrant.swift` (generated)
- `frontend/ios/Runner/Info.plist` and `frontend/android/app/src/main/AndroidManifest.xml` (existing declarations)
- `frontend/test/core/location/location_service_test.dart` (new)

## Definition of done

- [x] `geolocator` is pinned to 14.0.2 with its licence and purpose recorded against 091 in `allowlist.yaml`, only
      `core/location/` imports it, and the dependency check passes.
- [x] With GPS off for the project, `currentFix` returns no fix without calling the platform or asking for
      permission (FE-SEC-07, §60.3).
- [x] With the device's location services disabled, `currentFix` returns no fix and shows no permission prompt.
- [x] Permission is requested only while it is undecided; a refusal, a permanent denial or a restricted device
      returns no fix, and a permanent denial is never prompted again.
- [x] Switching GPS off while the permission prompt or the fix is pending discards the result.
- [x] A fix slower than `AppConstants.locationTimeout` ends at the time box with no fix, and capture and context
      maintenance neither wait longer nor report an error because of location.
- [x] A fix carries latitude, longitude, accuracy in metres and a UTC timestamp (§21).
- [ ] On web the browser asks for location only after GPS is on and a fix is requested; a refusal, an insecure
      origin or a browser without geolocation leaves the record without coordinates.
- [x] A platform with no geolocator implementation leaves the record without coordinates and shows no error.
- [ ] Both macOS entitlements files carry `com.apple.security.personal-information.location`, `Info.plist` carries
      `NSLocationUsageDescription`, and a sandboxed macOS build returns a fix once the user allows it. The iOS
      `NSLocationWhenInUseUsageDescription` and the Android `ACCESS_FINE_LOCATION` declarations remain in place.
- [x] Tests: `frontend/test/core/location/location_service_test.dart` over a fake `GeolocatorPlatform` covering GPS
      off (no platform call), services disabled, denied, denied forever, GPS switched off during the prompt, a
      timeout, an unsupported platform, and a fix that keeps coordinates, accuracy, UTC time and the time limit.
