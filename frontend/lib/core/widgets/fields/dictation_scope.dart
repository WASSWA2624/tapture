import 'package:flutter/widgets.dart';
import 'package:tapture/core/ai/stt_service.dart';

/// Hands the app's recogniser, voice language and offline choice to every
/// [AppTextField] below it. The shell places one above the navigator; a
/// field with none above it shows no microphone, which is what widget
/// suites get by default.
class DictationScope extends InheritedWidget {
  /// Creates the scope. [languageTag] comes from the voice-language setting,
  /// never from a hard-coded locale (FE-L10N-08).
  const DictationScope({
    super.key,
    required this.service,
    required this.languageTag,
    required super.child,
    this.onDeviceOnly = false,
  });

  /// The one recogniser every field shares.
  final SttService service;

  /// BCP-47 language speech is recognised in.
  final String languageTag;

  /// When true (offline by choice), audio must not leave the device
  /// (FE-SEC-04).
  final bool onDeviceOnly;

  /// The nearest scope, or null when dictation is not offered here.
  static DictationScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DictationScope>();
  }

  @override
  bool updateShouldNotify(DictationScope oldWidget) {
    return service != oldWidget.service ||
        languageTag != oldWidget.languageTag ||
        onDeviceOnly != oldWidget.onDeviceOnly;
  }
}
