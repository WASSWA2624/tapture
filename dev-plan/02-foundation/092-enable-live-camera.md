# 092 — Enable live camera and barcode adapters

**Implementation step:** 02.03

**Phase** 02 · Foundation services  |  **Depends on** [001](../01-orchestration/001-project-setup.md), [002](002-foundation-services.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

**Implementation started:** Yes

Replace the placeholder camera preview and the unavailable barcode decoder behind task 002's platform-service
boundary with maintained plug-ins: Flutter's `camera` 0.12.1 and `mobile_scanner` 7.4.2, both BSD-3-Clause, pinned
and recorded in the allowlist against this task. Only `core/camera/` and `core/barcode/` import them (FE-STR-11).

- `CameraService()` returns the `camera`-backed device service on Android, iOS and web: back lens first, high
  preset, no audio, with flash, tap-to-focus and zoom keeping their last supported setting where the hardware lacks
  them. macOS, Windows and Linux keep the photo-picker service.
- `BarcodeScannerService()` returns the `mobile_scanner`-backed device scanner on Android, iOS, macOS and web;
  elsewhere the scanner stays unavailable and the identifier is typed (§25).
- `CameraPreviewSurface` is the one seam through which an adapter hands its plug-in preview widget to a feature, so
  `CameraView` and `BarcodeScannerScreen` show the live image without importing a plug-in.
- `LiveCameraScreen` opens from the photo-source sheet's Take photo whenever the camera service offers a preview
  surface. It stays open for rapid multi-shot, and each shot is written through the capture session's durable writer
  before the shutter is enabled again (§22.1). Its saving and grid state live in `live_camera_controller.dart`, a
  Riverpod notifier, not in widget state.
- A refused, restricted or missing camera ends in the failed preview state with the no-camera message; gallery and
  file import and typed identifiers stay available, so capture is never blocked (STANDARD rule 3). The first-run
  permission prompt and closing the screen while the camera starts never leave the preview stuck on starting.
- On web the preview and the scanner work offline: nothing is fetched from a third-party origin at run time (§7.1).
- macOS declares the sandbox camera entitlement and a camera usage string that names photo capture and barcode
  scanning.

The capture screens of task 012 host these adapters; this task changes only the camera, scanner and live-camera
surfaces listed below.

Work so far: the adapters, the preview seam, `LiveCameraScreen` and the provider bindings in `main.dart` are
written. No acceptance item below has been verified yet. The 2026-09-28 review found the macOS camera entitlement
missing and a start/stop race when the first permission prompt pauses the app; both are open items below.

## Files

Dependencies:

- `frontend/pubspec.yaml` and `frontend/pubspec.lock` (changed — `camera` 0.12.1 and `mobile_scanner` 7.4.2)
- `frontend/tool/allowlist.yaml` (changed)

Adapters:

- `frontend/lib/core/camera/camera_service.dart` (changed — platform factory)
- `frontend/lib/core/camera/device_camera_service.dart` (new)
- `frontend/lib/core/camera/camera_preview_surface.dart` (new)
- `frontend/lib/core/barcode/barcode_scanner_service.dart` (changed — platform factory)
- `frontend/lib/core/barcode/device_barcode_scanner.dart` (new)
- `frontend/lib/main.dart` (changed — binds both services)

Screens:

- `frontend/lib/features/capture/presentation/live_camera_screen.dart` (new)
- `frontend/lib/features/capture/presentation/live_camera_controller.dart` (new)
- `frontend/lib/features/capture/presentation/camera_view.dart` (changed — live preview and lifecycle)
- `frontend/lib/features/capture/presentation/barcode_scanner_screen.dart` (changed — live preview and torch)
- `frontend/lib/features/capture/presentation/capture_screen.dart` (changed — opens the live camera)

Platform declarations:

- `frontend/macos/Runner/DebugProfile.entitlements` and `frontend/macos/Runner/Release.entitlements` (changed —
  `com.apple.security.device.camera`)
- `frontend/macos/Runner/Info.plist` (changed — `NSCameraUsageDescription`)
- `frontend/macos/Flutter/GeneratedPluginRegistrant.swift` (generated)
- `frontend/ios/Runner/Info.plist` and `frontend/android/app/src/main/AndroidManifest.xml` (existing declarations)

Tests:

- `frontend/test/core/camera/device_camera_service_test.dart` (new)
- `frontend/test/core/barcode/device_barcode_scanner_test.dart` (new)
- `frontend/test/features/capture/presentation/live_camera_screen_test.dart` (new)
- `frontend/test/features/capture/presentation/live_camera_controller_test.dart` (new)
- `frontend/test/features/capture/presentation/capture_widgets_test.dart` (changed — camera view and scanner screen)

## Definition of done

- [x] `camera` 0.12.1 and `mobile_scanner` 7.4.2 are pinned with licence and purpose recorded against 092 in
      `allowlist.yaml`, only `core/camera/` and `core/barcode/` import them, and the dependency check passes.
- [ ] On Android, iOS and web, Take photo opens `LiveCameraScreen` on the live back-camera preview; macOS, Windows
      and Linux keep the photo-picker path.
- [ ] Every shot is written through the capture session before the shutter is enabled again, the screen stays open
      for the next shot, and a failed shot or write shows the error snack without closing the screen (§22.1).
- [x] `LiveCameraScreen` holds no widget state; its saving and grid state live in `live_camera_controller.dart`.
- [ ] A refused or restricted camera permission ends in the failed state with the no-camera message and a
      `PermissionFailure`; a device with no camera does the same with a `ProviderFailure`. Gallery import, file
      import and typed identifiers stay available.
- [ ] The first-run permission prompt, backgrounding and resuming, and closing the screen while the camera is still
      starting all end in a running preview or an explicit failed state, never stuck on starting, and the camera is
      released when the screen closes.
- [ ] Flash, tap-to-focus and zoom keep the last supported setting on hardware that lacks them, and zoom stays
      within the device's reported bounds.
- [ ] The barcode screen shows the live scanner preview; the first decoded code shows once with haptic feedback,
      confirm returns it to the field as a `BARCODE` value, rescan clears it, and the torch appears only where
      supported (§25).
- [ ] A refused scanner permission, an unsupported platform or a scanner error shows the unavailable message, and
      the identifier can still be typed.
- [ ] On web, preview and scanning run after the browser grants camera access, and work offline with every script
      served from the app's own origin (§7.1); a refusal, an insecure origin or a browser without a camera shows the
      failed or unavailable state and gallery upload still works.
- [ ] Both macOS entitlements files carry `com.apple.security.device.camera`, `NSCameraUsageDescription` names photo
      capture and barcode scanning, and a sandboxed macOS build opens the live scanner.
- [ ] Tests: `frontend/test/core/camera/device_camera_service_test.dart` over a fake camera platform covering lens
      choice, start and stop generations (stop during start, restart after stop, the permission-prompt pause),
      permission and no-camera failures, and flash and zoom fallbacks.
- [ ] Tests: `frontend/test/core/barcode/device_barcode_scanner_test.dart` covering permission mapping, empty values
      ignored, torch support and stop releasing the controller.
- [ ] Tests: widget test `frontend/test/features/capture/presentation/live_camera_screen_test.dart` covering the
      preview states, a shot written before the next is enabled, a failed shot and a failed write; unit test
      `live_camera_controller_test.dart`; camera view and scanner screen cases in `capture_widgets_test.dart`.
