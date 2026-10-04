import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';

import 'speech_quality.dart';

// The two speech choices core reads but never owns: the settings feature
// does, and `main` overrides these defaults from it, because core never
// imports a feature (FE-STR-11).

/// The operator's speech quality. [SpeechQuality.auto] until `main`
/// overrides it from the settings (task 126).
final Provider<SpeechQuality> speechQualityProvider = Provider<SpeechQuality>(
  (Ref _) => SpeechQuality.auto,
);

/// The voice language, as a BCP 47 tag. The app default until `main`
/// overrides it from the voice-language setting (task 120).
final Provider<String> speechLanguageProvider = Provider<String>(
  (Ref _) => AppConstants.defaultLanguage,
);
