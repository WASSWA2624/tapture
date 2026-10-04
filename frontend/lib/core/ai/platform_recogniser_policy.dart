import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Whether the platform recogniser provably keeps speech on the device
/// (FE-SEC-04): the gate field dictation passes before it falls back from
/// Whisper to the platform's own recogniser.
///
/// The `speech_to_text` plugin's on-device flag is not a guarantee
/// everywhere: Android below 12, or without its on-device recogniser,
/// silently streams audio to a server. So the answer comes from the
/// platform, not from the flag.
abstract interface class PlatformRecogniserPolicy {
  /// The answer for the platform this build runs on: Android asks the
  /// activity (`SDK_INT >= 31` and an installed on-device recogniser); iOS
  /// and macOS always keep speech on device (the plugin requires
  /// on-device recognition there); Windows, Linux and the web never do.
  factory PlatformRecogniserPolicy.platform() = _PlatformRecogniserPolicy;

  /// The answer for [platform] (and [isWeb]), so a test covers every
  /// platform from one host.
  @visibleForTesting
  factory PlatformRecogniserPolicy.forPlatform(
    TargetPlatform platform, {
    required bool isWeb,
  }) = _PlatformRecogniserPolicy.forPlatform;

  /// A policy that always answers [onDevice].
  const factory PlatformRecogniserPolicy.fake(bool onDevice) = _FakePolicy;

  /// Whether a platform listen would stay on the device right now. Never
  /// fails: anything that cannot be confirmed is false.
  Future<bool> keepsSpeechOnDevice();
}

/// The activity's channel, which answers the Android on-device question.
const MethodChannel _filesChannel = MethodChannel('com.tapture.app/files');

/// The Android method that reports an on-device recogniser.
const String _onDeviceMethod = 'onDeviceRecognitionAvailable';

final class _PlatformRecogniserPolicy implements PlatformRecogniserPolicy {
  _PlatformRecogniserPolicy() : _platform = null, _isWeb = kIsWeb;

  _PlatformRecogniserPolicy.forPlatform(
    TargetPlatform platform, {
    required this._isWeb,
  }) : _platform = platform;

  /// The platform answered for, or null to read it at each question.
  final TargetPlatform? _platform;
  final bool _isWeb;

  @override
  Future<bool> keepsSpeechOnDevice() async {
    if (_isWeb) {
      // The browser recogniser streams audio to its vendor.
      return false;
    }
    return switch (_platform ?? defaultTargetPlatform) {
      TargetPlatform.android => _androidOnDevice(),
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.fuchsia => false,
    };
  }

  /// Asked every time: the operator may install the on-device pack while
  /// the app runs.
  Future<bool> _androidOnDevice() async {
    try {
      return await _filesChannel.invokeMethod<bool>(_onDeviceMethod) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

final class _FakePolicy implements PlatformRecogniserPolicy {
  const _FakePolicy(this._onDevice);

  final bool _onDevice;

  @override
  Future<bool> keepsSpeechOnDevice() async => _onDevice;
}
